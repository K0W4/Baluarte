-- Autorização antes de olhar o pedido.
--
-- A versão anterior consultava a linha e levantava PT404 antes de checar quem estava
-- perguntando. Com isso, alguém de fora da plataforma descobria quais ids existem:
-- id inexistente respondia "não encontrado", id real respondia "sem permissão".
--
-- É exatamente a mesma falha corrigida em set_membership_access_level, reintroduzida
-- aqui. A sonda "id inexistente não revela nada a quem não revisa" foi escrita
-- esperando 42501 e pegou -- foi a primeira vez que o CI barrou um vazamento antes
-- de ele chegar ao dev.
--
-- A regra, então: quem pergunta é verificado antes de qualquer coisa que dependa do
-- alvo, inclusive da existência dele.

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
  if not public.is_platform_admin() then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  select * into v_request
    from public.chapter_request
   where id = p_request_id
     for update;

  if not found then
    raise exception 'Solicitação não encontrada.'
      using errcode = 'PT404', hint = 'baluarte.request_not_found';
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
    values (trim(v_request.name), v_request.number, v_uf,
            nullif(trim(coalesce(v_request.city, '')), ''), 'active', false);
  end if;

  update public.chapter_request
     set status      = case when p_approved then 'approved' else 'rejected' end,
         note        = case when p_approved then note
                            else nullif(trim(coalesce(p_reason, '')), '') end,
         reviewed_by = (select auth.uid()),
         reviewed_at = now()
   where id = p_request_id;

  insert into public.notification_outbox (member_id, kind, title_key, body_key)
  values (
    v_request.requested_by,
    case when p_approved then 'chapter_request_approved' else 'chapter_request_rejected' end,
    case when p_approved then 'baluarte.push_chapter_approved_title' else 'baluarte.push_chapter_rejected_title' end,
    case when p_approved then 'baluarte.push_chapter_approved_body'  else 'baluarte.push_chapter_rejected_body' end
  );
end $$;

commit;
