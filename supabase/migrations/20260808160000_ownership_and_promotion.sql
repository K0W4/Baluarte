-- Phase 5 — Ownership, promotion and the second chapter.
--
-- access_level is never granted to `authenticated`, which is the whole reason nobody
-- can promote themselves. The flip side is that promotion has to live in a function
-- running as the owner of the schema, with the rules written out explicitly.

begin;

-- ---------------------------------------------------------------------------
-- Promote / demote. Owner is deliberately unreachable here: becoming Fundador is a
-- transfer, not a promotion, so there is always exactly one path to that role.
-- ---------------------------------------------------------------------------

create or replace function public.set_membership_access_level(
  p_membership_id uuid,
  p_access_level  public.access_level
)
returns public.chapter_membership language plpgsql security definer set search_path = '' as $$
declare v_membership public.chapter_membership;
begin
  select * into v_membership
    from public.chapter_membership
   where id = p_membership_id
     for update;

  if not found then
    raise exception 'Vínculo não encontrado.' using errcode = 'P0002';
  end if;

  if not public.is_owner_of(v_membership.chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_membership.member_id is null then
    raise exception 'Este cadastro ainda não pertence a ninguém, então não tem acesso para ajustar.'
      using errcode = '23514';
  end if;

  if v_membership.member_id = (select auth.uid()) then
    raise exception 'Você não pode alterar o próprio nível de acesso.' using errcode = '23514';
  end if;

  if p_access_level = 'owner' or v_membership.access_level = 'owner' then
    raise exception 'Fundador se define pela transferência de propriedade.' using errcode = '23514';
  end if;

  update public.chapter_membership
     set access_level = p_access_level
   where id = p_membership_id
  returning * into v_membership;

  return v_membership;
end $$;

-- ---------------------------------------------------------------------------
-- Transfer. Two rows have to move together: leaving the old owner as owner would
-- create a second one, and clearing them first would orphan the chapter mid-statement.
-- ---------------------------------------------------------------------------

create or replace function public.transfer_chapter_ownership(p_to_membership_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_target public.chapter_membership;
begin
  select * into v_target
    from public.chapter_membership
   where id = p_to_membership_id
     for update;

  if not found then
    raise exception 'Vínculo não encontrado.' using errcode = 'P0002';
  end if;

  if not public.is_owner_of(v_target.chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_target.status <> 'active' or v_target.member_id is null then
    raise exception 'A propriedade só pode ser transferida para alguém ativo e com conta no app.'
      using errcode = '23514';
  end if;

  if v_target.member_id = (select auth.uid()) then
    raise exception 'Você já é o Fundador deste Capítulo.' using errcode = '23514';
  end if;

  update public.chapter_membership
     set access_level = 'admin'
   where chapter_id = v_target.chapter_id
     and member_id  = (select auth.uid())
     and status     = 'active';

  update public.chapter_membership
     set access_level = 'owner'
   where id = p_to_membership_id;
end $$;

revoke execute on function
  public.set_membership_access_level(uuid, public.access_level),
  public.transfer_chapter_ownership(uuid)
from public, anon;

grant execute on function
  public.set_membership_access_level(uuid, public.access_level),
  public.transfer_chapter_ownership(uuid)
to authenticated;

commit;
