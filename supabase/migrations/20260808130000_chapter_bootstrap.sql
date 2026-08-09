-- Phase 4 — The empty chapter.
--
-- Every other door needs somebody already inside: a request needs an admin to approve
-- it, an invite needs an admin to generate it. A chapter nobody has claimed has neither,
-- so the first person through has to be reviewed by the platform, not by the chapter.
--
-- This is one approval per chapter, once ever. Fifty chapters is fifty decisions in
-- total, and each one unlocks a chapter that runs itself with invites from then on.
--
-- Deliberately not automated: "first to arrive owns it" is exactly the impersonation
-- vector the whole design avoids, and chapters hold the data of minors.

begin;

-- Private on purpose: a photo of somebody's membership card is not public content.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bootstrap-proof', 'bootstrap-proof', false, 8388608,
        array['image/jpeg', 'image/png', 'image/heic'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists proof_insert_own on storage.objects;
drop policy if exists proof_select_own on storage.objects;
drop policy if exists proof_delete_own on storage.objects;

-- Path convention is {auth.uid()}/{request_id}.jpg, so the first folder is the owner.
create policy proof_insert_own on storage.objects for insert to authenticated
  with check (
    bucket_id = 'bootstrap-proof'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy proof_select_own on storage.objects for select to authenticated
  using (
    bucket_id = 'bootstrap-proof'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or public.is_platform_admin()
    )
  );

create policy proof_delete_own on storage.objects for delete to authenticated
  using (
    bucket_id = 'bootstrap-proof'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ---------------------------------------------------------------------------
-- A bootstrap request only makes sense for a chapter with no owner. Asking to
-- found a chapter that already has one is a request nobody should be able to
-- approve, so it is refused at insert rather than left to die in a queue.
-- ---------------------------------------------------------------------------

drop policy if exists jr_insert_self on public.join_request;

create policy jr_insert_self on public.join_request for insert to authenticated
  with check (
    member_id = (select auth.uid())
    and status = 'pending'
    and not public.is_member_of(chapter_id)
    and (
      kind = 'chapter_join'
      or not exists (
        select 1 from public.chapter c where c.id = chapter_id and c.has_owner
      )
    )
  );

-- Same guard at approval time: has_owner can flip between the request and the review.
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
  v_has_owner  boolean;
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

    select c.has_owner into v_has_owner from public.chapter c where c.id = v_request.chapter_id;
    if coalesce(v_has_owner, false) then
      raise exception 'Este Capítulo já tem um Fundador. Quem quiser entrar deve solicitar a ele.'
        using errcode = '23514';
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

-- ---------------------------------------------------------------------------
-- A platform admin reviews bootstrap requests across every chapter, so they need
-- one query that spans chapters — is_admin_of() would not reach any of them.
-- ---------------------------------------------------------------------------

create or replace function public.pending_bootstrap_requests()
returns table (
  id           uuid,
  chapter_id   uuid,
  member_id    uuid,
  message      text,
  cid_snapshot text,
  proof_path   text,
  created_at   timestamptz,
  applicant_name text,
  chapter_name text,
  chapter_number int,
  chapter_uf   char(2)
)
language sql stable security definer set search_path = '' as $$
  select jr.id, jr.chapter_id, jr.member_id, jr.message, jr.cid_snapshot, jr.proof_path,
         jr.created_at, m.full_name, c.name, c.number, c.uf
    from public.join_request jr
    join public.member  m on m.id = jr.member_id
    join public.chapter c on c.id = jr.chapter_id
   where jr.kind = 'chapter_bootstrap'
     and jr.status = 'pending'
     and public.is_platform_admin()
   order by jr.created_at;
$$;

revoke execute on function public.pending_bootstrap_requests() from public, anon;
grant  execute on function public.pending_bootstrap_requests() to authenticated;

commit;
