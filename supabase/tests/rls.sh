#!/usr/bin/env bash
#
# Sondas de RLS contra o PostgREST.
#
# Toda regra de permissão deste projeto vive no banco. A interface só decide o que é
# desenhado -- a anon key vai dentro do binário, então o que um atacante usa é
# exatamente isto aqui: HTTP direto. Este script é a prova de que as policies
# continuam valendo, e é a única forma de o CI conferir isso.
#
# O script nunca cria conta nem manipula senha: recebe credenciais prontas por
# variável de ambiente e as troca por um access token. Em CI vêm de secrets.
#
#   BALUARTE_URL         https://<ref>.supabase.co
#   BALUARTE_ANON_KEY    anon key do projeto
#   RLS_USER_A_EMAIL     Fundador de um Capítulo (as sondas de nível de acesso
#   RLS_USER_A_PASSWORD  precisam que A seja owner para chegar à regra certa)
#   RLS_USER_B_EMAIL     alguém SEM vínculo com o Capítulo de A
#   RLS_USER_B_PASSWORD
#
# Uso:
#   supabase/tests/rls.sh            roda a matriz
#   supabase/tests/rls.sh -v         mostra o corpo de cada resposta
#
# Nada aqui grava dado que sobreviva: as sondas ou são leitura, ou são escrita que
# se espera ser recusada antes de tocar uma linha.
#
# Sobre o que cada sonda asserta:
#
#   probe_denied  confere o status HTTP. Vale para o que é barrado por grant de
#                 coluna ou por policy, onde 42501 -> 403 é documentado.
#   probe_raise   confere o SQLSTATE e o hint no corpo, não o status. É o contrato
#                 real: AppError.from decide pelo `code`, e o `hint` é o que carrega
#                 a mensagem traduzível. O PostgREST não documenta o status de
#                 23514 nem de P0002, então prendê-lo aqui seria testar o
#                 intermediário em vez da regra.
#   probe_empty   confere 200 com coleção vazia. Sob RLS um SELECT sem permissão
#                 devolve [] e não um erro -- conferir só o status daria verde num
#                 vazamento.
#   probe_count   confere 200 com um número exato de linhas. Serve para provar que
#                 algo continua existindo depois de uma tentativa de apagar.
#   probe_storage_write
#                 grava no bucket privado com um mime que ele aceita. Sem isso a
#                 requisição morre em 415 antes de a policy ser consultada, e a
#                 sonda ficaria verde sem ter provado nada.

set -uo pipefail

VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

fail() { printf '\033[31m%s\033[0m\n' "$*" >&2; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

for var in BALUARTE_URL BALUARTE_ANON_KEY RLS_USER_A_EMAIL RLS_USER_A_PASSWORD RLS_USER_B_EMAIL RLS_USER_B_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    fail "Faltando \$$var. Veja o cabeçalho deste arquivo."
    exit 2
  fi
done

URL="${BALUARTE_URL%/}"
ANON="$BALUARTE_ANON_KEY"

PASSED=0
FAILED=0
BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

jsonstr() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
field()   { python3 -c '
import json,sys
try: print(json.load(open(sys.argv[1])).get(sys.argv[2]) or "")
except Exception: print("")' "$BODY" "$1"; }

pass() { ok "ok      $1"; [ "$VERBOSE" = "1" ] && dim "        $(head -c 300 "$BODY")"; PASSED=$((PASSED + 1)); }
flunk() { fail "FALHOU  $1"; fail "        $2"; dim "        $(head -c 300 "$BODY")"; FAILED=$((FAILED + 1)); }

request() {
  local token="$1" method="$2" path="$3" body="$4"
  local args=(-s -o "$BODY" -w '%{http_code}' -X "$method" "$URL$path"
              -H "apikey: $ANON" -H "Authorization: Bearer $token")
  [ "$body" != "-" ] && args+=(-H "Content-Type: application/json" -d "$body")
  curl "${args[@]}"
}

# ---------------------------------------------------------------------------

sign_in() {
  local token
  token=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
            -H "apikey: $ANON" -H "Content-Type: application/json" \
            -d "$(printf '{"email":%s,"password":%s}' "$(jsonstr "$1")" "$(jsonstr "$2")")" \
          | python3 -c 'import json,sys; print(json.load(sys.stdin).get("access_token",""))')
  [ -n "$token" ] || return 1
  printf '%s' "$token"
}

subject_of() {
  python3 -c '
import base64, json, sys
p = sys.argv[1].split(".")[1]; p += "=" * (-len(p) % 4)
print(json.loads(base64.urlsafe_b64decode(p))["sub"])' "$1"
}

probe_denied() {
  local name="$1" token="$2" method="$3" path="$4" body="$5" want="${6:-403}"
  local code; code=$(request "$token" "$method" "$path" "$body")
  if [ "$code" = "$want" ]; then pass "$name"
  else flunk "$name" "esperava HTTP $want, veio $code"; fi
}

probe_raise() {
  local name="$1" token="$2" path="$3" body="$4" want_code="$5" want_hint="$6"
  local status; status=$(request "$token" POST "$path" "$body")
  local got_code got_hint; got_code=$(field code); got_hint=$(field hint)

  # Basta não ser 2xx. O status é escolha do PostgREST, não nossa: 42501 vira 403,
  # 23514 vira 400, e P0002 vira 500 -- um "não encontrado" saindo como erro de
  # servidor, que é feio mas não é o contrato de que dependemos. O contrato é o
  # SQLSTATE, que é o que AppError.from lê, e o hint, que carrega a mensagem.
  if [ "${status:0:1}" = "2" ] || [ -z "$status" ]; then
    flunk "$name" "esperava recusa, veio HTTP $status"
  elif [ "$got_code" != "$want_code" ]; then
    flunk "$name" "esperava SQLSTATE $want_code, veio '$got_code'"
  elif [ "$want_hint" = "${want_hint%%:*}" ] && [ "${got_hint%%:*}" != "$want_hint" ]; then
    # Sem ':' no esperado, compara só a chave: o caso parametrizado carrega o
    # argumento no próprio hint (baluarte.last_owner_with_members:2).
    flunk "$name" "SQLSTATE ok, mas hint era '$want_hint' e veio '$got_hint'"
  elif [ "$want_hint" != "${want_hint%%:*}" ] && [ "$got_hint" != "$want_hint" ]; then
    flunk "$name" "SQLSTATE ok, mas hint era '$want_hint' e veio '$got_hint'"
  else
    pass "$name"
  fi
}

probe_count() {
  local name="$1" token="$2" path="$3" want="$4"
  local code; code=$(curl -s -o "$BODY" -w '%{http_code}' "$URL$path" \
                       -H "apikey: $ANON" -H "Authorization: Bearer $token")
  local n; n=$(python3 -c '
import json,sys
try:
    d = json.load(open(sys.argv[1]))
    print(len(d) if isinstance(d, list) else -1)
except Exception: print(-1)' "$BODY")

  if [ "$code" = "200" ] && [ "$n" = "$want" ]; then pass "$name"
  else flunk "$name" "esperava 200 com $want item(ns), veio HTTP $code com $n"; fi
}

# O bucket aceita apenas image/jpeg, png e heic. Sem o mime certo a requisição
# morre em 415 antes de a policy ser consultada.
probe_storage_write() {
  local name="$1" token="$2" path="$3"
  local code
  code=$(printf '\xff\xd8\xff\xd9' | curl -s -o "$BODY" -w '%{http_code}' \
           -X POST "$URL/storage/v1/object/bootstrap-proof/$path" \
           -H "apikey: $ANON" -H "Authorization: Bearer $token" \
           -H "Content-Type: image/jpeg" --data-binary @-)
  if [ "${code:0:1}" != "2" ] && [ -n "$code" ]; then
    pass "$name"
  else
    flunk "$name" "esperava recusa, veio HTTP $code — E UM OBJETO FOI CRIADO EM $path"
  fi
}

probe_empty() {
  local name="$1" token="$2" path="$3"
  local code; code=$(curl -s -o "$BODY" -w '%{http_code}' "$URL$path" \
                       -H "apikey: $ANON" -H "Authorization: Bearer $token")
  local n; n=$(python3 -c '
import json,sys
try:
    d = json.load(open(sys.argv[1]))
    print(len(d) if isinstance(d, list) else -1)
except Exception: print(-1)' "$BODY")

  if [ "$code" = "200" ] && [ "$n" = "0" ]; then pass "$name"
  else flunk "$name" "esperava 200 com coleção vazia, veio HTTP $code com $n item(ns)"; fi
}

# ---------------------------------------------------------------------------

echo "Sondas de RLS · $URL"
echo

TOKEN_A=$(sign_in "$RLS_USER_A_EMAIL" "$RLS_USER_A_PASSWORD") || { fail "login de A falhou"; exit 2; }
TOKEN_B=$(sign_in "$RLS_USER_B_EMAIL" "$RLS_USER_B_PASSWORD") || { fail "login de B falhou"; exit 2; }
A_UID=$(subject_of "$TOKEN_A")

read -r A_MEMBERSHIP A_CHAPTER A_LEVEL <<<"$(curl -s \
  "$URL/rest/v1/chapter_membership?select=id,chapter_id,access_level&status=eq.active&member_id=eq.$A_UID&limit=1" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN_A" \
  | python3 -c '
import json,sys
d = json.load(sys.stdin)
print(d[0]["id"], d[0]["chapter_id"], d[0]["access_level"]) if d else print("", "", "")')"

[ -n "$A_MEMBERSHIP" ] || { fail "A não tem vínculo ativo — veja o cabeçalho."; exit 2; }
[ "$A_LEVEL" = "owner" ] || { fail "A precisa ser Fundador; hoje é '$A_LEVEL'."; exit 2; }

dim "A ($A_LEVEL) · vínculo $A_MEMBERSHIP · Capítulo $A_CHAPTER"
echo

# ---------------------------------------------------------------------------
echo "— Auto-promoção: o que só o grant de coluna impede —"
# RLS é cego a colunas. A policy cm_update_admin deixaria a linha passar; o que
# recusa é access_level nunca ter sido concedido a authenticated.

probe_denied "não escreve access_level direto" "$TOKEN_A" PATCH \
  "/rest/v1/chapter_membership?id=eq.$A_MEMBERSHIP" '{"access_level":"owner"}'

probe_denied "não escreve approved_by direto" "$TOKEN_A" PATCH \
  "/rest/v1/chapter_membership?id=eq.$A_MEMBERSHIP" '{"approved_by":null}'

probe_denied "não vira admin de plataforma" "$TOKEN_A" PATCH \
  "/rest/v1/member?id=eq.$A_UID" '{"is_platform_admin":true}'

echo
echo "— RPCs de nível de acesso —"

probe_raise "não altera o próprio nível" "$TOKEN_A" \
  "/rest/v1/rpc/set_membership_access_level" \
  "{\"p_membership_id\":\"$A_MEMBERSHIP\",\"p_access_level\":\"admin\"}" \
  23514 "baluarte.cannot_change_own_access"

probe_denied "B não promove no Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/rpc/set_membership_access_level" \
  "{\"p_membership_id\":\"$A_MEMBERSHIP\",\"p_access_level\":\"admin\"}"

probe_denied "B não transfere posse do Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/rpc/transfer_chapter_ownership" "{\"p_to_membership_id\":\"$A_MEMBERSHIP\"}"

probe_raise "A não transfere posse para si mesmo" "$TOKEN_A" \
  "/rest/v1/rpc/transfer_chapter_ownership" "{\"p_to_membership_id\":\"$A_MEMBERSHIP\"}" \
  23514 "baluarte.already_owner"

echo
echo "— Fronteira entre Capítulos —"

probe_empty "B não lê o roster do Capítulo de A" "$TOKEN_B" \
  "/rest/v1/chapter_roster?chapter_id=eq.$A_CHAPTER&select=id"
probe_empty "B não lê eventos do Capítulo de A" "$TOKEN_B" \
  "/rest/v1/event?chapter_id=eq.$A_CHAPTER&select=id"
probe_empty "B não lê metas do Capítulo de A" "$TOKEN_B" \
  "/rest/v1/goal?chapter_id=eq.$A_CHAPTER&select=id"
probe_empty "B não lê tarefas do Capítulo de A" "$TOKEN_B" \
  "/rest/v1/task?chapter_id=eq.$A_CHAPTER&select=id"
probe_empty "B não lê comissões do Capítulo de A" "$TOKEN_B" \
  "/rest/v1/committee?chapter_id=eq.$A_CHAPTER&select=id"

echo
echo "— Convites —"
# Não existe policy de select para quem não é admin, de propósito: o modelo inteiro
# repousa no código ser inadivinhável, então enumerar não pode.

probe_empty "B não enumera convites" "$TOKEN_B" "/rest/v1/chapter_invite?select=id"

# `select` é concedido no nível da tabela, então `code` é uma coluna legível -- o que
# impede enumerar é não haver policy de select para quem não é admin do Capítulo.
# Pedir justamente essa coluna prova que nem assim sai linha.
probe_empty "nem pedindo a coluna code sai linha" "$TOKEN_B" \
  "/rest/v1/chapter_invite?select=code"

# A proteção contra escolher o próprio código é o grant de insert omitir `code`, e é
# por isso que ele nasce de um DEFAULT no servidor. A data no passado é cinto e
# suspensório: se esta sonda um dia parar de ser recusada, o convite criado por
# engano já nasce vencido.
probe_denied "admin não escolhe o próprio código" "$TOKEN_A" POST \
  "/rest/v1/chapter_invite" \
  "{\"chapter_id\":\"$A_CHAPTER\",\"created_by\":\"$A_UID\",\"code\":\"SONDARLS\",\"expires_at\":\"2000-01-01T00:00:00Z\"}"

probe_raise "resgate com código vazio é recusado" "$TOKEN_B" \
  "/rest/v1/rpc/redeem_chapter_invite" '{"p_code":""}' \
  23514 "baluarte.invite_code_required"

probe_raise "código inexistente não se distingue de expirado" "$TOKEN_B" \
  "/rest/v1/rpc/redeem_chapter_invite" '{"p_code":"ZZZZZZZZ"}' \
  23514 "baluarte.invite_invalid"

echo
echo "— Entrada é revisada, nunca self-service —"

probe_denied "B não se insere no Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/chapter_membership" \
  "{\"chapter_id\":\"$A_CHAPTER\",\"full_name\":\"Sonda RLS\",\"status\":\"active\"}"

probe_raise "aprovação de solicitação inexistente" "$TOKEN_B" \
  "/rest/v1/rpc/approve_join_request" \
  '{"p_request_id":"00000000-0000-0000-0000-000000000000"}' \
  P0002 "baluarte.request_not_found"

echo
echo "— Registro de Capítulos é somente leitura —"

probe_denied "ninguém cria Capítulo" "$TOKEN_A" POST "/rest/v1/chapter" \
  '{"name":"Sonda RLS","number":99999,"uf":"RS"}'
probe_denied "ninguém edita Capítulo" "$TOKEN_A" PATCH \
  "/rest/v1/chapter?id=eq.$A_CHAPTER" '{"name":"Sonda RLS"}'

echo
echo "— Fila da plataforma —"
# A única leitura do app que atravessa Capítulos.

probe_empty "B não vê a fila de fundação" "$TOKEN_B" \
  "/rest/v1/rpc/pending_bootstrap_requests"

echo
echo "— Um Capítulo não fica órfão —"
# A recusa é o comportamento correto e não escreve nada. Se um dia ela parar de
# valer, o Capítulo perde o único Fundador e ninguém mais aprova ninguém, para
# sempre -- é a falha silenciosa mais cara do modelo.
probe_raise "último Fundador não sai deixando gente para trás" "$TOKEN_A" \
  "/rest/v1/rpc/leave_chapter" "{\"p_chapter_id\":\"$A_CHAPTER\"}" \
  23514 "baluarte.last_owner_with_members"

echo
echo "— Roster: só cadastros que ninguém reivindicou —"
# Apagar o vínculo de quem tem conta levaria junto presenças, tarefas e comissões
# dessa pessoa. A policy é `is_admin_of(chapter_id) and member_id is null`, e o
# vínculo de A tem dono -- ele mesmo. O DELETE responde 204 porque não casa linha
# alguma, e não porque apagou: por isso a contagem depois é que prova.
probe_denied "delete de vínculo com conta não casa linha" "$TOKEN_A" DELETE \
  "/rest/v1/chapter_membership?id=eq.$A_MEMBERSHIP" - 204
probe_count "e o vínculo continua lá" "$TOKEN_A" \
  "/rest/v1/chapter_membership?id=eq.$A_MEMBERSHIP&select=id" 1

echo
echo "— Comprovantes de fundação são privados —"
# proof_insert_own exige (storage.foldername(name))[1] = auth.uid(). B tentando
# gravar sob o caminho de A é a tentativa que a policy existe para barrar.
#
# O mime tem de ser um dos permitidos pelo bucket: mandar JSON leva a 415 antes de
# a policy ser consultada, e a sonda passaria sem ter provado nada.
#
# Não há sonda de leitura aqui de propósito. Pedir um objeto inexistente devolve
# 404 tanto se a policy negar quanto se ela permitir -- verde pelo motivo errado.
# Provar a leitura exige um objeto que exista e um leitor que não seja nem o dono
# nem administrador de plataforma, e esse terceiro ator não existe nesta matriz.
probe_storage_write "B não grava sob o caminho de A" "$TOKEN_B" \
  "$A_UID/sonda-rls.jpg"

echo
echo "— Imutabilidade do Capítulo de um registro —"

probe_denied "não move um vínculo de Capítulo" "$TOKEN_A" PATCH \
  "/rest/v1/chapter_membership?id=eq.$A_MEMBERSHIP" \
  '{"chapter_id":"00000000-0000-0000-0000-000000000000"}'

echo
printf '%s\n' "─────────────────────────────"
if [ "$FAILED" -eq 0 ]; then
  ok "$PASSED sondas passaram"
  exit 0
fi
fail "$PASSED passaram · $FAILED FALHARAM"
exit 1
