-- "Não encontrado" para de sair como erro de servidor.
--
-- O PostgREST mapeia SQLSTATE para status HTTP por uma tabela própria, e P0002 não
-- está nela: cai no genérico e vira 500. Descoberto pela primeira execução de
-- supabase/tests/rls.sh, que é literalmente o motivo de aquelas sondas existirem.
--
-- O app nunca se importou -- AppError.from decide pelo `code` e pelo `hint`, e os
-- dois sempre vieram certos. O problema é operacional: seis RPCs devolvem 5xx para
-- condições normais, e um dia alguém investiga um pico de erro de servidor que era
-- só gente clicando numa solicitação já respondida.
--
-- PT404 é o mecanismo documentado do PostgREST para escolher o status: qualquer
-- errcode PTxyz vira HTTP xyz. Continua sendo um SQLSTATE válido, então o `hint`
-- viaja igual e a tradução não muda.
--
-- As funções são reescritas inteiras porque não há como remendar um raise isolado.
-- Só a linha do errcode muda em relação a 20260808190000.

begin;


-- ---------------------------------------------------------------------------
-- Gatilhos de chapter_membership (20260807120000)
-- ---------------------------------------------------------------------------

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
      using errcode = '23514', hint = 'baluarte.two_chapters_max';
  end if;

  return new;
end $$;

create or replace function public.reject_chapter_id_change()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.chapter_id is distinct from old.chapter_id then
    raise exception 'O Capítulo de um registro não pode ser alterado.'
      using errcode = '42501', hint = 'baluarte.chapter_immutable';
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- Presença em evento (20260807120000)
-- ---------------------------------------------------------------------------

create or replace function public.set_event_attendance(p_event_id uuid, p_confirmed boolean)
returns public.event language plpgsql security definer set search_path = '' as $$
declare
  v_event public.event;
  v_me    uuid;
begin
  select * into v_event from public.event where id = p_event_id for update;

  if not found then
    raise exception 'Evento não encontrado.'
      using errcode = 'PT404', hint = 'baluarte.event_not_found';
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

-- ---------------------------------------------------------------------------
-- Fila de aprovação (versão vigente em 20260808130000, que trata o bootstrap)
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
  v_has_owner  boolean;
begin
  select * into v_request from public.join_request where id = p_request_id for update;

  if not found then
    raise exception 'Solicitação não encontrada.'
      using errcode = 'PT404', hint = 'baluarte.request_not_found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Esta solicitação já foi respondida.'
      using errcode = '23514', hint = 'baluarte.request_already_reviewed';
  end if;

  if v_request.kind = 'chapter_bootstrap' then
    if not public.is_platform_admin() then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;

    select c.has_owner into v_has_owner from public.chapter c where c.id = v_request.chapter_id;
    if coalesce(v_has_owner, false) then
      raise exception 'Este Capítulo já tem um Fundador. Quem quiser entrar deve solicitar a ele.'
        using errcode = '23514', hint = 'baluarte.chapter_already_has_owner';
    end if;

    v_level := 'owner';
  else
    if not public.is_admin_of(v_request.chapter_id) then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;
    if p_access_level = 'owner' then
      raise exception 'Para tornar alguém Fundador, use a transferência de propriedade.'
        using errcode = '23514', hint = 'baluarte.owner_needs_transfer';
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
        using errcode = '23514', hint = 'baluarte.roster_entry_unavailable';
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
    raise exception 'Solicitação não encontrada.'
      using errcode = 'PT404', hint = 'baluarte.request_not_found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Esta solicitação já foi respondida.'
      using errcode = '23514', hint = 'baluarte.request_already_reviewed';
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
-- Saída do Capítulo (versão vigente em 20260808110000)
--
-- Único caso parametrizado da lista: a contagem viaja no próprio hint, depois do
-- dois-pontos, porque a frase traduzida precisa dela para fazer sentido.
-- ---------------------------------------------------------------------------

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
    raise exception 'Você não participa deste Capítulo.'
      using errcode = 'PT404', hint = 'baluarte.not_in_chapter';
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
        using errcode = '23514',
              hint = 'baluarte.last_owner_with_members:' || v_other_actives;
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

-- ---------------------------------------------------------------------------
-- Convites (20260808100000)
-- ---------------------------------------------------------------------------

create or replace function public.generate_invite_code()
returns text language plpgsql volatile set search_path = '' as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_code text;
  v_attempts int := 0;
begin
  loop
    v_code := '';
    for _ in 1..8 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;

    exit when not exists (select 1 from public.chapter_invite ci where ci.code = v_code);

    v_attempts := v_attempts + 1;
    if v_attempts > 20 then
      raise exception 'Não foi possível gerar um código único.'
        using errcode = '23514', hint = 'baluarte.invite_code_generation_failed';
    end if;
  end loop;

  return v_code;
end $$;

create or replace function public.redeem_chapter_invite(p_code text)
returns public.chapter_membership language plpgsql security definer set search_path = '' as $$
declare
  v_me          uuid := (select auth.uid());
  v_code        text;
  v_invite      public.chapter_invite;
  v_failures    int;
  v_membership  public.chapter_membership;
  v_full_name   text;
begin
  if v_me is null then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  v_code := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));

  if length(v_code) = 0 then
    raise exception 'Informe o código do convite.'
      using errcode = '23514', hint = 'baluarte.invite_code_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('invite:' || v_me::text, 0));

  select count(*) into v_failures
    from public.invite_attempt ia
   where ia.member_id = v_me
     and ia.succeeded = false
     and ia.attempted_at > now() - interval '15 minutes';

  if v_failures >= 10 then
    raise exception 'Muitas tentativas. Aguarde alguns minutos antes de tentar de novo.'
      using errcode = '23514', hint = 'baluarte.invite_rate_limited';
  end if;

  select * into v_invite from public.chapter_invite ci where ci.code = v_code for update;

  if not found
     or v_invite.revoked_at is not null
     or (v_invite.expires_at is not null and v_invite.expires_at < now())
     or (v_invite.max_uses is not null and v_invite.uses_count >= v_invite.max_uses) then
    insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
    -- Uma mensagem só para todos os modos de falha, de propósito: distinguir "expirado"
    -- de "não existe" conta a um atacante quais códigos são reais. O hint é único pelo
    -- mesmo motivo -- ele não pode revelar o que a mensagem esconde.
    raise exception 'Convite inválido ou expirado. Confira o código com quem enviou.'
      using errcode = '23514', hint = 'baluarte.invite_invalid';
  end if;

  if public.is_member_of(v_invite.chapter_id) then
    insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
    raise exception 'Você já participa deste Capítulo.'
      using errcode = '23514', hint = 'baluarte.already_member';
  end if;

  select m.full_name into v_full_name from public.member m where m.id = v_me;

  if v_invite.target_membership_id is not null then
    update public.chapter_membership cm
       set member_id   = v_me,
           status      = 'active',
           joined_at   = now(),
           approved_by = v_invite.created_by
     where cm.id         = v_invite.target_membership_id
       and cm.chapter_id = v_invite.chapter_id
       and cm.member_id  is null
    returning * into v_membership;

    if not found then
      insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
      raise exception 'O cadastro vinculado a este convite já pertence a alguém.'
        using errcode = '23514', hint = 'baluarte.roster_entry_taken';
    end if;
  else
    insert into public.chapter_membership
      (chapter_id, member_id, full_name, category, access_level, status, joined_at, approved_by)
    values
      (v_invite.chapter_id, v_me, coalesce(v_full_name, 'Membro DeMolay'),
       'ativo', 'member', 'active', now(), v_invite.created_by)
    returning * into v_membership;
  end if;

  update public.chapter_invite
     set uses_count = uses_count + 1
   where id = v_invite.id;

  insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, true);

  update public.member
     set active_chapter_id = v_invite.chapter_id
   where id = v_me and active_chapter_id is null;

  -- A pending request for this chapter is moot now.
  update public.join_request
     set status = 'cancelled'
   where member_id = v_me and chapter_id = v_invite.chapter_id and status = 'pending';

  return v_membership;
end $$;

-- ---------------------------------------------------------------------------
-- Promoção e transferência de posse (20260808160000)
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
    raise exception 'Vínculo não encontrado.'
      using errcode = 'PT404', hint = 'baluarte.membership_not_found';
  end if;

  if not public.is_owner_of(v_membership.chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_membership.member_id is null then
    raise exception 'Este cadastro ainda não pertence a ninguém, então não tem acesso para ajustar.'
      using errcode = '23514', hint = 'baluarte.membership_unclaimed';
  end if;

  if v_membership.member_id = (select auth.uid()) then
    raise exception 'Você não pode alterar o próprio nível de acesso.'
      using errcode = '23514', hint = 'baluarte.cannot_change_own_access';
  end if;

  if p_access_level = 'owner' or v_membership.access_level = 'owner' then
    raise exception 'Fundador se define pela transferência de propriedade.'
      using errcode = '23514', hint = 'baluarte.owner_needs_transfer';
  end if;

  update public.chapter_membership
     set access_level = p_access_level
   where id = p_membership_id
  returning * into v_membership;

  return v_membership;
end $$;

create or replace function public.transfer_chapter_ownership(p_to_membership_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_target public.chapter_membership;
begin
  select * into v_target
    from public.chapter_membership
   where id = p_to_membership_id
     for update;

  if not found then
    raise exception 'Vínculo não encontrado.'
      using errcode = 'PT404', hint = 'baluarte.membership_not_found';
  end if;

  if not public.is_owner_of(v_target.chapter_id) then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_target.status <> 'active' or v_target.member_id is null then
    raise exception 'A propriedade só pode ser transferida para alguém ativo e com conta no app.'
      using errcode = '23514', hint = 'baluarte.owner_target_invalid';
  end if;

  if v_target.member_id = (select auth.uid()) then
    raise exception 'Você já é o Fundador deste Capítulo.'
      using errcode = '23514', hint = 'baluarte.already_owner';
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

commit;
