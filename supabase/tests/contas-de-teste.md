# As contas que as sondas usam

`rls.sh` não cria conta e não lida com senha: ele faz login com o que está nos secrets e
caminha a matriz. Quem cria as contas é uma pessoa, uma vez, e as senhas vão do computador
dela direto para os secrets do repositório — nunca pelo chat, nunca por um agente.

## O que cada conta precisa ser

| conta | secrets | precisa ser |
|---|---|---|
| A | `RLS_USER_A_EMAIL` / `RLS_USER_A_PASSWORD` | **Fundador** de um Capítulo que tenha pelo menos um outro membro |
| B | `RLS_USER_B_EMAIL` / `RLS_USER_B_PASSWORD` | **sem vínculo nenhum** com o Capítulo de A |
| C | `RLS_USER_C_EMAIL` / `RLS_USER_C_PASSWORD` | membro comum do Capítulo de A, **fora de toda comissão** |

A e B são obrigatórias. C é opcional: sem ela, as duas sondas que precisam de um terceiro
ator são **puladas com aviso**, em vez de mentirem que passaram.

A primeira coisa que o script faz é conferir o nível de A e abortar com a razão exata —
`A precisa ser Fundador; hoje é 'admin'` foi como se descobriu, em 13/08/2026, que a posse
do Capítulo real tinha mudado de mãos.

## Por que A não pode ser uma conta pessoal

Enquanto A foi a conta pessoal do Kowa, as sondas rodaram contra o Capítulo real a cada
push, e as duas coisas se atrapalharam nos dois sentidos:

- **O CI sujou o Capítulo.** O Histórico de acesso do Capela Grande nº 656 tem uma fileira
  de "Um convite foi revogado / Um convite foi excluído" a cada execução, misturada com o
  que o Capítulo fez de verdade. Um log de auditoria com ruído de teste deixa de auditar.
- **O Capítulo quebrou o CI.** Uma transferência de posse — coisa legítima de acontecer num
  Capítulo real — derrubou a suíte inteira por um motivo que não tem nada a ver com código.

Depois desta troca, o CI deixa de depender de quem é Fundador do Capítulo real.

## Passo 1 — criar as três contas

Pelo painel do Supabase, **Authentication → Users → Add user → Create new user**, com
**Auto Confirm User** marcado — sem isso o login das sondas falha esperando confirmação.

Para os e-mails, duas opções que funcionam:

- **Subendereçamento**, `voce+sonda-a@gmail.com`, `+sonda-b`, `+sonda-c`. Chegam na sua
  caixa, então recuperação de senha funciona se um dia precisar.
- **Domínio reservado**, `sonda-a@baluarte.test`. `.test` nunca resolve na internet, por
  RFC 2606, então não há risco de mandar e-mail para um estranho. Só sirva com Auto
  Confirm marcado.

Gere as três senhas no seu gerenciador. Elas não passam por aqui.

## Passo 2 — montar o Capítulo de teste

A via normal não serve: `chapter` é registro somente-leitura para o app, e o caminho de
fundação (`join_request` com `kind = 'chapter_bootstrap'`) precisa de um `is_platform_admin`
para aprovar — e hoje não existe nenhum. Então o Capítulo de teste nasce por SQL.

### Ele nasce invisível

O Capítulo entra com **`status = 'pending_review'`**, e isso não é um detalhe: é o que
mantém as contas de sonda fora do produto. `search_chapters` filtra
`where c.status <> 'pending_review'`, então o Capítulo de Teste **não aparece na busca**
para ninguém — nem para você, nem para um Capítulo real procurando o seu.

O mecanismo já existe e é o mesmo que esconde um Capítulo em análise: quem já tem vínculo
continua enxergando o nome dele (`fetchChapter` é leitura direta por id), e é exatamente
disso que as sondas precisam. Nenhuma delas consulta a busca, e nenhuma depende do status.

O resultado é que as três contas existem no `auth.users`, porque precisam existir, e não
aparecem em lugar nenhum do app:

- **B** não tem vínculo com Capítulo algum — some por definição.
- **A e C** só existem dentro do Capítulo de Teste, que a busca não devolve.
- **Nenhuma** delas encosta no Capela Grande nº 656.

Cole no **SQL Editor**, trocando só os três e-mails da primeira linha. O script busca os
UUIDs sozinho, e é idempotente — rodar duas vezes não duplica nada.

```sql
begin;

with contas as (
  select 'voce+sonda-a@gmail.com'::text as a,
         'voce+sonda-b@gmail.com'::text as b,
         'voce+sonda-c@gmail.com'::text as c
),

-- O Capítulo de teste. (uf, number) é a chave real do registro, e 9999/RS é
-- obviamente sintético.
capitulo as (
  insert into public.chapter (name, number, uf, city, status, has_owner)
  values ('Capítulo de Teste', 9999, 'RS', 'Porto Alegre', 'pending_review', true)
  on conflict (uf, number) do update
    set has_owner = true, status = 'pending_review'
  returning id
),

-- O perfil. O app cria esta linha no cadastro; conta feita pelo painel de Auth não
-- tem uma, e `chapter_membership.member_id` referencia exatamente ela.
perfis as (
  insert into public.member (id, full_name)
  select u.id,
         case u.email when k.a then 'Sonda A'
                      when k.b then 'Sonda B'
                      else 'Sonda C' end
  from auth.users u, contas k
  where u.email in (k.a, k.b, k.c)
  on conflict (id) do nothing
  returning id
)

-- A entra como Fundador, C como membro comum. B fica de fora: o papel dele é ser
-- de fora, e é isso que as sondas de isolamento provam.
insert into public.chapter_membership
  (chapter_id, member_id, full_name, category, role, access_level, status, joined_at)
select cap.id,
       u.id,
       case u.email when k.a then 'Sonda A' else 'Sonda C' end,
       'ativo'::public.membership_category,
       case u.email when k.a then 'Mestre Conselheiro' else null end,
       (case u.email when k.a then 'owner' else 'member' end)::public.access_level,
       'active'::public.membership_status,
       now()
from capitulo cap, auth.users u, contas k
where u.email in (k.a, k.c)
on conflict (chapter_id, member_id)
  do update set access_level = excluded.access_level,
                status       = 'active';

commit;
```

### Conferir antes de sair do SQL Editor

```sql
select m.full_name, u.email, cm.access_level, cm.status, c.name, c.number
from public.chapter_membership cm
join public.member m  on m.id = cm.member_id
join auth.users u     on u.id = cm.member_id
join public.chapter c on c.id = cm.chapter_id
where c.uf = 'RS' and c.number = 9999
order by cm.access_level desc;
```

Tem de sair exatamente isto: **Sonda A · owner · active** e **Sonda C · member · active**.
E, para confirmar que o Capítulo está invisível, `select * from public.search_chapters('teste', null)`
não deve devolver nada.
Se B aparecer, ele entrou por engano e precisa sair — `delete from public.chapter_membership
where member_id = (select id from auth.users where email = '<e-mail de B>')`.

## Passo 2b — a última sonda (opcional)

Com A, B e C no lugar, 50 das 51 sondas rodam. A que sobra precisa de **uma tarefa ligada
a uma comissão** no Capítulo de A, para provar que um membro de fora da comissão não a
enxerga — e o Capítulo de teste nasce vazio. Ela se declara pulada com a razão: *"o
Capítulo de A não tem nenhuma tarefa ligada a comissão"*.

Para fechar as 51, rode também:

```sql
-- Uma comissão onde só A entra. C fica de fora, que é o ponto.
insert into public.committee (chapter_id, name, chairman_id, member_ids)
select c.id, 'Comissão de Sonda', cm.id, array[cm.id]
from public.chapter c
join public.chapter_membership cm
  on cm.chapter_id = c.id and cm.access_level = 'owner'
where c.uf = 'RS' and c.number = 9999
  and not exists (select 1 from public.committee x where x.chapter_id = c.id);

-- E uma tarefa dentro dela.
insert into public.task (chapter_id, creator_id, assignee_id, committee_id, title)
select c.id, cm.id, cm.id, com.id, 'Tarefa de sonda'
from public.chapter c
join public.chapter_membership cm
  on cm.chapter_id = c.id and cm.access_level = 'owner'
join public.committee com on com.chapter_id = c.id
where c.uf = 'RS' and c.number = 9999
  and not exists (select 1 from public.task t where t.committee_id = com.id);
```

## Passo 3 — gravar os secrets

Pelo site: **Settings → Secrets and variables → Actions → New repository secret**, seis
vezes. Ou pelo CLI, que não ecoa o valor na tela nem no histórico do shell:

```bash
gh secret set RLS_USER_A_PASSWORD --repo K0W4/Baluarte
```

Ele pede o valor e você cola. Repita para os seis nomes da tabela lá em cima.

## Passo 4 — re-rodar

```bash
gh run rerun --repo K0W4/Baluarte --failed
```

A primeira linha da saída confirma o nível de A antes de qualquer sonda. Se ela passar, as
49 sondas rodam — e as 2 que hoje são puladas passam a rodar também, porque C existe.

## Depois

Tire a conta pessoal dos secrets e deixe-a fora. O Capítulo real volta a ter no Histórico
de acesso só o que o Capítulo real fez, e o CI para de depender de quem é Fundador nele.
