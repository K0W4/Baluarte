-- Phase 0 — Chapter membership foundation
--
-- Splits the person (member) from the chapter bond (chapter_membership), introduces
-- three real access levels enforced by RLS, and preserves every existing UUID so that
-- committee.member_ids, task.assignee_id/creator_id and event.confirmed_attendees keep
-- resolving without a rewrite.
--
-- Safe to run once, on a database that holds test data only.

begin;

-- ---------------------------------------------------------------------------
-- 1. Enums
-- ---------------------------------------------------------------------------

do $$ begin
  create type public.access_level as enum ('member', 'admin', 'owner');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.membership_status as enum ('active', 'inactive');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.membership_category as enum ('ativo', 'senior', 'macom');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- 2. member becomes the person
-- ---------------------------------------------------------------------------

alter table public.member
  add column if not exists active_chapter_id uuid references public.chapter(id) on delete set null,
  add column if not exists is_platform_admin boolean not null default false;

-- ---------------------------------------------------------------------------
-- 3. chapter_membership — the bond
-- ---------------------------------------------------------------------------

create table if not exists public.chapter_membership (
  id           uuid primary key default gen_random_uuid(),
  chapter_id   uuid not null references public.chapter(id) on delete cascade,
  member_id    uuid references public.member(id) on delete cascade,
  full_name    text not null,
  category     public.membership_category not null default 'ativo',
  role         text,
  cid          text,
  birthdate    date,
  access_level public.access_level      not null default 'member',
  status       public.membership_status not null default 'active',
  joined_at    timestamptz,
  approved_by  uuid references public.member(id) on delete set null,
  created_at   timestamptz not null default now(),
  unique (chapter_id, member_id)
);

create index if not exists chapter_membership_member_active_idx
  on public.chapter_membership (member_id, chapter_id) where status = 'active';
create index if not exists chapter_membership_chapter_idx
  on public.chapter_membership (chapter_id);

-- ---------------------------------------------------------------------------
-- 4. RLS helper functions
--
-- security definer bypasses RLS on the inner read, which is what stops a policy on
-- chapter_membership that reads chapter_membership from recursing forever.
-- set search_path = '' forces full qualification and closes the standard Supabase
-- privilege-escalation hole. (select auth.uid()) is hoisted to an InitPlan and so is
-- evaluated once per statement instead of once per row.
-- ---------------------------------------------------------------------------

create or replace function public.is_member_of(p_chapter_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chapter_membership cm
    where cm.chapter_id = p_chapter_id
      and cm.member_id  = (select auth.uid())
      and cm.status     = 'active'
  );
$$;

create or replace function public.is_admin_of(p_chapter_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chapter_membership cm
    where cm.chapter_id = p_chapter_id
      and cm.member_id  = (select auth.uid())
      and cm.status     = 'active'
      and cm.access_level in ('admin', 'owner')
  );
$$;

create or replace function public.is_owner_of(p_chapter_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chapter_membership cm
    where cm.chapter_id = p_chapter_id
      and cm.member_id  = (select auth.uid())
      and cm.status     = 'active'
      and cm.access_level = 'owner'
  );
$$;

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select m.is_platform_admin from public.member m where m.id = (select auth.uid())),
    false
  );
$$;

create or replace function public.shares_chapter_with(p_member_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.chapter_membership mine
    join public.chapter_membership theirs on theirs.chapter_id = mine.chapter_id
    where mine.member_id   = (select auth.uid()) and mine.status   = 'active'
      and theirs.member_id = p_member_id         and theirs.status = 'active'
  );
$$;

revoke execute on function
  public.is_member_of(uuid), public.is_admin_of(uuid), public.is_owner_of(uuid),
  public.is_platform_admin(), public.shares_chapter_with(uuid)
from public, anon;

grant execute on function
  public.is_member_of(uuid), public.is_admin_of(uuid), public.is_owner_of(uuid),
  public.is_platform_admin(), public.shares_chapter_with(uuid)
to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Backfill — identity preserving
--
-- chapter_membership.id inherits member.id, so every UUID already referenced by
-- committee.member_ids, committee.chairman_id, event.confirmed_attendees,
-- task.assignee_id and task.creator_id keeps resolving.
-- ---------------------------------------------------------------------------

insert into public.chapter_membership
  (id, chapter_id, member_id, full_name, category, role, cid, birthdate,
   access_level, status, joined_at, created_at)
select
  m.id,
  m.chapter_id,
  case when exists (select 1 from auth.users u where u.id = m.id) then m.id else null end,
  m.full_name,
  case
    when m.is_mason  then 'macom'
    when m.is_senior then 'senior'
    else 'ativo'
  end::public.membership_category,
  m.role,
  m.cid,
  m.birthdate,
  case
    when lower(coalesce(m.access_level, '')) in ('admin', 'owner')
      then lower(m.access_level)::public.access_level
    else 'member'::public.access_level
  end,
  'active',
  m.created_at,
  m.created_at
from public.member m
where m.chapter_id is not null
on conflict (id) do nothing;

update public.member m
   set active_chapter_id = m.chapter_id
 where m.chapter_id is not null;

-- Pre-flight assertion: abort before the destructive delete if any chapter-scoped
-- reference points at a member row that is about to disappear without a membership
-- inheriting its id.
do $$
declare
  v_destroyed int;
  v_dangling  int;
begin
  with refs as (
    select unnest(c.member_ids) as ref from public.committee c
    union
    select c.chairman_id from public.committee c where c.chairman_id is not null
    union
    select unnest(e.confirmed_attendees) from public.event e
    union
    select t.assignee_id from public.task t where t.assignee_id is not null
    union
    select t.creator_id from public.task t
  )
  select
    count(*) filter (
      where     exists (select 1 from public.member m  where m.id = refs.ref)
        and not exists (select 1 from auth.users  u    where u.id = refs.ref)
    ),
    count(*) filter (
      where not exists (select 1 from public.member m  where m.id = refs.ref)
    )
  into v_destroyed, v_dangling
  from refs
  where refs.ref is not null
    and not exists (select 1 from public.chapter_membership cm where cm.id = refs.ref);

  if v_dangling > 0 then
    raise warning 'Backfill: % referência(s) já apontavam para membros inexistentes antes desta migration.', v_dangling;
  end if;

  if v_destroyed > 0 then
    raise exception 'Backfill abortado: % referência(s) seriam destruídas pela limpeza de member. Investigue antes de reaplicar.', v_destroyed;
  end if;
end $$;

-- Accountless roster rows lived in member with synthetic UUIDs. Their ids now live on
-- as chapter_membership.id, so the fake person rows can go.
delete from public.member m
 where not exists (select 1 from auth.users u where u.id = m.id);

alter table public.member
  drop constraint if exists member_id_fkey;
alter table public.member
  add constraint member_id_fkey foreign key (id) references auth.users(id) on delete cascade;

alter table public.member
  drop column if exists chapter_id,
  drop column if exists role,
  drop column if exists is_active,
  drop column if exists is_senior,
  drop column if exists is_mason,
  drop column if exists access_level;

-- ---------------------------------------------------------------------------
-- 6. Triggers
-- ---------------------------------------------------------------------------

-- Double affiliation limit. A bare count() is racy under concurrent inserts, so the
-- advisory lock keyed on member_id serialises the check.
create or replace function public.enforce_membership_limit()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_count int;
begin
  if new.member_id is null or new.status <> 'active' then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.member_id::text, 0));

  select count(*) into v_count
    from public.chapter_membership cm
   where cm.member_id = new.member_id
     and cm.status    = 'active'
     and cm.id       <> new.id;

  if v_count >= 2 then
    raise exception 'Você já participa de dois Capítulos. Saia de um antes de entrar em outro.'
      using errcode = '23514';
  end if;

  return new;
end $$;

drop trigger if exists chapter_membership_limit on public.chapter_membership;
create trigger chapter_membership_limit
  before insert or update of member_id, status on public.chapter_membership
  for each row execute function public.enforce_membership_limit();

-- chapter_id is immutable. Without this an admin can PATCH a row into another chapter,
-- which every is_admin_of() policy would happily allow on the way out.
create or replace function public.reject_chapter_id_change()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.chapter_id is distinct from old.chapter_id then
    raise exception 'O Capítulo de um registro não pode ser alterado.' using errcode = '42501';
  end if;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['event', 'goal', 'task', 'committee', 'chapter_membership'] loop
    execute format('drop trigger if exists %I_chapter_id_immutable on public.%I', t, t);
    execute format(
      'create trigger %I_chapter_id_immutable before update of chapter_id on public.%I
       for each row execute function public.reject_chapter_id_change()', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 7. RLS
--
-- Every pre-existing policy on the affected tables is dropped first so the resulting
-- state is knowable — policies are permissive and OR together, so one forgotten
-- permissive policy silently defeats everything below.
-- ---------------------------------------------------------------------------

do $$
declare r record;
begin
  for r in
    select tablename, policyname from pg_policies
     where schemaname = 'public'
       and tablename in ('member', 'event', 'goal', 'task', 'committee', 'chapter_membership')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

alter table public.chapter_membership enable row level security;
alter table public.member             enable row level security;
alter table public.event              enable row level security;
alter table public.goal               enable row level security;
alter table public.task               enable row level security;
alter table public.committee          enable row level security;

-- Direct predicate, never the helper: someone with no membership at all must still be
-- able to read their own row.
create policy cm_select_self on public.chapter_membership for select to authenticated
  using (member_id = (select auth.uid()));

create policy cm_select_chapter on public.chapter_membership for select to authenticated
  using (public.is_member_of(chapter_id));

create policy cm_insert_admin_roster on public.chapter_membership for insert to authenticated
  with check (public.is_admin_of(chapter_id) and member_id is null);

create policy cm_update_admin on public.chapter_membership for update to authenticated
  using (public.is_admin_of(chapter_id))
  with check (public.is_admin_of(chapter_id));

create policy cm_delete_admin on public.chapter_membership for delete to authenticated
  using (public.is_admin_of(chapter_id) and member_id is null);

-- TEMPORARY: keeps joining a chapter working between Phase 0 and Phase 2.
-- REMOVE in Phase 2, when join_request takes over.
-- access_level is not granted to authenticated, so the row is always born as 'member'.
create policy cm_insert_self_provisional on public.chapter_membership for insert to authenticated
  with check (member_id = (select auth.uid()) and status = 'active');

create policy member_select on public.member for select to authenticated
  using (id = (select auth.uid()) or public.shares_chapter_with(id));
create policy member_insert_self on public.member for insert to authenticated
  with check (id = (select auth.uid()));
create policy member_update_self on public.member for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

do $$
declare t text;
begin
  foreach t in array array['event', 'goal', 'task', 'committee'] loop
    execute format(
      'create policy %I_select on public.%I for select to authenticated
       using (public.is_member_of(chapter_id))', t, t);
  end loop;
end $$;

create policy event_write_admin on public.event for all to authenticated
  using (public.is_admin_of(chapter_id)) with check (public.is_admin_of(chapter_id));
create policy goal_write_admin on public.goal for all to authenticated
  using (public.is_admin_of(chapter_id)) with check (public.is_admin_of(chapter_id));
create policy committee_write_admin on public.committee for all to authenticated
  using (public.is_admin_of(chapter_id)) with check (public.is_admin_of(chapter_id));

-- Members create and complete tasks — decided business rule.
create policy task_write_member on public.task for all to authenticated
  using (public.is_member_of(chapter_id)) with check (public.is_member_of(chapter_id));

-- ---------------------------------------------------------------------------
-- 8. Column privileges
--
-- RLS is blind to columns: without this, PATCH /member?id=eq.<self> with
-- {"is_platform_admin": true} succeeds. PostgREST honours column privileges and
-- returns 403, so withholding the grant is the whole fix — no trigger needed.
-- access_level and approved_by are never granted, so only the security definer
-- functions can ever write them.
-- ---------------------------------------------------------------------------

revoke update on public.member from authenticated;
grant  update (full_name, cid, birthdate, active_chapter_id)
  on public.member to authenticated;

revoke insert, update, delete on public.chapter_membership from authenticated;
grant  insert (chapter_id, member_id, full_name, category, role, cid, birthdate, status)
  on public.chapter_membership to authenticated;
grant  update (full_name, category, role, cid, birthdate, status)
  on public.chapter_membership to authenticated;
grant  delete on public.chapter_membership to authenticated;

-- ---------------------------------------------------------------------------
-- 9. chapter_roster — compatibility projection
--
-- Keeps the shape the app's Member model already decodes, so the roster, committee
-- and attendance screens need no change. security_invoker is mandatory: without it
-- the view runs as its owner and bypasses every policy underneath.
-- ---------------------------------------------------------------------------

create or replace view public.chapter_roster with (security_invoker = on) as
select
  cm.id,
  cm.chapter_id,
  cm.full_name,
  cm.role,
  (cm.category = 'ativo')  as is_active,
  (cm.category = 'senior') as is_senior,
  (cm.category = 'macom')  as is_mason,
  cm.access_level::text    as access_level,
  cm.birthdate,
  cm.cid,
  cm.created_at
from public.chapter_membership cm
where cm.status = 'active';

grant select on public.chapter_roster to authenticated;

-- ---------------------------------------------------------------------------
-- 10. set_event_attendance
--
-- A plain UPDATE policy cannot inspect an array delta, so it would let any member
-- confirm attendance for anyone else. This also removes the read-modify-write race
-- the app and the widget both had.
--
-- Takes the desired state rather than toggling: the caller always states what it
-- wants, so a double-fired widget button cannot silently undo a confirmation.
-- ---------------------------------------------------------------------------

create or replace function public.set_event_attendance(p_event_id uuid, p_confirmed boolean)
returns public.event language plpgsql security definer set search_path = '' as $$
declare
  v_event public.event;
  v_me    uuid;
begin
  select * into v_event from public.event where id = p_event_id for update;

  if not found then
    raise exception 'Evento não encontrado.' using errcode = 'P0002';
  end if;

  select cm.id into v_me
    from public.chapter_membership cm
   where cm.chapter_id = v_event.chapter_id
     and cm.member_id  = (select auth.uid())
     and cm.status     = 'active';

  if v_me is null then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  update public.event
     set confirmed_attendees = case
           when p_confirmed
             then (select array(
                     select distinct unnest(
                       array_append(coalesce(confirmed_attendees, '{}'::uuid[]), v_me))))
             else array_remove(coalesce(confirmed_attendees, '{}'::uuid[]), v_me)
         end
   where id = p_event_id
   returning * into v_event;

  return v_event;
end $$;

revoke execute on function public.set_event_attendance(uuid, boolean) from public, anon;
grant  execute on function public.set_event_attendance(uuid, boolean) to authenticated;

commit;
