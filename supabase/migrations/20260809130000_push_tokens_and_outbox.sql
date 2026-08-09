-- Pacote 5, primeira camada: para onde mandar, e o que mandar.
--
-- A entrega em si (falar APNs) fica numa Edge Function, que depende da chave .p8 e
-- não pode ser verificada aqui. O que dá para deixar pronto e provado é o resto: o
-- registro do aparelho e a fila do que precisa sair.
--
-- ---------------------------------------------------------------------------
-- device_token
--
-- Um token é do aparelho, não da pessoa: a mesma pessoa tem iPhone e iPad, e o
-- mesmo iPhone pode ser usado por duas pessoas. A chave é o token, e ele migra de
-- dono no upsert -- se não migrasse, quem entrasse depois receberia as notificações
-- de quem saiu.
--
-- O token da APNs não é segredo (não autentica ninguém), mas é identificador de
-- aparelho: ninguém além do dono precisa lê-lo, e ninguém precisa listá-los.
--
-- ---------------------------------------------------------------------------
-- notification_outbox
--
-- Gatilho não fala com a internet. O que ele faz é gravar aqui o que precisa sair, e
-- a Edge Function consome. Isso também é o que torna a coisa testável sem APNs
-- nenhum: o gatilho é provável por SQL, e a entrega é problema de outra camada.
--
-- A tabela não tem policy alguma para `authenticated`. Nada no app lê ou escreve
-- nela; quem consome é a função, com service_role.

begin;

create table if not exists public.device_token (
  token       text primary key,
  member_id   uuid not null references public.member(id) on delete cascade,
  platform    text not null default 'ios' check (platform in ('ios')),
  created_at  timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index if not exists device_token_member_idx on public.device_token (member_id);

alter table public.device_token enable row level security;

drop policy if exists dt_select_own on public.device_token;
drop policy if exists dt_insert_own on public.device_token;
drop policy if exists dt_update_own on public.device_token;
drop policy if exists dt_delete_own on public.device_token;

create policy dt_select_own on public.device_token for select to authenticated
  using (member_id = (select auth.uid()));

create policy dt_insert_own on public.device_token for insert to authenticated
  with check (member_id = (select auth.uid()));

-- O upsert de um token que já existe cai aqui, e é como o aparelho troca de dono.
create policy dt_update_own on public.device_token for update to authenticated
  using (true)
  with check (member_id = (select auth.uid()));

create policy dt_delete_own on public.device_token for delete to authenticated
  using (member_id = (select auth.uid()));

revoke all on public.device_token from anon, authenticated;
grant select, insert, update, delete on public.device_token to authenticated;

-- ---------------------------------------------------------------------------

create table if not exists public.notification_outbox (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.member(id) on delete cascade,
  kind         text not null,
  -- Chave de tradução, não frase: o servidor não sabe o idioma do aparelho, pela
  -- mesma razão que os `raise` carregam hint em vez de texto pronto.
  title_key    text not null,
  body_key     text not null,
  body_args    jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  delivered_at timestamptz,
  attempts     int not null default 0
);

create index if not exists notification_outbox_pending_idx
  on public.notification_outbox (created_at)
  where delivered_at is null;

alter table public.notification_outbox enable row level security;
-- Sem policy nenhuma, de propósito: nada no app toca esta tabela.

revoke all on public.notification_outbox from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Gatilhos. Cada um responde a uma pergunta que hoje só é respondida abrindo o app.
-- ---------------------------------------------------------------------------

create or replace function public.enqueue_join_request_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.kind = 'chapter_bootstrap' then
    -- Fundação: avisa quem revisa, que é a plataforma inteira.
    insert into public.notification_outbox (member_id, kind, title_key, body_key)
    select m.id, 'bootstrap_requested', 'baluarte.push_bootstrap_title', 'baluarte.push_bootstrap_body'
      from public.member m
     where m.is_platform_admin;
  else
    -- Entrada: avisa quem pode aprovar naquele Capítulo.
    insert into public.notification_outbox (member_id, kind, title_key, body_key)
    select cm.member_id, 'join_requested', 'baluarte.push_join_title', 'baluarte.push_join_body'
      from public.chapter_membership cm
     where cm.chapter_id = new.chapter_id
       and cm.status = 'active'
       and cm.access_level in ('admin', 'owner')
       and cm.member_id is not null;
  end if;

  return new;
end $$;

drop trigger if exists join_request_notify on public.join_request;
create trigger join_request_notify
  after insert on public.join_request
  for each row execute function public.enqueue_join_request_notifications();

create or replace function public.enqueue_join_request_review()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = old.status or new.member_id is null then
    return new;
  end if;

  if new.status = 'approved' then
    insert into public.notification_outbox (member_id, kind, title_key, body_key)
    values (new.member_id, 'join_approved', 'baluarte.push_approved_title', 'baluarte.push_approved_body');
  elsif new.status = 'rejected' then
    insert into public.notification_outbox (member_id, kind, title_key, body_key)
    values (new.member_id, 'join_rejected', 'baluarte.push_rejected_title', 'baluarte.push_rejected_body');
  end if;

  return new;
end $$;

drop trigger if exists join_request_review_notify on public.join_request;
create trigger join_request_review_notify
  after update of status on public.join_request
  for each row execute function public.enqueue_join_request_review();

commit;
