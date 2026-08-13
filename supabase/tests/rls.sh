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
# Opcionais. Sem eles as sondas que precisam de um terceiro ator são puladas com
# aviso, em vez de mentir que passaram:
#
#   RLS_USER_C_EMAIL     membro comum do Capítulo de A, fora de toda comissão
#   RLS_USER_C_PASSWORD
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
#   probe_top_action
#                 confere 200 e que a primeira linha devolvida é da ação esperada.
#                 Existe para a auditoria: uma tabela permanentemente vazia deixaria
#                 todas as sondas negativas dela verdes.
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
SKIPPED=0
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

# Quase toda sonda aqui prova uma recusa. Esta prova o contrário, e existe porque a
# ausência dela escondeu um defeito por completo: `task.creator_id` apontava para
# `member` em vez de `chapter_membership`, então quem entrou no Capítulo depois do
# backfill -- id novo, que não coincide com nenhum `member.id` -- levava 23503 ao criar
# tarefa. Nenhuma sonda de recusa jamais veria isso: recusar era o que todas esperavam.
probe_allowed() {
  local name="$1" token="$2" method="$3" path="$4" body="$5"
  local code; code=$(request "$token" "$method" "$path" "$body")
  if [ "${code:0:1}" = "2" ]; then pass "$name"
  else flunk "$name" "esperava ser aceito, veio HTTP $code $(field code)"; fi
}

# Uma sonda que não pôde rodar não é uma sonda que passou. Contada à parte e
# anunciada no fim, para a ausência de cobertura não desaparecer no verde.
skip() { printf '\033[33m%s\033[0m\n' "pulada  $1"; dim "        $2"; SKIPPED=$((SKIPPED + 1)); }

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

# Confere 200 e que a PRIMEIRA linha devolvida é da ação esperada. Serve para a
# auditoria: as sondas negativas dela ficariam todas verdes com a tabela sempre
# vazia, que é o falso-verde de sempre. Esta só passa se o gatilho tiver gravado.
probe_top_action() {
  local name="$1" token="$2" path="$3" body="$4" want="$5"
  local status; status=$(request "$token" POST "$path" "$body")
  local got; got=$(python3 -c '
import json,sys
try:
    d = json.load(open(sys.argv[1]))
    print(d[0].get("action","") if isinstance(d, list) and d else "")
except Exception: print("")' "$BODY")

  if [ "$status" = "200" ] && [ "$got" = "$want" ]; then pass "$name"
  else flunk "$name" "esperava 200 com a primeira linha em '$want', veio HTTP $status com '$got'"; fi
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
B_UID=$(subject_of "$TOKEN_B")

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

probe_denied "B não promove no Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/rpc/set_membership_access_level" \
  "{\"p_membership_id\":\"$A_MEMBERSHIP\",\"p_access_level\":\"admin\"}"

probe_denied "B não transfere posse do Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/rpc/transfer_chapter_ownership" "{\"p_to_membership_id\":\"$A_MEMBERSHIP\"}"

probe_raise "A não transfere posse para si mesmo" "$TOKEN_A" \
  "/rest/v1/rpc/transfer_chapter_ownership" "{\"p_to_membership_id\":\"$A_MEMBERSHIP\"}" \
  23514 "baluarte.already_owner"

echo
echo "— Acesso de plataforma: cadeia de confiança —"
# A coluna is_platform_admin nunca é concedida a authenticated -- isso já é sondado
# acima. Aqui é a RPC: só quem já tem o status concede a outro. Se B conseguisse,
# ele aprovaria a fundação de qualquer Capítulo do país e tomaria posse dele.
probe_denied "B não se torna admin de plataforma pela RPC" "$TOKEN_B" POST \
  "/rest/v1/rpc/set_platform_admin" \
  "{\"p_member_id\":\"$B_UID\",\"p_is_admin\":true}"

probe_denied "B não concede status de plataforma a A" "$TOKEN_B" POST \
  "/rest/v1/rpc/set_platform_admin" \
  "{\"p_member_id\":\"$A_UID\",\"p_is_admin\":true}"

probe_empty "B não lista os admins de plataforma" "$TOKEN_B" \
  "/rest/v1/rpc/platform_admins"

echo
echo "— Auto-rebaixamento: descer sim, subir não —"
# A assimetria é a regra inteira. A é Fundador, então as duas direções são recusadas
# para ele -- mas por motivos diferentes, e é isso que as duas sondas separam.
probe_raise "A não sobe o próprio acesso" "$TOKEN_A" \
  "/rest/v1/rpc/set_membership_access_level" \
  "{\"p_membership_id\":\"$A_MEMBERSHIP\",\"p_access_level\":\"owner\"}" \
  23514 "baluarte.owner_needs_transfer"

probe_raise "Fundador não se rebaixa, transfere" "$TOKEN_A" \
  "/rest/v1/rpc/set_membership_access_level" \
  "{\"p_membership_id\":\"$A_MEMBERSHIP\",\"p_access_level\":\"admin\"}" \
  23514 "baluarte.owner_needs_transfer"

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

# A tabela de tentativas não é do app: quem consome é a própria RPC. Se desse para
# ler, um atacante veria quais códigos já foram tentados; se desse para escrever,
# ele encheria o contador de outra pessoa e a trancaria fora do Capítulo.
probe_denied "ninguém lê a tabela de tentativas" "$TOKEN_B" GET \
  "/rest/v1/invite_attempt?select=code" -
probe_denied "ninguém escreve na tabela de tentativas" "$TOKEN_B" POST \
  "/rest/v1/invite_attempt" \
  "{\"member_id\":\"$B_UID\",\"code\":\"SONDARLS\",\"succeeded\":false}"

# O expurgo roda por manutenção, não pelo app.
probe_denied "ninguém dispara o expurgo de tentativas" "$TOKEN_A" POST \
  "/rest/v1/rpc/purge_invite_attempts" '{}' 

echo
echo "— Entrada é revisada, nunca self-service —"

probe_denied "B não se insere no Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/chapter_membership" \
  "{\"chapter_id\":\"$A_CHAPTER\",\"full_name\":\"Sonda RLS\",\"status\":\"active\"}"

probe_raise "aprovação de solicitação inexistente" "$TOKEN_B" \
  "/rest/v1/rpc/approve_join_request" \
  '{"p_request_id":"00000000-0000-0000-0000-000000000000"}' \
  PT404 "baluarte.request_not_found"

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
echo "— Fila de Capítulos solicitados —"
# Aprovar insere em `chapter`, que é registro somente leitura. Se B conseguisse
# revisar, ele criaria Capítulos à vontade -- e depois fundaria cada um deles.
probe_denied "B não revisa solicitação de Capítulo" "$TOKEN_B" POST \
  "/rest/v1/rpc/review_chapter_request" \
  '{"p_request_id":"00000000-0000-0000-0000-000000000000","p_approved":true}'

probe_empty "B não vê a fila de Capítulos" "$TOKEN_B" \
  "/rest/v1/rpc/pending_chapter_requests"

# A autorização vem antes de qualquer detalhe do alvo: mesmo com um id inexistente,
# quem não revisa recebe 42501 e não "não encontrado". O contrário contaria a um
# estranho quais ids existem.
probe_denied "id inexistente não revela nada a quem não revisa" "$TOKEN_B" POST \
  "/rest/v1/rpc/review_chapter_request" \
  '{"p_request_id":"00000000-0000-0000-0000-000000000000","p_approved":false}'

echo
echo "— Token de aparelho é do dono, e só dele —"
# O token não autentica ninguém, mas identifica um aparelho. Ninguém além do dono
# precisa lê-lo, e ninguém precisa listá-los.
probe_denied "B não registra token em nome de A" "$TOKEN_B" POST \
  "/rest/v1/device_token" \
  "{\"token\":\"sonda-rls-$RANDOM\",\"member_id\":\"$A_UID\"}"

probe_empty "B não lê tokens de A" "$TOKEN_B" \
  "/rest/v1/device_token?member_id=eq.$A_UID&select=token"

echo
echo "— A fila de notificações não é do app —"
# Sem policy alguma: quem consome é a Edge Function, com service_role. Um SELECT
# daqui tem de voltar vazio, e um INSERT tem de ser recusado -- se alguém pudesse
# enfileirar, mandaria push em nome do Baluarte para quem quisesse.
probe_denied "ninguém enfileira notificação" "$TOKEN_A" POST \
  "/rest/v1/notification_outbox" \
  "{\"member_id\":\"$A_UID\",\"kind\":\"sonda\",\"title_key\":\"x\",\"body_key\":\"y\"}"

probe_denied "ninguém lê a fila de notificações" "$TOKEN_A" GET \
  "/rest/v1/notification_outbox?select=id" -

echo
echo "— Auditoria de mudanças de acesso —"
# A tabela não tem policy alguma, como `invite_attempt` e `notification_outbox`: se
# desse para escrever, o log poderia ser forjado; se desse para apagar, ele não
# serviria de prova nenhuma.

probe_denied "ninguém lê a tabela de auditoria" "$TOKEN_A" GET \
  "/rest/v1/access_change_log?select=id" -

probe_denied "ninguém escreve na tabela de auditoria" "$TOKEN_A" POST \
  "/rest/v1/access_change_log" \
  "{\"action\":\"access_level_changed\",\"scope\":\"chapter\",\"chapter_id\":\"$A_CHAPTER\"}"

probe_denied "ninguém apaga linha da auditoria" "$TOKEN_A" DELETE \
  "/rest/v1/access_change_log?id=gt.0" -

probe_denied "B não lê o histórico do Capítulo de A" "$TOKEN_B" POST \
  "/rest/v1/rpc/chapter_access_log" "{\"p_chapter_id\":\"$A_CHAPTER\"}"

# Autorização antes de qualquer detalhe do alvo, inclusive da existência dele: um
# Capítulo inventado responde igual a um real, senão a auditoria vira um oráculo de
# quais ids existem.
probe_denied "Capítulo inexistente responde igual" "$TOKEN_B" POST \
  "/rest/v1/rpc/chapter_access_log" \
  '{"p_chapter_id":"00000000-0000-0000-0000-000000000000"}'

probe_denied "B não lê o histórico da plataforma" "$TOKEN_B" POST \
  "/rest/v1/rpc/platform_access_log" '{}'

# E a sonda que impede as de cima de passarem por vacuidade. Todo o resto desta
# seção ficaria verde com a tabela permanentemente vazia -- o gatilho é justamente o
# que não dá para provar por negativa.
#
# É a única sonda do arquivo que deixa linha para trás, e de propósito: "o log não
# pode ser apagado" é a propriedade sendo provada, então uma sonda que limpasse o
# próprio rastro provaria o contrário. Duas linhas de auditoria, sobre um convite
# que nasce vencido, é revogado e é apagado em seguida.
PROBE_INVITE=$(curl -s -X POST "$URL/rest/v1/chapter_invite" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "{\"chapter_id\":\"$A_CHAPTER\",\"created_by\":\"$A_UID\",\"max_uses\":1,\"expires_at\":\"2000-01-01T00:00:00Z\"}" \
  | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
    print(d[0]["id"] if isinstance(d, list) and d else "")
except Exception: print("")')

if [ -z "$PROBE_INVITE" ]; then
  skip "o gatilho grava a revogação" "não foi possível criar o convite de sonda no Capítulo de A"
  skip "o gatilho grava a exclusão" "idem"
else
  request "$TOKEN_A" PATCH "/rest/v1/chapter_invite?id=eq.$PROBE_INVITE" \
    "{\"revoked_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >/dev/null

  probe_top_action "o gatilho grava a revogação" "$TOKEN_A" \
    "/rest/v1/rpc/chapter_access_log" "{\"p_chapter_id\":\"$A_CHAPTER\",\"p_limit\":1}" \
    "invite_revoked"

  request "$TOKEN_A" DELETE "/rest/v1/chapter_invite?id=eq.$PROBE_INVITE" - >/dev/null

  probe_top_action "o gatilho grava a exclusão" "$TOKEN_A" \
    "/rest/v1/rpc/chapter_access_log" "{\"p_chapter_id\":\"$A_CHAPTER\",\"p_limit\":1}" \
    "invite_deleted"
fi

echo
echo "— Escopo de comissão e dupla filiação —"
# Estas duas exigem um terceiro ator: alguém DENTRO do Capítulo de A que não esteja
# na comissão. B não serve -- ele está fora do Capítulo, e a fronteira entre
# Capítulos já é testada acima. Sem C, a regra fica sem prova, e dizer isso é melhor
# do que somar dois verdes que não significam nada.
if [ -z "${RLS_USER_C_EMAIL:-}" ] || [ -z "${RLS_USER_C_PASSWORD:-}" ]; then
  skip "tarefa de comissão alheia" "defina RLS_USER_C_EMAIL/PASSWORD: membro do Capítulo de A, fora de toda comissão"
  skip "terceiro vínculo é recusado" "idem"
else
  TOKEN_C=$(sign_in "$RLS_USER_C_EMAIL" "$RLS_USER_C_PASSWORD") || { fail "login de C falhou"; exit 2; }
  C_UID=$(subject_of "$TOKEN_C")

  # Uma tarefa de comissão só é visível a quem está nela e aos administradores.
  # Procura uma comissão de A que não tenha C, e uma tarefa dela.
  read -r SCOPED_TASK <<<"$(curl -s \
    "$URL/rest/v1/task?chapter_id=eq.$A_CHAPTER&committee_id=not.is.null&select=id,committee_id&limit=20" \
    -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN_A" \
    | python3 -c '
import json,sys
d = json.load(sys.stdin)
print(d[0]["id"] if d else "")')"

  if [ -z "$SCOPED_TASK" ]; then
    skip "tarefa de comissão alheia" "o Capítulo de A não tem nenhuma tarefa ligada a comissão"
  else
    probe_empty "C não lê tarefa de comissão que não é dele" "$TOKEN_C" \
      "/rest/v1/task?id=eq.$SCOPED_TASK&select=id"
  fi

  # A trava de dupla filiação está num trigger, e só dispara num insert que passe
  # pela policy. C pedindo entrada num terceiro Capítulo é barrado antes disso pela
  # própria RLS, então o que dá para provar por HTTP é a recusa, não qual das duas
  # camadas recusou -- e as duas precisam valer.
  probe_denied "C não se insere em Capítulo por conta própria" "$TOKEN_C" POST \
    "/rest/v1/chapter_membership" \
    "{\"chapter_id\":\"$A_CHAPTER\",\"member_id\":\"$C_UID\",\"full_name\":\"Sonda RLS\",\"status\":\"active\"}"

  # O ator de um Capítulo é o vínculo, não a pessoa, e C é justamente quem tem vínculo
  # com id novo -- o caso que as FKs antigas recusavam. Cria e apaga: nada sobrevive.
  C_MEMBERSHIP=$(curl -s \
    "$URL/rest/v1/chapter_membership?select=id&member_id=eq.$C_UID&chapter_id=eq.$A_CHAPTER&limit=1" \
    -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN_C" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["id"] if d else "")')

  if [ -z "$C_MEMBERSHIP" ]; then
    skip "vínculo novo cria tarefa" "não foi possível ler o vínculo de C"
  else
    probe_allowed "vínculo novo cria tarefa" "$TOKEN_C" POST "/rest/v1/task" \
      "{\"chapter_id\":\"$A_CHAPTER\",\"creator_id\":\"$C_MEMBERSHIP\",\"assignee_id\":\"$C_MEMBERSHIP\",\"title\":\"Sonda RLS\"}"
    curl -s -X DELETE \
      "$URL/rest/v1/task?chapter_id=eq.$A_CHAPTER&title=eq.Sonda%20RLS" \
      -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN_C" >/dev/null
  fi
fi

echo
printf '%s\n' "─────────────────────────────"
SUFFIX=""
[ "$SKIPPED" -gt 0 ] && SUFFIX=" · $SKIPPED pulada(s)"
if [ "$FAILED" -eq 0 ]; then
  ok "$PASSED sondas passaram$SUFFIX"
  [ "$SKIPPED" -gt 0 ] && dim "Puladas não são aprovadas: essas regras seguem sem prova."
  exit 0
fi
fail "$PASSED passaram · $FAILED FALHARAM$SUFFIX"
exit 1
