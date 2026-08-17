-- Pacote 4 — acesso de plataforma e auto-rebaixamento.
--
-- Duas mudanças que parecem opostas e vêm juntas de propósito: uma abre um caminho
-- de concessão, a outra abre um caminho de renúncia. Nenhuma das duas permite
-- alguém subir sozinho.
--
-- ---------------------------------------------------------------------------
-- 1. Cadeia de confiança para o acesso de plataforma
--
-- Administrador de Capítulo é papel LOCAL. Administrador de plataforma aprova a
-- fundação de QUALQUER Capítulo. Se um Fundador pudesse se conceder o status, ele
-- aprovaria a própria fundação de qualquer Capítulo do país e tomaria posse dele --
-- por isso o pedido original (que admin ou Fundador concedesse) foi recusado.
--
-- O desenho é o padrão de cadeia de confiança: só quem já é administrador de
-- plataforma concede a outro. O primeiro veio por SQL, o que é inevitável -- alguém
-- tem que ser o primeiro.
--
-- A coluna `is_platform_admin` continua NUNCA concedida a `authenticated`. É isso, e
-- não a função abaixo, que impede auto-promoção por PATCH direto; a função existe
-- porque só ela pode escrever a coluna, rodando como dona do schema.
--
-- ---------------------------------------------------------------------------
-- 2. Auto-rebaixamento no Capítulo
--
-- `set_membership_access_level` recusa mudar o próprio nível. Isso estava certo
-- contra auto-promoção, mas prendia quem queria SAIR da administração: um Escrivão
-- que terminou a gestão não conseguia devolver o próprio acesso.
--
-- Vira: você pode se rebaixar, nunca se promover. A assimetria é a regra inteira.

begin;

-- ---------------------------------------------------------------------------

create or replace function public.set_platform_admin(
  p_member_id uuid,
  p_is_admin  boolean
)
returns void language plpgsql security definer set search_path = '' as $$
declare v_exists boolean;
begin
  if not public.is_platform_admin() then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  -- Sem isto, o último administrador de plataforma pode se remover e ninguém mais
  -- aprova fundação de Capítulo nenhuma -- o mesmo beco sem saída que leave_chapter
  -- evita para o Fundador, um nível acima.
  if p_member_id = (select auth.uid()) and p_is_admin = false then
    if (select count(*) from public.member m where m.is_platform_admin) <= 1 then
      raise exception 'Você é o único administrador de plataforma. Conceda a outra pessoa antes de sair.'
        using errcode = '23514', hint = 'baluarte.last_platform_admin';
    end if;
  end if;

  select true into v_exists from public.member m where m.id = p_member_id;
  if not found then
    raise exception 'Pessoa não encontrada.'
      using errcode = 'PT404', hint = 'baluarte.member_not_found';
  end if;

  update public.member
     set is_platform_admin = p_is_admin
   where id = p_member_id;
end $$;

revoke execute on function public.set_platform_admin(uuid, boolean) from public, anon;
grant  execute on function public.set_platform_admin(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Quem já é administrador de plataforma precisa enxergar os outros para poder
-- conceder e revogar. É a segunda leitura do app que atravessa Capítulos, e como a
-- primeira (pending_bootstrap_requests) vive numa função, não numa policy: abrir
-- `member` por policy daria a todo administrador de plataforma leitura irrestrita
-- da tabela de pessoas, e o que ele precisa é só a lista de pares.
-- ---------------------------------------------------------------------------

create or replace function public.platform_admins()
returns table (id uuid, full_name text, email text)
language sql stable security definer set search_path = '' as $$
  select m.id, m.full_name, u.email::text
    from public.member m
    join auth.users u on u.id = m.id
   where m.is_platform_admin
     and public.is_platform_admin()
   order by m.full_name;
$$;

revoke execute on function public.platform_admins() from public, anon;
grant  execute on function public.platform_admins() to authenticated;

-- ---------------------------------------------------------------------------
-- Auto-rebaixamento. Reproduz a versão vigente (20260809100000) mudando apenas a
-- regra do próprio nível: descer é permitido, subir não.
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

  if v_membership.member_id is null then
    raise exception 'Este cadastro ainda não pertence a ninguém, então não tem acesso para ajustar.'
      using errcode = '23514', hint = 'baluarte.membership_unclaimed';
  end if;

  if v_membership.member_id = (select auth.uid()) then
    -- Renunciar ao próprio acesso não precisa de permissão de ninguém, e a checagem
    -- de owner não pode vir antes: era ela que prendia o administrador comum, para
    -- quem esta regra existe. A assimetria é tudo: descer é renúncia, subir seria
    -- auto-promoção.
    if v_membership.access_level = 'owner' then
      raise exception 'Fundador se define pela transferência de propriedade.'
        using errcode = '23514', hint = 'baluarte.owner_needs_transfer';
    end if;

    if p_access_level >= v_membership.access_level then
      raise exception 'Você pode reduzir o próprio acesso, mas não aumentá-lo.'
        using errcode = '23514', hint = 'baluarte.cannot_raise_own_access';
    end if;
  else
    -- Autorização primeiro, sempre. Checar o nível do alvo antes contaria a um
    -- estranho que aquele vínculo é de um Fundador.
    if not public.is_owner_of(v_membership.chapter_id) then
      raise exception 'insufficient_privilege' using errcode = '42501';
    end if;

    if p_access_level = 'owner' or v_membership.access_level = 'owner' then
      raise exception 'Fundador se define pela transferência de propriedade.'
        using errcode = '23514', hint = 'baluarte.owner_needs_transfer';
    end if;
  end if;

  update public.chapter_membership
     set access_level = p_access_level
   where id = p_membership_id
  returning * into v_membership;

  return v_membership;
end $$;

commit;
