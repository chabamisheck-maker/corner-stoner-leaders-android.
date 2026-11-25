-- CORNER STONER LEADERS: Finance daily records
-- Run this in Supabase SQL Editor for project gyezqkekuvkhdqndrzcu.
-- Safe to re-run. Uses the existing public.is_admin() helper from the approval setup.

-- 1. Add a finance permission flag. Only the administrator can change it.
alter table public.profiles
  add column if not exists finance_access boolean not null default false;

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
    new.finance_access := old.finance_access;
  end if;
  return new;
end;
$$;

-- 2. Finance permissions: admin and explicitly appointed treasurer only.
create or replace function public.can_manage_finance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.approval_status = 'approved'
      and (p.role = 'admin' or p.finance_access = true)
  );
$$;

-- 3. Ledger table. Amounts are stored as exact decimal values, in ZMW.
create table if not exists public.finance_transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_date date not null default current_date,
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  category text not null default 'Other',
  description text,
  amount numeric(14,2) not null check (amount > 0),
  reference text,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists finance_transactions_date_idx
  on public.finance_transactions (transaction_date desc);
create index if not exists finance_transactions_type_idx
  on public.finance_transactions (transaction_type);

alter table public.finance_transactions enable row level security;
grant select, insert, update, delete on public.finance_transactions to authenticated;

-- 4. Every approved leader can read. Only admin/treasurer can write.
drop policy if exists "Approved leaders view finance records" on public.finance_transactions;
create policy "Approved leaders view finance records"
on public.finance_transactions for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.approval_status = 'approved'
  )
);

drop policy if exists "Finance managers add records" on public.finance_transactions;
create policy "Finance managers add records"
on public.finance_transactions for insert to authenticated
with check (
  (select public.can_manage_finance())
  and recorded_by = (select auth.uid())
);

drop policy if exists "Finance managers update records" on public.finance_transactions;
create policy "Finance managers update records"
on public.finance_transactions for update to authenticated
using ((select public.can_manage_finance()))
with check ((select public.can_manage_finance()));

drop policy if exists "Finance managers delete records" on public.finance_transactions;
create policy "Finance managers delete records"
on public.finance_transactions for delete to authenticated
using ((select public.can_manage_finance()));

-- 5. Keep updated_at current when a record is edited.
create or replace function public.set_finance_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists finance_transactions_updated_at on public.finance_transactions;
create trigger finance_transactions_updated_at
before update on public.finance_transactions
for each row execute function public.set_finance_updated_at();

-- Verify the new setup.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'finance_transactions'
order by ordinal_position;
