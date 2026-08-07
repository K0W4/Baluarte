-- Phase 1 — Chapter becomes a curated, read-only registry.
--
-- Until now anyone could create a chapter, which fragments the base: three rows for
-- "Capítulo Abrahan Lincoln nº 1" and nobody knows which one their brothers joined.
-- From here the table is reference data. People find their chapter; they never invent it.
--
-- Also fixes a real modelling bug: chapter numbers were globally unique, but in Brazil
-- numbering is per state jurisdiction, so (uf, number) is the real key.

begin;

create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm  with schema extensions;

alter table public.chapter
  add column if not exists uf        char(2),
  add column if not exists city      text,
  add column if not exists status    text not null default 'active'
    check (status in ('active', 'dormant', 'pending_review')),
  add column if not exists has_owner boolean not null default false;

-- unaccent() is only STABLE, and a generated column requires IMMUTABLE. Pinning the
-- dictionary by regdictionary is the standard way to make it immutable honestly.
create or replace function public.immutable_unaccent(text)
returns text language sql immutable strict parallel safe as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, $1)
$$;

-- Abort before touching constraints if the existing rows cannot satisfy the new key.
do $$
declare v_detail text;
begin
  select string_agg(d.line, E'\n')
    into v_detail
    from (
      select format('  nº %s (uf %s) → %s',
                    c.number,
                    coalesce(c.uf, 'sem UF'),
                    string_agg(format('%s [%s]', c.name, c.id), ', ' order by c.created_at)) as line
        from public.chapter c
       group by c.number, c.uf
      having count(*) > 1
    ) d;

  if v_detail is not null then
    raise exception E'Capítulos duplicados impedem a chave (uf, number):\n%\n\nApague ou renumere os excedentes antes de reaplicar. Confira antes se algum deles tem membros, eventos ou metas ligados.', v_detail;
  end if;
end $$;

-- The old constraint was on number alone; its generated name is unknown, so drop
-- every unique constraint on the table and state the correct one explicitly.
do $$
declare r record;
begin
  for r in
    select con.conname
      from pg_constraint con
      join pg_class rel on rel.oid = con.conrelid
      join pg_namespace n on n.oid = rel.relnamespace
     where n.nspname = 'public' and rel.relname = 'chapter' and con.contype = 'u'
  loop
    execute format('alter table public.chapter drop constraint %I', r.conname);
  end loop;
end $$;

-- nulls not distinct: two rows awaiting a UF with the same number must still collide.
alter table public.chapter
  add constraint chapter_uf_number_key unique nulls not distinct (uf, number);

alter table public.chapter
  add column if not exists search_text text
  generated always as (
    public.immutable_unaccent(lower(
      coalesce(name, '')     || ' ' ||
      coalesce(city, '')     || ' ' ||
      coalesce(uf, '')       || ' ' ||
      coalesce(number::text, '')
    ))
  ) stored;

create index if not exists chapter_search_trgm
  on public.chapter using gin (search_text extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- RLS: public read, no writes at all
-- ---------------------------------------------------------------------------

alter table public.chapter enable row level security;

do $$
declare r record;
begin
  for r in select policyname from pg_policies where schemaname = 'public' and tablename = 'chapter'
  loop
    execute format('drop policy %I on public.chapter', r.policyname);
  end loop;
end $$;

create policy chapter_public_read on public.chapter for select to anon, authenticated
  using (true);

revoke insert, update, delete on public.chapter from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Search: accent- and case-insensitive, optionally narrowed by state
-- ---------------------------------------------------------------------------

create or replace function public.search_chapters(p_query text default null, p_uf text default null)
returns setof public.chapter language sql stable set search_path = '' as $$
  select c.*
    from public.chapter c
   where c.status <> 'pending_review'
     and (p_uf is null or p_uf = '' or c.uf = upper(p_uf))
     and (
       p_query is null or p_query = ''
       or c.search_text like '%' || public.immutable_unaccent(lower(p_query)) || '%'
     )
   order by c.uf nulls last, c.name
   limit 50;
$$;

grant execute on function public.search_chapters(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- has_owner — drives the Phase 4 fork: a chapter with no owner routes to the
-- bootstrap flow instead of a join request nobody could approve. Public by design;
-- it leaks nothing.
-- ---------------------------------------------------------------------------

create or replace function public.sync_chapter_has_owner()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_chapter uuid;
begin
  v_chapter := coalesce(new.chapter_id, old.chapter_id);

  update public.chapter c
     set has_owner = exists (
       select 1 from public.chapter_membership cm
        where cm.chapter_id = v_chapter
          and cm.status = 'active'
          and cm.access_level = 'owner'
     )
   where c.id = v_chapter;

  return null;
end $$;

drop trigger if exists chapter_membership_owner_sync on public.chapter_membership;
create trigger chapter_membership_owner_sync
  after insert or update or delete on public.chapter_membership
  for each row execute function public.sync_chapter_has_owner();

update public.chapter c
   set has_owner = exists (
     select 1 from public.chapter_membership cm
      where cm.chapter_id = c.id
        and cm.status = 'active'
        and cm.access_level = 'owner'
   );

-- ---------------------------------------------------------------------------
-- chapter_request — "my chapter isn't listed"
--
-- A separate table, not a pending_review row in chapter: a pending row would be
-- publicly searchable, joinable before it is real, and would consume a (uf, number)
-- slot that the real chapter needs.
-- ---------------------------------------------------------------------------

create table if not exists public.chapter_request (
  id           uuid primary key default gen_random_uuid(),
  requested_by uuid not null references public.member(id) on delete cascade,
  name         text not null,
  number       int  not null,
  uf           char(2) not null,
  city         text,
  note         text,
  status       text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at   timestamptz not null default now(),
  reviewed_by  uuid references public.member(id) on delete set null,
  reviewed_at  timestamptz
);

create index if not exists chapter_request_pending_idx
  on public.chapter_request (created_at desc) where status = 'pending';

alter table public.chapter_request enable row level security;

create policy cr_insert_self on public.chapter_request for insert to authenticated
  with check (requested_by = (select auth.uid()) and status = 'pending');

create policy cr_select_own on public.chapter_request for select to authenticated
  using (requested_by = (select auth.uid()) or public.is_platform_admin());

revoke all on public.chapter_request from anon, authenticated;
grant select on public.chapter_request to authenticated;
grant insert (requested_by, name, number, uf, city, note)
  on public.chapter_request to authenticated;

commit;
