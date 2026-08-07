-- Phase 2 — Entering a chapter stops being self-service.
--
-- Until now joining was an INSERT you made on your own row (the provisional policy from
-- Phase 0). From here you ask, and someone already inside decides. This matters beyond
-- tidiness: chapters hold the birthdates and contact details of members aged 12–21, so
-- "anyone who finds the chapter can walk in" is not an acceptable default.

begin;

do $$ begin
  create type public.join_request_kind as enum ('chapter_join', 'chapter_bootstrap');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.join_request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
exception when duplicate_object then null; end $$;

create table if not exists public.join_request (
  id            uuid primary key default gen_random_uuid(),
  chapter_id    uuid not null references public.chapter(id) on delete cascade,
  member_id     uuid not null references public.member(id) on delete cascade,
  kind          public.join_request_kind   not null default 'chapter_join',
  status        public.join_request_status not null default 'pending',
  message       text,
  cid_snapshot  text,
  proof_path    text,
  created_at    timestamptz not null default now(),
  reviewed_by   uuid references public.member(id) on delete set null,
  reviewed_at   timestamptz,
  reject_reason text
);

-- One open request per person per chapter. A partial unique index says it without
-- forbidding a second attempt after a rejection.
create unique index if not exists join_request_one_pending
  on public.join_request (member_id, chapter_id) where status = 'pending';

create index if not exists join_request_queue_idx
  on public.join_request (chapter_id, created_at desc) where status = 'pending';

alter table public.join_request enable row level security;

create policy jr_insert_self on public.join_request for insert to authenticated
  with check (
    member_id = (select auth.uid())
    and status = 'pending'
    and not public.is_member_of(chapter_id)
  );

create policy jr_select_own on public.join_request for select to authenticated
  using (member_id = (select auth.uid()));

create policy jr_select_reviewer on public.join_request for select to authenticated
  using (
    public.is_admin_of(chapter_id)
    or (kind = 'chapter_bootstrap' and public.is_platform_admin())
  );

-- The column grant allows writing `status`; this policy is what restricts the value to
-- 'cancelled'. Approving and rejecting go through the RPCs below.
create policy jr_cancel_own on public.join_request for update to authenticated
  using (member_id = (select auth.uid()) and status = 'pending')
  with check (status = 'cancelled');

revoke all on public.join_request from anon, authenticated;
grant select on public.join_request to authenticated;
grant insert (chapter_id, member_id, kind, message, cid_snapshot, proof_path)
  on public.join_request to authenticated;
grant update (status) on public.join_request to authenticated;

-- ---------------------------------------------------------------------------
-- Approving inserts a membership for *someone else's* member_id, which no
-- `with check` can express: the right to do it comes from a pending request
-- existing, not from anything visible in the new row.
-- ---------------------------------------------------------------------------

create or replace function public.approve_join_request(
  p_request_id         uuid,
  p_access_level       public.access_level         default 'member',
  p_category           public.membership_category  default 'ativo',
  p_role               text                        default null,
  p_link_membership_id uuid                        default null
)
returns public.chapter_membership language plpgsql security definer set search_path = '' as $$
declare
  v_request    public.join_request;
  v_level      public.access_level;
  v_membership public.chapter_membership;
  v_full_name  text;
begin
  select * into v_request from public.join_request where id = p_request_id for update;

  if not found then
    raise exception 'Solicitação não encontrada.' using errcode = 'P0002';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Esta solicitação já foi respondida.' using errcode = '23514';
  end if;

  if v_request.kind = 'chapter_bootstrap' then
    if not public.is_platform_admin() then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;
    v_level := 'owner';
  else
    if not public.is_admin_of(v_request.chapter_id) then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;
    if p_access_level = 'owner' then
      raise exception 'Para tornar alguém Fundador, use a transferência de propriedade.'
        using errcode = '23514';
    end if;
    v_level := p_access_level;
  end if;

  select m.full_name into v_full_name from public.member m where m.id = v_request.member_id;

  if p_link_membership_id is not null then
    -- Claiming a roster entry an admin created before this person had an account.
    update public.chapter_membership cm
       set member_id    = v_request.member_id,
           access_level = v_level,
           status       = 'active',
           joined_at    = now(),
           approved_by  = (select auth.uid())
     where cm.id         = p_link_membership_id
       and cm.chapter_id = v_request.chapter_id
       and cm.member_id  is null
    returning * into v_membership;

    if not found then
      raise exception 'O cadastro escolhido não existe mais ou já pertence a alguém.'
        using errcode = '23514';
    end if;
  else
    insert into public.chapter_membership
      (chapter_id, member_id, full_name, category, role, access_level, status, joined_at, approved_by)
    values
      (v_request.chapter_id, v_request.member_id, coalesce(v_full_name, 'Membro DeMolay'),
       p_category, p_role, v_level, 'active', now(), (select auth.uid()))
    returning * into v_membership;
  end if;

  update public.join_request
     set status = 'approved', reviewed_by = (select auth.uid()), reviewed_at = now()
   where id = p_request_id;

  update public.member
     set active_chapter_id = v_request.chapter_id
   where id = v_request.member_id and active_chapter_id is null;

  return v_membership;
end $$;

create or replace function public.reject_join_request(p_request_id uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare v_request public.join_request;
begin
  select * into v_request from public.join_request where id = p_request_id for update;

  if not found then
    raise exception 'Solicitação não encontrada.' using errcode = 'P0002';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Esta solicitação já foi respondida.' using errcode = '23514';
  end if;

  if v_request.kind = 'chapter_bootstrap' then
    if not public.is_platform_admin() then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;
  elsif not public.is_admin_of(v_request.chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  update public.join_request
     set status = 'rejected',
         reviewed_by = (select auth.uid()),
         reviewed_at = now(),
         reject_reason = p_reason
   where id = p_request_id;
end $$;

-- ---------------------------------------------------------------------------
-- Leaving has to refuse the last owner, otherwise the chapter is orphaned with
-- nobody able to approve anyone ever again.
-- ---------------------------------------------------------------------------

create or replace function public.leave_chapter(p_chapter_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_level  public.access_level;
  v_owners int;
begin
  select cm.access_level into v_level
    from public.chapter_membership cm
   where cm.chapter_id = p_chapter_id
     and cm.member_id  = (select auth.uid())
     and cm.status     = 'active'
     for update;

  if v_level is null then
    raise exception 'Você não participa deste Capítulo.' using errcode = 'P0002';
  end if;

  if v_level = 'owner' then
    select count(*) into v_owners
      from public.chapter_membership cm
     where cm.chapter_id = p_chapter_id
       and cm.status = 'active'
       and cm.access_level = 'owner';

    if v_owners <= 1 then
      raise exception 'Você é o único Fundador deste Capítulo. Transfira a propriedade antes de sair.'
        using errcode = '23514';
    end if;
  end if;

  update public.chapter_membership
     set status = 'inactive'
   where chapter_id = p_chapter_id
     and member_id  = (select auth.uid());

  update public.member
     set active_chapter_id = (
       select cm.chapter_id from public.chapter_membership cm
        where cm.member_id = (select auth.uid()) and cm.status = 'active' limit 1
     )
   where id = (select auth.uid());
end $$;

revoke execute on function
  public.approve_join_request(uuid, public.access_level, public.membership_category, text, uuid),
  public.reject_join_request(uuid, text),
  public.leave_chapter(uuid)
from public, anon;

grant execute on function
  public.approve_join_request(uuid, public.access_level, public.membership_category, text, uuid),
  public.reject_join_request(uuid, text),
  public.leave_chapter(uuid)
to authenticated;

-- The provisional self-join from Phase 0 has done its job.
drop policy if exists cm_insert_self_provisional on public.chapter_membership;

commit;
