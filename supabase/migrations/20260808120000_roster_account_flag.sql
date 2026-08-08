-- Expõe no roster se aquela pessoa já tem conta no app.
--
-- A regra de exclusão sempre esteve certa no banco (cm_delete_admin só apaga linhas
-- com member_id nulo), mas a interface não tinha como saber disso: o botão "Excluir
-- membro" aparecia para todo mundo e só falhava no servidor. Agora a projeção diz.
--
-- Um booleano em vez do member_id: a tela precisa saber "tem dono?", não quem é o dono,
-- e o id de autenticação não tem por que circular no roster.

begin;

create or replace view public.chapter_roster with (security_invoker = on) as
select
  cm.id,
  cm.chapter_id,
  cm.full_name,
  cm.role,
  (cm.category = 'ativo')  as is_active,
  (cm.category = 'senior') as is_senior,
  (cm.category = 'macom')  as is_mason,
  cm.access_level::text    as access_level,
  cm.birthdate,
  cm.cid,
  cm.created_at,
  -- No fim da lista de propósito: `create or replace view` só aceita acrescentar
  -- colunas ao final, e recriar a view exigiria derrubar tudo que depende dela.
  (cm.member_id is not null) as has_account
from public.chapter_membership cm
where cm.status = 'active';

grant select on public.chapter_roster to authenticated;

commit;
