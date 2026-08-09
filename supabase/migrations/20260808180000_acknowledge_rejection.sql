-- Permite que a pessoa marque como vista a recusa da própria solicitação.
--
-- A policy anterior só deixava mexer em solicitação `pending`, então dar ciência de uma
-- recusa era bloqueado -- e sem isso a tela de recusa reapareceria para sempre.
-- Continua sendo só o dono da linha, e só para o valor 'cancelled': aprovar ou recusar
-- segue exclusivo das RPCs.

begin;

drop policy if exists jr_cancel_own on public.join_request;

create policy jr_cancel_own on public.join_request for update to authenticated
  using (
    member_id = (select auth.uid())
    and status in ('pending', 'rejected')
  )
  with check (status = 'cancelled');

commit;
