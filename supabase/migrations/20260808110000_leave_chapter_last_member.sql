-- Refina a regra de saída do Capítulo.
--
-- A versão anterior recusava todo último Fundador. A intenção estava certa -- um
-- Capítulo sem dono não teria mais ninguém capaz de aprovar ninguém, para sempre --
-- mas a regra era ampla demais: se você é a única pessoa ativa do Capítulo, sair não
-- deixa ninguém órfão. Havia gente que não conseguia sair de um Capítulo vazio, e sem
-- transferência de propriedade (Fase 5) isso era um beco sem saída.
--
-- A regra passa a ser: recusa só quando existe mais alguém que ficaria sem dono.

begin;

create or replace function public.leave_chapter(p_chapter_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_level        public.access_level;
  v_owners       int;
  v_other_actives int;
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
    select count(*) filter (where cm.access_level = 'owner'),
           count(*) filter (where cm.member_id is distinct from (select auth.uid()))
      into v_owners, v_other_actives
      from public.chapter_membership cm
     where cm.chapter_id = p_chapter_id
       and cm.status = 'active';

    if v_owners <= 1 and v_other_actives > 0 then
      raise exception 'Você é o único Fundador e ainda há % pessoa(s) no Capítulo. Promova outro Fundador antes de sair.', v_other_actives
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

commit;
