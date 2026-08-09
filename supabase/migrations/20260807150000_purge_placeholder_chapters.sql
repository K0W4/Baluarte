-- Remove the placeholder chapters manufactured by a bug in HomeViewModel.
--
-- Until now `loadData`'s catch block created a chapter literally named "Meu Capítulo"
-- nº 1 on any failure — a cancelled task, a network blip, an empty event list. Four of
-- them accumulated, all sharing number 1, which is what blocks the (uf, number) key the
-- registry needs. The Swift side that produced them has been deleted.
--
-- Deliberately surgical: a row is only removed when it matches that exact name AND has
-- nothing pointing at it. The chapter you actually joined has a membership, so it
-- survives. If two placeholders both carry data, this deletes neither and the registry
-- migration will name them again — that is a judgement call, not something to automate.

begin;

do $$
declare v_removed int;
begin
  with orphans as (
    delete from public.chapter c
     where c.name = 'Meu Capítulo'
       and not exists (select 1 from public.chapter_membership m where m.chapter_id = c.id)
       and not exists (select 1 from public.event            e where e.chapter_id = c.id)
       and not exists (select 1 from public.goal             g where g.chapter_id = c.id)
       and not exists (select 1 from public.committee        k where k.chapter_id = c.id)
       and not exists (select 1 from public.task             t where t.chapter_id = c.id)
       and not exists (select 1 from public.member           p where p.active_chapter_id = c.id)
    returning c.id
  )
  select count(*) into v_removed from orphans;

  raise notice 'Capítulos placeholder removidos: %', v_removed;
end $$;

commit;
