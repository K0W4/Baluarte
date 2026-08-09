-- Pacote 9 — endurecer o convite.
--
-- O limite de tentativas conta falhas por CONTA. O alvo de um ataque, porém, é
-- sempre um CÓDIGO: quem quer entrar num Capítulo específico cria contas até acertar
-- oito caracteres, e cada conta nova zera o contador. O limite por conta protege o
-- projeto de uma pessoa insistente, não de alguém determinado.
--
-- Some-se um limite por código. Ele é o que de fato defende o modelo, porque o
-- modelo inteiro repousa em o código ser inadivinhável: 30^8 combinações só valem
-- alguma coisa enquanto ninguém puder tentar à vontade.
--
-- E `invite_attempt` cresce para sempre. Uma tabela de log sem expurgo é uma tabela
-- que um dia deixa a RPC lenta -- e esta RPC roda com advisory lock, então lentidão
-- ali serializa todo mundo que está tentando entrar.

begin;

-- Casa o contador por código: (code, attempted_at) com a coluna de tempo descendente
-- é o que a janela de 15 minutos varre.
create index if not exists invite_attempt_by_code_idx
  on public.invite_attempt (code, attempted_at desc)
  where succeeded = false;

-- ---------------------------------------------------------------------------
-- Expurgo. Trinta dias é folgado para uma janela de quinze minutos; o resto é
-- histórico que ninguém lê.
-- ---------------------------------------------------------------------------

create or replace function public.purge_invite_attempts()
returns integer language plpgsql security definer set search_path = '' as $$
declare v_removed integer;
begin
  delete from public.invite_attempt
   where attempted_at < now() - interval '30 days';
  get diagnostics v_removed = row_count;
  return v_removed;
end $$;

revoke execute on function public.purge_invite_attempts() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Resgate, com os dois limites. Reproduz a versão vigente (20260808190000) e muda
-- só o bloco de rate limit.
-- ---------------------------------------------------------------------------

create or replace function public.redeem_chapter_invite(p_code text)
returns public.chapter_membership language plpgsql security definer set search_path = '' as $$
declare
  v_me            uuid := (select auth.uid());
  v_code          text;
  v_invite        public.chapter_invite;
  v_by_member     int;
  v_by_code       int;
  v_membership    public.chapter_membership;
  v_full_name     text;
begin
  if v_me is null then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  v_code := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));

  if length(v_code) = 0 then
    raise exception 'Informe o código do convite.'
      using errcode = '23514', hint = 'baluarte.invite_code_required';
  end if;

  -- Serializa as tentativas desta pessoa para o limite não ser burlado em paralelo.
  perform pg_advisory_xact_lock(hashtextextended('invite:' || v_me::text, 0));
  -- E as tentativas contra este código, pelo mesmo motivo -- é o limite que importa,
  -- e sem lock várias contas simultâneas passariam juntas pela contagem.
  perform pg_advisory_xact_lock(hashtextextended('invite-code:' || v_code, 0));

  select count(*) into v_by_member
    from public.invite_attempt ia
   where ia.member_id = v_me
     and ia.succeeded = false
     and ia.attempted_at > now() - interval '15 minutes';

  if v_by_member >= 10 then
    raise exception 'Muitas tentativas. Aguarde alguns minutos antes de tentar de novo.'
      using errcode = '23514', hint = 'baluarte.invite_rate_limited';
  end if;

  -- O limite por código é mais apertado de propósito: dez erros da mesma pessoa é
  -- alguém digitando mal; vinte erros contra o mesmo código, de contas quaisquer, é
  -- alguém tentando adivinhar.
  select count(*) into v_by_code
    from public.invite_attempt ia
   where ia.code = v_code
     and ia.succeeded = false
     and ia.attempted_at > now() - interval '15 minutes';

  if v_by_code >= 20 then
    -- Mesma mensagem do outro limite, de propósito: distinguir "você errou demais"
    -- de "este código foi tentado demais" confirma a um atacante que o código existe.
    raise exception 'Muitas tentativas. Aguarde alguns minutos antes de tentar de novo.'
      using errcode = '23514', hint = 'baluarte.invite_rate_limited';
  end if;

  select * into v_invite from public.chapter_invite ci where ci.code = v_code for update;

  if not found
     or v_invite.revoked_at is not null
     or (v_invite.expires_at is not null and v_invite.expires_at < now())
     or (v_invite.max_uses is not null and v_invite.uses_count >= v_invite.max_uses) then
    insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
    -- Uma mensagem só para todos os modos de falha, de propósito: distinguir
    -- "expirado" de "não existe" conta a um atacante quais códigos são reais.
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

commit;
