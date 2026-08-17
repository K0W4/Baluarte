-- Pacote 6 — a fila de Capítulos solicitados ganha resposta.
--
-- "Não encontrei meu Capítulo" grava em `chapter_request` e mostra uma confirmação,
-- mas não existia caminho nenhum para revisar. Quem pediu nunca recebia resposta --
-- o mesmo buraco que a recusa de entrada tinha, noutro fluxo.
--
-- Aprovar insere em `chapter`, que é registro somente leitura: `authenticated` não
-- tem grant de insert, então só uma função rodando como dona do schema pode escrever.
-- Isso é de propósito e continua valendo -- um Capítulo é conferido contra o registro
-- oficial da Ordem, nunca criado de dentro do app.
--
-- A chave real é (uf, number): a numeração é por jurisdição estadual, então um
-- número globalmente único seria errado. Aprovar um pedido cujo Capítulo já existe
-- tem de ser recusado em vez de duplicar o registro.

begin;

create or replace function public.review_chapter_request(
  p_request_id uuid,
  p_approved   boolean,
  p_reason     text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_request public.chapter_request;
  v_uf      char(2);
begin
  select * into v_request
    from public.chapter_request
   where id = p_request_id
     for update;

  if not found then
    raise exception 'Solicitação não encontrada.'
      using errcode = 'PT404', hint = 'baluarte.request_not_found';
  end if;

  -- Autorização antes de qualquer detalhe do alvo: dizer que o pedido já foi
  -- respondido antes de checar quem pergunta contaria isso a quem não deveria saber.
  if not public.is_platform_admin() then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Esta solicitação já foi respondida.'
      using errcode = '23514', hint = 'baluarte.request_already_reviewed';
  end if;

  if p_approved then
    v_uf := upper(v_request.uf);

    if exists (
      select 1 from public.chapter c
       where upper(c.uf) = v_uf and c.number = v_request.number
    ) then
      raise exception 'Já existe um Capítulo com este número neste estado.'
        using errcode = '23514', hint = 'baluarte.chapter_already_exists';
    end if;

    insert into public.chapter (name, number, uf, city, status, has_owner)
    values (trim(v_request.name), v_request.number, v_uf, nullif(trim(coalesce(v_request.city, '')), ''),
            'active', false);
  end if;

  update public.chapter_request
     set status      = case when p_approved then 'approved' else 'rejected' end,
         note        = case when p_approved then note
                            else nullif(trim(coalesce(p_reason, '')), '') end,
         reviewed_by = (select auth.uid()),
         reviewed_at = now()
   where id = p_request_id;

  -- Quem pediu fica sabendo. Sem isto o pacote não fecha o buraco que existe para
  -- resolver: a fila teria revisão, e o solicitante continuaria no escuro.
  insert into public.notification_outbox (member_id, kind, title_key, body_key)
  values (
    v_request.requested_by,
    case when p_approved then 'chapter_request_approved' else 'chapter_request_rejected' end,
    case when p_approved then 'baluarte.push_chapter_approved_title' else 'baluarte.push_chapter_rejected_title' end,
    case when p_approved then 'baluarte.push_chapter_approved_body'  else 'baluarte.push_chapter_rejected_body' end
  );
end $$;

revoke execute on function public.review_chapter_request(uuid, boolean, text) from public, anon;
grant  execute on function public.review_chapter_request(uuid, boolean, text) to authenticated;

-- ---------------------------------------------------------------------------
-- A fila, para quem revisa. Atravessa pessoas, então é função e não policy -- pela
-- mesma razão de platform_admins(): o que o revisor precisa é da lista de pedidos,
-- não de leitura da tabela de pessoas.
-- ---------------------------------------------------------------------------

create or replace function public.pending_chapter_requests()
returns table (
  id uuid, name text, number int, uf char(2), city text, note text,
  created_at timestamptz, requester_name text
)
language sql stable security definer set search_path = '' as $$
  select cr.id, cr.name, cr.number, cr.uf, cr.city, cr.note, cr.created_at,
         coalesce(m.full_name, 'Membro DeMolay')
    from public.chapter_request cr
    left join public.member m on m.id = cr.requested_by
   where cr.status = 'pending'
     and public.is_platform_admin()
   order by cr.created_at;
$$;

revoke execute on function public.pending_chapter_requests() from public, anon;
grant  execute on function public.pending_chapter_requests() to authenticated;

commit;
