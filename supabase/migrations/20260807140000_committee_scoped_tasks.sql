-- Scope tasks to the committees a person actually belongs to.
--
-- Until now any chapter member could read and write every task in the chapter, and
-- the app only narrowed it visually. This moves the rule into the database:
--
--   * a committee task is visible and completable only to that committee's members
--     (its chairman counts) and to chapter admins;
--   * a task with no committee is personal — only its creator, its assignee and
--     admins can see it;
--   * you can only create a task for a committee you belong to, and you cannot
--     create one in someone else's name.

begin;

-- The caller's membership in a given chapter. Chapter-scoped references (assignee,
-- creator, attendance) all point at this id, never at auth.uid().
create or replace function public.my_membership_id(p_chapter_id uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select cm.id
    from public.chapter_membership cm
   where cm.chapter_id = p_chapter_id
     and cm.member_id  = (select auth.uid())
     and cm.status     = 'active'
   limit 1;
$$;

create or replace function public.is_in_committee(p_committee_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.committee c
    join public.chapter_membership cm
      on cm.chapter_id = c.chapter_id
     and cm.member_id  = (select auth.uid())
     and cm.status     = 'active'
    where c.id = p_committee_id
      and (cm.id = any(coalesce(c.member_ids, '{}'::uuid[])) or cm.id = c.chairman_id)
  );
$$;

revoke execute on function public.my_membership_id(uuid), public.is_in_committee(uuid)
  from public, anon;
grant execute on function public.my_membership_id(uuid), public.is_in_committee(uuid)
  to authenticated;

drop policy if exists task_select on public.task;
drop policy if exists task_write_member on public.task;

create policy task_select on public.task for select to authenticated
using (
  public.is_admin_of(chapter_id)
  or (committee_id is not null and public.is_in_committee(committee_id))
  or (committee_id is null and (
        creator_id  = public.my_membership_id(chapter_id)
     or assignee_id = public.my_membership_id(chapter_id)))
);

create policy task_insert on public.task for insert to authenticated
with check (
  public.is_member_of(chapter_id)
  -- you always author your own tasks
  and creator_id = public.my_membership_id(chapter_id)
  and (
    committee_id is null
    or public.is_admin_of(chapter_id)
    or public.is_in_committee(committee_id)
  )
);

create policy task_update on public.task for update to authenticated
using (
  public.is_admin_of(chapter_id)
  or (committee_id is not null and public.is_in_committee(committee_id))
  or (committee_id is null and (
        creator_id  = public.my_membership_id(chapter_id)
     or assignee_id = public.my_membership_id(chapter_id)))
)
with check (
  public.is_admin_of(chapter_id)
  or (committee_id is not null and public.is_in_committee(committee_id))
  or (committee_id is null and (
        creator_id  = public.my_membership_id(chapter_id)
     or assignee_id = public.my_membership_id(chapter_id)))
);

create policy task_delete on public.task for delete to authenticated
using (
  public.is_admin_of(chapter_id)
  or (committee_id is not null and public.is_in_committee(committee_id))
  or (committee_id is null and creator_id = public.my_membership_id(chapter_id))
);

commit;
