-- Pacote 10 — auditoria de mudanças de acesso.
--
-- Hoje o único rastro de autoridade é `chapter_membership.approved_by`, que diz quem
-- deixou alguém entrar e nada mais. Promoção, rebaixamento, transferência de posse,
-- concessão de acesso de plataforma e revogação de convite não deixam nada. Numa
-- organização que troca de gestão a cada semestre, "quem me tirou de administrador?"
-- é uma pergunta que vai ser feita, e hoje ela não tem resposta.
--
-- ---------------------------------------------------------------------------
-- Por que gatilho, e não o corpo das RPCs
--
-- O nível de acesso muda hoje por cinco caminhos, e três deles não são
-- `set_membership_access_level`:
--
--   set_membership_access_level     promove, rebaixa, auto-rebaixa
--   transfer_chapter_ownership      mexe em duas linhas
--   approve_join_request            cria o vínculo JÁ como admin ou owner
--   redeem_chapter_invite           cria o vínculo como member
--   anonymize_member_memberships    zera para member quando a conta é excluída
--
-- Instrumentar corpo de função registra o que eu lembrar de instrumentar. O gatilho
-- registra o que de fato aconteceu com a linha -- inclusive pelo caminho que outra
-- pessoa escrever daqui a seis meses, e inclusive pelo que for feito por
-- `service_role` fora do app.
--
-- `auth.uid()` continua valendo dentro de um `security definer`: o que muda ali é o
-- `current_user`, não o GUC do JWT. Então o gatilho sabe quem chamou. Quando não
-- sabe -- script, dashboard, Edge Function -- grava `actor_id` nulo, que é
-- informação e não buraco.
--
-- ---------------------------------------------------------------------------
-- Duas escolhas de coluna que decidem se isto serve para alguma coisa
--
-- 1. Sem chave estrangeira nas colunas de ator e de sujeito. Auditoria que o cascade
--    apaga junto com a evidência não é auditoria: apagar a conta apagaria justamente
--    o registro de que ela rebaixou alguém. Só `chapter_id` tem FK, porque o
--    registro de Capítulos não é apagado pelo app.
--
-- 2. Sem cópia de nome. Guardamos ids e resolvemos o nome na leitura. Assim a
--    auditoria anonimiza sozinha quando a conta sai, coerente com
--    `anonymize_on_account_deletion`, que existe exatamente para o nome não ficar.
--    Nome congelado aqui furaria aquela migration.

begin;

create table if not exists public.access_change_log (
  id          bigserial primary key,
  occurred_at timestamptz not null default now(),

  -- A transferência de posse move duas linhas na mesma transação. O gatilho continua
  -- burro -- uma linha por mudança de linha -- e quem lê agrupa pelo txid para
  -- reconhecer o par e chamar aquilo de transferência. Interpretar no gatilho
  -- significaria mentir no dia em que surgir um caminho novo.
  txid        bigint not null default txid_current(),

  action      text not null check (action in (
                'access_level_changed',
                'access_cleared_on_account_deletion',
                'platform_admin_changed',
                'invite_revoked',
                'invite_deleted')),
  scope       text not null check (scope in ('chapter', 'platform')),

  chapter_id  uuid references public.chapter(id) on delete cascade,
  actor_id    uuid,

  subject_member_id     uuid,
  subject_membership_id uuid,
  invite_id             uuid,

  old_value   text,
  new_value   text,

  constraint access_change_log_scope_has_chapter check (
    (scope = 'chapter'  and chapter_id is not null) or
    (scope = 'platform' and chapter_id is null)
  )
);

create index if not exists access_change_log_chapter_idx
  on public.access_change_log (chapter_id, id desc)
  where scope = 'chapter';

create index if not exists access_change_log_platform_idx
  on public.access_change_log (id desc)
  where scope = 'platform';

-- Nenhuma policy, como `invite_attempt` e `notification_outbox`: nada no app lê ou
-- escreve esta tabela direto. Escrita é dos gatilhos, leitura é das duas funções
-- abaixo, e as duas rodam como donas do schema.
alter table public.access_change_log enable row level security;
revoke all on public.access_change_log from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Vínculo: nível de acesso
-- ---------------------------------------------------------------------------

create or replace function public.log_membership_access_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    -- Entrar como membro comum não é concessão de autoridade, e registrar toda
    -- adesão afogaria o log no ruído. Já entrar administrador é promoção com outro
    -- nome: sem esta linha, quem entrou admin no dia um não tem a quem perguntar.
    if new.access_level = 'member' then
      return null;
    end if;

    insert into public.access_change_log
      (action, scope, chapter_id, actor_id, subject_member_id, subject_membership_id,
       old_value, new_value)
    values
      ('access_level_changed', 'chapter', new.chapter_id, (select auth.uid()),
       new.member_id, new.id, null, new.access_level::text);

    return null;
  end if;

  if old.access_level is not distinct from new.access_level then
    return null;
  end if;

  -- `anonymize_member_memberships` rebaixa para member junto com member_id -> null
  -- quando a conta é excluída. Sem separar este caso, o log diria "Fulano foi
  -- rebaixado por (desconhecido)" para quem na verdade saiu do app.
  if old.member_id is not null and new.member_id is null then
    insert into public.access_change_log
      (action, scope, chapter_id, actor_id, subject_member_id, subject_membership_id,
       old_value, new_value)
    values
      ('access_cleared_on_account_deletion', 'chapter', new.chapter_id, null,
       old.member_id, new.id, old.access_level::text, new.access_level::text);

    return null;
  end if;

  insert into public.access_change_log
    (action, scope, chapter_id, actor_id, subject_member_id, subject_membership_id,
     old_value, new_value)
  values
    ('access_level_changed', 'chapter', new.chapter_id, (select auth.uid()),
     coalesce(new.member_id, old.member_id), new.id,
     old.access_level::text, new.access_level::text);

  return null;
end $$;

drop trigger if exists cm_log_access_change on public.chapter_membership;
create trigger cm_log_access_change
  after insert or update on public.chapter_membership
  for each row execute function public.log_membership_access_change();

-- ---------------------------------------------------------------------------
-- Pessoa: acesso de plataforma
--
-- Não há gatilho de INSERT porque `member` nasce sempre com o status falso: o
-- primeiro administrador de plataforma veio por SQL, o que é um UPDATE, e todos os
-- outros vêm de `set_platform_admin`.
-- ---------------------------------------------------------------------------

create or replace function public.log_platform_admin_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.is_platform_admin is not distinct from new.is_platform_admin then
    return null;
  end if;

  insert into public.access_change_log
    (action, scope, chapter_id, actor_id, subject_member_id, old_value, new_value)
  values
    ('platform_admin_changed', 'platform', null, (select auth.uid()), new.id,
     old.is_platform_admin::text, new.is_platform_admin::text);

  return null;
end $$;

drop trigger if exists member_log_platform_admin on public.member;
create trigger member_log_platform_admin
  after update on public.member
  for each row execute function public.log_platform_admin_change();

-- ---------------------------------------------------------------------------
-- Convite: revogação e exclusão
--
-- A exclusão importa mais que a revogação, e é a que não deixava rastro nenhum:
-- `delete` é concedido a `authenticated` sob a policy de administrador, então hoje a
-- linha inteira some e com ela quem a criou e quantas vezes foi usada.
--
-- O código nunca entra no log. Um convite revogado está morto, mas guardar código em
-- tabela de auditoria é criar um segundo lugar de onde ele pode vazar.
-- ---------------------------------------------------------------------------

create or replace function public.log_invite_retirement()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    insert into public.access_change_log
      (action, scope, chapter_id, actor_id, invite_id, old_value)
    values
      ('invite_deleted', 'chapter', old.chapter_id, (select auth.uid()), old.id,
       old.uses_count::text);

    return null;
  end if;

  if old.revoked_at is not null or new.revoked_at is null then
    return null;
  end if;

  insert into public.access_change_log
    (action, scope, chapter_id, actor_id, invite_id, old_value)
  values
    ('invite_revoked', 'chapter', new.chapter_id, (select auth.uid()), new.id,
     new.uses_count::text);

  return null;
end $$;

drop trigger if exists ci_log_retirement on public.chapter_invite;
create trigger ci_log_retirement
  after update or delete on public.chapter_invite
  for each row execute function public.log_invite_retirement();

-- ---------------------------------------------------------------------------
-- Leitura
--
-- Autorização antes de qualquer detalhe do alvo, inclusive da existência dele:
-- `is_owner_of` de um id inventado e de um id real respondem a mesma coisa, então
-- ninguém descobre quais Capítulos existem perguntando pelo log deles.
--
-- Paginação pelo `id` e não pelo `occurred_at`: as duas linhas de uma transferência
-- de posse têm o mesmo `now()`, e um cursor por tempo pularia uma delas.
--
-- O nome sai do join, nunca de cópia guardada. Ator sem linha em `member` é conta
-- excluída, e devolve nulo -- é o app que escreve "Conta removida", porque o
-- servidor não sabe o idioma de quem perguntou.
-- ---------------------------------------------------------------------------

create or replace function public.chapter_access_log(
  p_chapter_id uuid,
  p_limit      int    default 50,
  p_before_id  bigint default null
)
returns table (
  id                    bigint,
  occurred_at           timestamptz,
  txid                  bigint,
  action                text,
  actor_id              uuid,
  actor_name            text,
  subject_membership_id uuid,
  subject_name          text,
  old_value             text,
  new_value             text
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_owner_of(p_chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  return query
    select l.id, l.occurred_at, l.txid, l.action,
           l.actor_id, a.full_name,
           l.subject_membership_id, s.full_name,
           l.old_value, l.new_value
      from public.access_change_log l
      left join public.member a             on a.id = l.actor_id
      left join public.chapter_membership s on s.id = l.subject_membership_id
     where l.scope = 'chapter'
       and l.chapter_id = p_chapter_id
       and (p_before_id is null or l.id < p_before_id)
     order by l.id desc
     limit least(greatest(coalesce(p_limit, 50), 1), 200);
end $$;

create or replace function public.platform_access_log(
  p_limit     int    default 50,
  p_before_id bigint default null
)
returns table (
  id           bigint,
  occurred_at  timestamptz,
  txid         bigint,
  action       text,
  actor_id     uuid,
  actor_name   text,
  subject_member_id uuid,
  subject_name text,
  old_value    text,
  new_value    text
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_platform_admin() then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  return query
    select l.id, l.occurred_at, l.txid, l.action,
           l.actor_id, a.full_name,
           l.subject_member_id, s.full_name,
           l.old_value, l.new_value
      from public.access_change_log l
      left join public.member a on a.id = l.actor_id
      left join public.member s on s.id = l.subject_member_id
     where l.scope = 'platform'
       and (p_before_id is null or l.id < p_before_id)
     order by l.id desc
     limit least(greatest(coalesce(p_limit, 50), 1), 200);
end $$;

revoke execute on function
  public.chapter_access_log(uuid, int, bigint),
  public.platform_access_log(int, bigint)
from public, anon;

grant execute on function
  public.chapter_access_log(uuid, int, bigint),
  public.platform_access_log(int, bigint)
to authenticated;

commit;
