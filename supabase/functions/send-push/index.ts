// Consome notification_outbox e entrega pela APNs.
//
// Roda com service_role porque a outbox não tem policy alguma -- nada no app lê ou
// escreve nela, justamente para ninguém conseguir enfileirar um push em nome do
// Baluarte. Esta função é a única leitora.
//
// Autenticação na APNs é por JWT ES256 assinado com a chave .p8, e o token vale uma
// hora. A Apple recusa quem gera um por requisição, então ele é reaproveitado
// enquanto durar.
//
// A localização é do aparelho, não daqui: a outbox guarda chave de tradução, e o que
// vai no payload é `loc-key`/`loc-args`, que o iOS resolve contra o catálogo do app.
// Mandar frase pronta seria escolher o idioma do lado errado.

import { createClient } from "npm:@supabase/supabase-js@2";

const APNS_HOST = "https://api.push.apple.com";
const BATCH = 100;
const MAX_ATTEMPTS = 5;

interface OutboxRow {
  id: string;
  member_id: string;
  kind: string;
  title_key: string;
  body_key: string;
  body_args: Record<string, unknown>;
  attempts: number;
}

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importSigningKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"],
  );
}

let cachedToken: { value: string; issuedAt: number } | null = null;

async function apnsToken(keyId: string, teamId: string, pem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  // A Apple recusa um token com mais de uma hora, e recusa também quem gera um por
  // requisição. Cinquenta minutos deixa margem para o relógio divergir.
  if (cachedToken && now - cachedToken.issuedAt < 50 * 60) return cachedToken.value;

  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const claims = base64url(JSON.stringify({ iss: teamId, iat: now }));
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    await importSigningKey(pem),
    new TextEncoder().encode(`${header}.${claims}`),
  );

  const value = `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
  cachedToken = { value, issuedAt: now };
  return value;
}

Deno.serve(async () => {
  const keyId = Deno.env.get("APNS_KEY_ID");
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY");

  if (!keyId || !teamId || !bundleId || !privateKey) {
    return Response.json(
      { error: "APNs secrets missing", need: ["APNS_KEY_ID", "APNS_TEAM_ID", "APNS_BUNDLE_ID", "APNS_PRIVATE_KEY"] },
      { status: 500 },
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: pending, error } = await supabase
    .from("notification_outbox")
    .select("id, member_id, kind, title_key, body_key, body_args, attempts")
    .is("delivered_at", null)
    .lt("attempts", MAX_ATTEMPTS)
    .order("created_at", { ascending: true })
    .limit(BATCH);

  if (error) return Response.json({ error: error.message }, { status: 500 });
  if (!pending?.length) return Response.json({ sent: 0, pending: 0 });

  const jwt = await apnsToken(keyId, teamId, privateKey);
  let sent = 0;
  let dropped = 0;

  for (const row of pending as OutboxRow[]) {
    const { data: devices } = await supabase
      .from("device_token")
      .select("token")
      .eq("member_id", row.member_id);

    // Sem aparelho registrado não há o que entregar, e reenfileirar para sempre
    // encheria a fila. A linha é marcada como entregue porque, para esta pessoa,
    // não há entrega possível.
    if (!devices?.length) {
      await supabase.from("notification_outbox")
        .update({ delivered_at: new Date().toISOString() }).eq("id", row.id);
      dropped++;
      continue;
    }

    let anyDelivered = false;

    for (const device of devices) {
      const payload = {
        aps: {
          alert: {
            "title-loc-key": row.title_key,
            "loc-key": row.body_key,
            "loc-args": Object.values(row.body_args ?? {}).map(String),
          },
          sound: "default",
        },
        kind: row.kind,
      };

      const response = await fetch(`${APNS_HOST}/3/device/${device.token}`, {
        method: "POST",
        headers: {
          "authorization": `bearer ${jwt}`,
          "apns-topic": bundleId,
          "apns-push-type": "alert",
          "content-type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        anyDelivered = true;
        continue;
      }

      // 410 é a Apple dizendo que o aparelho desinstalou o app. Guardar o token
      // depois disso só gera falha em toda entrega seguinte.
      if (response.status === 410) {
        await supabase.from("device_token").delete().eq("token", device.token);
        continue;
      }

      // 400 com BadDeviceToken é token malformado -- também não melhora tentando.
      if (response.status === 400) {
        const body = await response.text();
        if (body.includes("BadDeviceToken")) {
          await supabase.from("device_token").delete().eq("token", device.token);
        }
      }
    }

    if (anyDelivered) {
      await supabase.from("notification_outbox")
        .update({ delivered_at: new Date().toISOString() }).eq("id", row.id);
      sent++;
    } else {
      // Sem marcar delivered_at: a próxima execução tenta de novo, até MAX_ATTEMPTS.
      await supabase.from("notification_outbox")
        .update({ attempts: row.attempts + 1 }).eq("id", row.id);
    }
  }

  return Response.json({ sent, dropped, considered: pending.length });
});
