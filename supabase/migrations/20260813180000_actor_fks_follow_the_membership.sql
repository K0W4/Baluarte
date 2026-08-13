-- As três colunas que guardam o ator de um Capítulo apontavam para `member`, a pessoa,
-- e não para `chapter_membership`, o vínculo -- que é o que o app grava nelas.
--
-- Passou despercebido porque o backfill do pacote 1 preservou identidade: cada
-- `chapter_membership.id` herdou o `member.id` de quem já existia, então toda referência
-- antiga continuou resolvendo e a FK antiga continuou válida **por coincidência**. Um
-- vínculo criado depois -- por convite redimido, por solicitação aprovada -- recebe
-- `gen_random_uuid()`, e aí a coincidência acaba.
--
-- O efeito estava em produção e não em teoria: quem entrou no Capítulo depois da
-- migração não conseguia **criar tarefa** (`task.creator_id`, `task.assignee_id`) nem
-- ser feito **presidente de comissão** (`committee.chairman_id`). O 23503 não é mapeado
-- por `AppError`, então a tela mostrava "o servidor está temporariamente indisponível"
-- -- uma frase transitória para uma condição permanente. No Capítulo onde isso foi
-- encontrado, 2 dos 3 vínculos com conta já estavam do lado errado da linha.
--
-- As delete rules são preservadas exatamente; o que muda é para onde apontam. O CASCADE
-- de `task.creator_id` segue seguro depois da troca: `leave_chapter` desativa o vínculo
-- (`status = 'inactive'`) em vez de apagá-lo, e o único delete de vínculo que existe é o
-- de entrada sem conta (`cm_delete_admin`), que por definição nunca criou tarefa.

begin;

-- Abortar antes de tocar em constraint alguma se alguma linha não resolver. Um erro
-- aqui é dado inconsistente de verdade, e pede ser olhado, não contornado.
do $$
declare n bigint;
begin
  select count(*) into n
    from public.committee c
   where c.chairman_id is not null
     and not exists (select 1 from public.chapter_membership m where m.id = c.chairman_id);
  if n > 0 then
    raise exception 'committee.chairman_id tem % linha(s) sem vínculo correspondente', n;
  end if;

  select count(*) into n
    from public.task t
   where not exists (select 1 from public.chapter_membership m where m.id = t.creator_id);
  if n > 0 then
    raise exception 'task.creator_id tem % linha(s) sem vínculo correspondente', n;
  end if;

  select count(*) into n
    from public.task t
   where t.assignee_id is not null
     and not exists (select 1 from public.chapter_membership m where m.id = t.assignee_id);
  if n > 0 then
    raise exception 'task.assignee_id tem % linha(s) sem vínculo correspondente', n;
  end if;
end $$;

-- Derrubar pelo que a constraint **é**, e não pelo nome que se supõe que ela tenha: estas
-- FKs são anteriores às migrations versionadas, e um nome adivinhado errado deixaria a
-- antiga de pé ao lado da nova.
do $$
declare r record;
begin
  for r in
    select tc.table_name, tc.constraint_name
      from information_schema.table_constraints tc
      join information_schema.key_column_usage kcu
        on kcu.constraint_name = tc.constraint_name
       and kcu.table_schema    = tc.table_schema
      join information_schema.constraint_column_usage ccu
        on ccu.constraint_name = tc.constraint_name
     where tc.constraint_type = 'FOREIGN KEY'
       and tc.table_schema    = 'public'
       and ccu.table_name     = 'member'
       and (tc.table_name, kcu.column_name) in
           (('committee', 'chairman_id'), ('task', 'creator_id'), ('task', 'assignee_id'))
  loop
    execute format('alter table public.%I drop constraint %I', r.table_name, r.constraint_name);
  end loop;
end $$;

alter table public.committee
  add constraint committee_chairman_id_fkey
  foreign key (chairman_id) references public.chapter_membership(id) on delete set null;

alter table public.task
  add constraint task_creator_id_fkey
  foreign key (creator_id) references public.chapter_membership(id) on delete cascade;

alter table public.task
  add constraint task_assignee_id_fkey
  foreign key (assignee_id) references public.chapter_membership(id) on delete set null;

commit;
