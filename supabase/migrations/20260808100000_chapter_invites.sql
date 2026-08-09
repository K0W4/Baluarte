-- Phase 3 — Invite codes.
--
-- The approval queue works but does not scale to onboarding a whole chapter: fifty
-- people asking one by one is fifty decisions. An admin generates a code, pastes it in
-- the chapter's WhatsApp group, and whoever opens it is already in.
--
-- The entire security model rests on the code being unguessable, so two things are not
-- optional: codes are never enumerable through the API, and redemption is rate limited.
-- 30^8 is a large space, but without a limit on attempts a code is a door left unlocked.

begin;

-- Crockford-ish alphabet: no I, L, O, U, 0 or 1. Nobody dictates those correctly over
-- the phone, and the code has to survive being read aloud in a meeting.
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
      raise exception 'Não foi possível gerar um código único.' using errcode = '23514';
    end if;
  end loop;

  return v_code;
end $$;

create table if not exists public.chapter_invite (
  id         uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapter(id) on delete cascade,
  code       text not null unique,
  -- Claiming a roster entry an admin created before this person had an account,
  -- instead of producing a duplicate "João Silva" in the members list.
  target_membership_id uuid references public.chapter_membership(id) on delete set null,
  expires_at timestamptz,
  max_uses   int check (max_uses is null or max_uses > 0),
  uses_count int not null default 0,
  revoked_at timestamptz,
  created_by uuid not null references public.member(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- The default is what keeps the code server-generated: `code` is never granted to
-- authenticated, so a client cannot choose its own.
alter table public.chapter_invite
  alter column code set default public.generate_invite_code();

create index if not exists chapter_invite_chapter_idx
  on public.chapter_invite (chapter_id, created_at desc);

create table if not exists public.invite_attempt (
  id           bigserial primary key,
  member_id    uuid not null,
  code         text not null,
  succeeded    boolean not null,
  attempted_at timestamptz not null default now()
);

create index if not exists invite_attempt_recent_idx
  on public.invite_attempt (member_id, attempted_at desc);

-- ---------------------------------------------------------------------------
-- RLS
--
-- There is deliberately no policy for people outside the chapter. Not "a policy that
-- returns nothing" — no policy at all, so a code can never be discovered by listing.
-- ---------------------------------------------------------------------------

alter table public.chapter_invite enable row level security;

create policy ci_admin_select on public.chapter_invite for select to authenticated
  using (public.is_admin_of(chapter_id));

create policy ci_admin_insert on public.chapter_invite for insert to authenticated
  with check (public.is_admin_of(chapter_id) and created_by = (select auth.uid()));

create policy ci_admin_update on public.chapter_invite for update to authenticated
  using (public.is_admin_of(chapter_id)) with check (public.is_admin_of(chapter_id));

create policy ci_admin_delete on public.chapter_invite for delete to authenticated
  using (public.is_admin_of(chapter_id));

revoke all on public.chapter_invite from anon, authenticated;
grant select on public.chapter_invite to authenticated;
grant insert (chapter_id, created_by, target_membership_id, expires_at, max_uses)
  on public.chapter_invite to authenticated;
grant update (revoked_at, expires_at, max_uses) on public.chapter_invite to authenticated;
grant delete on public.chapter_invite to authenticated;

-- No policies at all: only the security definer function below reads or writes this.
alter table public.invite_attempt enable row level security;
revoke all on public.invite_attempt from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Redemption
--
-- Needs to be an RPC for two independent reasons: the caller cannot SELECT an invite
-- for a chapter they are not in (that is the whole point), and cannot INSERT their own
-- membership. Both gaps are crossed here, under a lock, with the attempt recorded.
--
-- Invites always grant `member`. A code travelling through a WhatsApp group must never
-- be able to hand out administration — promoting someone stays a deliberate, named act.
-- ---------------------------------------------------------------------------

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
    raise exception 'Informe o código do convite.' using errcode = '23514';
  end if;

  -- Serialises this caller's attempts so the rate limit cannot be outrun in parallel.
  perform pg_advisory_xact_lock(hashtextextended('invite:' || v_me::text, 0));

  select count(*) into v_failures
    from public.invite_attempt ia
   where ia.member_id = v_me
     and ia.succeeded = false
     and ia.attempted_at > now() - interval '15 minutes';

  if v_failures >= 10 then
    raise exception 'Muitas tentativas. Aguarde alguns minutos antes de tentar de novo.'
      using errcode = '23514';
  end if;

  select * into v_invite from public.chapter_invite ci where ci.code = v_code for update;

  if not found
     or v_invite.revoked_at is not null
     or (v_invite.expires_at is not null and v_invite.expires_at < now())
     or (v_invite.max_uses is not null and v_invite.uses_count >= v_invite.max_uses) then
    insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
    -- One message for every failure mode on purpose: distinguishing "expired" from
    -- "does not exist" tells an attacker which codes are real.
    raise exception 'Convite inválido ou expirado. Confira o código com quem enviou.'
      using errcode = '23514';
  end if;

  if public.is_member_of(v_invite.chapter_id) then
    insert into public.invite_attempt (member_id, code, succeeded) values (v_me, v_code, false);
    raise exception 'Você já participa deste Capítulo.' using errcode = '23514';
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
        using errcode = '23514';
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

revoke execute on function public.redeem_chapter_invite(text) from public, anon;
grant  execute on function public.redeem_chapter_invite(text) to authenticated;

revoke execute on function public.generate_invite_code() from public, anon, authenticated;

commit;
