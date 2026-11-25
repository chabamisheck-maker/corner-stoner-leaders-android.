-- CORNER STONER LEADERS: approval workflow and final access policies
-- Run this in Supabase SQL Editor for project gyezqkekuvkhdqndrzcu.
-- Safe to re-run.

-- 1) Add approval status. New registrations remain pending by default.
alter table public.profiles
  add column if not exists approval_status text not null default 'pending'
  check (approval_status in ('pending', 'approved', 'rejected'));

-- 2) Keep role and approval status under administrator control.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    new.role := old.role;
    new.approval_status := old.approval_status;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
before update on public.profiles
for each row execute function public.protect_profile_role();

-- 3) Helpers used by row-level security.
create or replace function public.is_approved()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and approval_status = 'approved'
  );
$$;

-- 4) Make sure the existing administrator profile is approved.
-- This also repairs the profile if it was not created by the signup trigger.
insert into public.profiles (id, display_name, role, approval_status)
select u.id, 'Misheck', 'admin', 'approved'
from auth.users u
where lower(u.email) = lower('chabamisheck@gmail.com')
on conflict (id) do update
set role = 'admin',
    approval_status = 'approved';

-- 5) Ensure all existing auth users have a profile (new users get one via trigger).
insert into public.profiles (id, display_name, role, approval_status)
select
  u.id,
  coalesce(nullif(u.raw_user_meta_data ->> 'display_name', ''), 'New Leader'),
  'leader',
  'pending'
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
);

-- 6) Rebuild profile policies.
drop policy if exists "View own profile or admin" on public.profiles;
drop policy if exists "Update own profile or admin" on public.profiles;

create policy "View own profile or admin"
on public.profiles for select
to authenticated
using (id = (select auth.uid()) or (select public.is_admin()));

create policy "Update own profile or admin"
on public.profiles for update
to authenticated
using (id = (select auth.uid()) or (select public.is_admin()))
with check (id = (select auth.uid()) or (select public.is_admin()));

-- 7) Songs: approved leaders/admins can read; owners/admins manage.
drop policy if exists "Leaders view songs" on public.songs;
drop policy if exists "Leaders add songs" on public.songs;
drop policy if exists "Owners or admins update songs" on public.songs;
drop policy if exists "Owners or admins delete songs" on public.songs;

create policy "Approved users view songs"
on public.songs for select to authenticated
using ((select public.is_approved()) or (select public.is_admin()));

create policy "Approved users add songs"
on public.songs for insert to authenticated
with check (
  (select public.is_approved())
  and created_by = (select auth.uid())
);

create policy "Owners or admins update songs"
on public.songs for update to authenticated
using (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
)
with check (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

create policy "Owners or admins delete songs"
on public.songs for delete to authenticated
using (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

-- 8) Attendance: approved users can view/record; only recorder/admin edits/deletes.
drop policy if exists "Leaders view attendance" on public.attendance;
drop policy if exists "Leaders record attendance" on public.attendance;
drop policy if exists "Leaders update attendance" on public.attendance;
drop policy if exists "Leaders delete attendance" on public.attendance;

create policy "Approved users view attendance"
on public.attendance for select to authenticated
using ((select public.is_approved()) or (select public.is_admin()));

create policy "Approved users record attendance"
on public.attendance for insert to authenticated
with check (
  ((select public.is_approved()) or (select public.is_admin()))
  and recorded_by = (select auth.uid())
);

create policy "Recorders or admins update attendance"
on public.attendance for update to authenticated
using (
  (recorded_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
)
with check (
  (recorded_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

create policy "Recorders or admins delete attendance"
on public.attendance for delete to authenticated
using (
  (recorded_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

-- 9) Activities: approved users can view/add; creator/admin edits/deletes.
drop policy if exists "Leaders view activities" on public.activities;
drop policy if exists "Leaders add activities" on public.activities;
drop policy if exists "Leaders update activities" on public.activities;
drop policy if exists "Leaders delete activities" on public.activities;

create policy "Approved users view activities"
on public.activities for select to authenticated
using ((select public.is_approved()) or (select public.is_admin()));

create policy "Approved users add activities"
on public.activities for insert to authenticated
with check (
  ((select public.is_approved()) or (select public.is_admin()))
  and created_by = (select auth.uid())
);

create policy "Creators or admins update activities"
on public.activities for update to authenticated
using (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
)
with check (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

create policy "Creators or admins delete activities"
on public.activities for delete to authenticated
using (
  (created_by = (select auth.uid()) and (select public.is_approved()))
  or (select public.is_admin())
);

-- 10) Helpful indexes.
create index if not exists profiles_approval_status_idx
  on public.profiles (approval_status);
create index if not exists attendance_date_idx
  on public.attendance (attendance_date);
create index if not exists activities_date_idx
  on public.activities (activity_date);
create index if not exists songs_title_idx
  on public.songs (title);

-- Verify administrator.
select id, display_name, role, approval_status
from public.profiles
where lower(id::text) in (
  select id::text from auth.users
  where lower(email) = lower('chabamisheck@gmail.com')
);