-- Excluir a conta não pode levar junto o histórico do Capítulo.
--
-- Hoje a Edge Function apaga a linha de `member` e o `on delete cascade` leva o vínculo.
-- Só que `chapter_membership.id` é referenciado por `committee.member_ids`,
-- `committee.chairman_id`, `task.assignee_id`, `task.creator_id` e
-- `event.confirmed_attendees` -- e nenhuma dessas é chave estrangeira. Apagar o vínculo
-- transforma todas em referências órfãs silenciosas: presenças de reuniões passadas,
-- autoria de tarefas e composição de comissões passam a apontar para o nada.
--
-- A saída é separar as duas coisas que estavam grudadas. O histórico é do Capítulo e
-- fica; a identidade é da pessoa e sai. O vínculo vira um cadastro sem dono e anônimo,
-- que qualquer administrador pode remover se quiser -- mas por decisão, não por efeito
-- colateral de outra ação.

begin;

create or replace function public.anonymize_member_memberships()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.chapter_membership
     set member_id = null,
         full_name = 'Membro removido',
         cid       = null,
         birthdate = null,
         role      = null,
         -- Sem dono, o vínculo não pode carregar poder de administração.
         access_level = 'member'
   where member_id = old.id;

  return old;
end $$;

-- BEFORE DELETE: precisa rodar antes de o cascade da chave estrangeira levar as linhas.
drop trigger if exists member_anonymize_memberships on public.member;
create trigger member_anonymize_memberships
  before delete on public.member
  for each row execute function public.anonymize_member_memberships();

-- Solicitações pendentes da pessoa deixam de fazer sentido e carregam nome e CID.
create or replace function public.purge_member_requests()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  delete from public.join_request where member_id = old.id;
  delete from public.chapter_request where requested_by = old.id;
  return old;
end $$;

drop trigger if exists member_purge_requests on public.member;
create trigger member_purge_requests
  before delete on public.member
  for each row execute function public.purge_member_requests();

commit;
