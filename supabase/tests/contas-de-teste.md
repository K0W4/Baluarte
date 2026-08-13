# As contas que as sondas usam

`rls.sh` não cria conta e não lida com senha: ele faz login com o que está nos secrets e
caminha a matriz. Quem cria as contas é uma pessoa, uma vez, e as senhas vão do computador
dela direto para os secrets do repositório — nunca pelo chat, nunca por um agente.

## O que cada conta precisa ser

| conta | secret | precisa ser |
|---|---|---|
| A | `RLS_USER_A_EMAIL` / `RLS_USER_A_PASSWORD` | **Fundador** de um Capítulo com pelo menos um outro membro |
| B | `RLS_USER_B_EMAIL` / `RLS_USER_B_PASSWORD` | **fora** do Capítulo de A, sem vínculo com ele |
| C | `RLS_USER_C_EMAIL` / `RLS_USER_C_PASSWORD` | membro comum do Capítulo de A, **fora** de qualquer comissão |

A primeira linha do script confere isso e aborta com a razão exata — `A precisa ser
Fundador; hoje é 'admin'` foi como se descobriu, em 13/08/2026, que a posse do Capítulo
tinha mudado de mãos.

## Por que A não deve ser a conta pessoal de ninguém

Enquanto A foi a conta pessoal do Kowa, as sondas rodaram contra o Capítulo real a cada
push. O efeito aparece no próprio app: o Histórico de acesso do Capela Grande nº 656 tem
uma fileira de "Um convite foi revogado / Um convite foi excluído" a cada execução do CI,
misturados com o que o Capítulo fez de verdade. Um log de auditoria que contém ruído de
teste deixa de servir para auditar.

E o inverso também: qualquer mudança de acesso no Capítulo real — uma transferência de
posse, por exemplo — quebra o CI por um motivo que não tem nada a ver com o código.

## Como montar um Capítulo de teste

A via normal de criar Capítulo não serve aqui: `chapter` é registro somente-leitura para o
app, e o caminho de fundação (`join_request` com `kind = 'chapter_bootstrap'`) precisa de
um `is_platform_admin` para aprovar — e hoje não existe nenhum. Então o Capítulo de teste
nasce por SQL, uma vez, com as contas já criadas pela interface.

1. **Criar as três contas pelo app ou pelo painel de Auth** (é a única parte que precisa de
   senha, e por isso é sua). Anote os `auth.users.id` de cada uma.
2. **Rodar o SQL abaixo** no SQL Editor do projeto, trocando os três UUIDs. Ele cria o
   Capítulo de teste, põe A como Fundador, C como membro comum, e deixa B de fora.
3. **Gravar os seis secrets** em Settings → Secrets and variables → Actions.
4. **Re-rodar o workflow.** A primeira linha do script confirma o nível de A antes de
   qualquer sonda.

```sql
-- Capítulo de teste. O par (uf, number) é a chave real, então use um número que não
-- exista no RS -- 9999 é seguro e obviamente sintético.
insert into public.chapter (name, number, uf, city, status, has_owner)
values ('Capítulo de Teste', 9999, 'RS', 'Porto Alegre', 'active', true)
returning id;  -- guarde este id para os inserts abaixo

-- A: Fundador
insert into public.chapter_membership
  (chapter_id, member_id, full_name, category, role, access_level, status)
values ('<CHAPTER_ID>', '<UID_A>', 'Sonda A', 'ativo', 'Mestre Conselheiro', 'owner', 'active');

-- C: membro comum, fora de comissão. É o que destrava as 2 sondas puladas.
insert into public.chapter_membership
  (chapter_id, member_id, full_name, category, role, access_level, status)
values ('<CHAPTER_ID>', '<UID_C>', 'Sonda C', 'ativo', null, 'member', 'active');

-- B não entra: o papel dele é ser de fora.
```

`access_level` não é concedido a `authenticated`, então estes `insert` só funcionam pelo
SQL Editor (que roda como `postgres`) — o que é o ponto: nem a conta A conseguiria se
promover por conta própria, e é isso que as sondas provam.

## Depois de trocar

Devolva a conta pessoal ao que ela era e mantenha-a fora dos secrets. As sondas passam a
sujar só o Capítulo de teste, e o Histórico de acesso do Capítulo real volta a conter
apenas o que o Capítulo real fez.
