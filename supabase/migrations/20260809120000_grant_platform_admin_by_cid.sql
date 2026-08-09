-- Conceder acesso de plataforma sem abrir uma busca de pessoas.
--
-- A tela precisa apontar para alguém. Fazer isso por lista exigiria mostrar todo
-- mundo do app a quem concede, e por busca exigiria um endpoint que devolve pessoas
-- por nome ou CID -- as duas coisas dão a um administrador de plataforma leitura da
-- tabela de pessoas, que é justamente o que `platform_admins()` evitou ao ser função
-- em vez de policy.
--
-- Então a resolução acontece aqui dentro: entra um CID, sai o acesso concedido, e
-- nada da tabela `member` atravessa a API. Quem concede já recebeu o CID de quem vai
-- receber o acesso -- essa troca fora do app é parte da cadeia de confiança, não uma
-- lacuna dela.
--
-- `cid` não tem restrição de unicidade, então o casamento ambíguo é recusado em vez
-- de escolher um. Conceder acesso de plataforma à pessoa errada não é um erro que se
-- descubra rápido.

begin;

create or replace function public.grant_platform_admin(p_cid text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_cid    text := nullif(trim(p_cid), '');
  v_target uuid;
  v_count  int;
begin
  if not public.is_platform_admin() then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_cid is null then
    raise exception 'Informe o CID de quem vai receber o acesso.'
      using errcode = '23514', hint = 'baluarte.cid_required';
  end if;

  select count(*), min(m.id) into v_count, v_target
    from public.member m
   where m.cid = v_cid;

  if v_count = 0 then
    raise exception 'Ninguém com este CID tem conta no app.'
      using errcode = 'PT404', hint = 'baluarte.cid_not_found';
  end if;

  if v_count > 1 then
    raise exception 'Há mais de uma conta com este CID. Resolva a duplicidade antes de conceder.'
      using errcode = '23514', hint = 'baluarte.cid_ambiguous';
  end if;

  update public.member
     set is_platform_admin = true
   where id = v_target;
end $$;

revoke execute on function public.grant_platform_admin(text) from public, anon;
grant  execute on function public.grant_platform_admin(text) to authenticated;

commit;
