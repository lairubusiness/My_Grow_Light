-- ============================================================
--  MyGrowLight – full database schema
--  Personal finance: profiles, transactions, savings, members
-- ============================================================
-- Run with:  supabase db push      (after `supabase link`)
-- Or paste into the Supabase SQL editor.
-- ============================================================

-- ---------- extensions ----------
create extension if not exists "pgcrypto";

-- ============================================================
--  PROFILES  (1:1 with auth.users)
-- ============================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  fname       text not null default '',
  lname       text not null default '',
  email       text,
  phone       text,
  nic         text,
  dob         date,
  created_at  timestamptz not null default now()
);

-- ============================================================
--  MEMBERS  (team members who save together)
-- ============================================================
create table if not exists public.members (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fname       text not null,
  lname       text,
  nic         text,
  phone       text,
  dob         date,
  role        text,
  created_at  timestamptz not null default now()
);
create index if not exists members_user_id_idx on public.members (user_id);

-- ============================================================
--  TRANSACTIONS  (income / expense)
-- ============================================================
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  type        text not null check (type in ('income','expense')),
  title       text not null,
  amount      numeric(14,2) not null check (amount > 0),
  date        date not null,
  category    text,
  note        text,
  created_at  timestamptz not null default now()
);
create index if not exists transactions_user_id_idx on public.transactions (user_id);
create index if not exists transactions_date_idx    on public.transactions (user_id, date);

-- ============================================================
--  SAVINGS BOXES  (digital piggy banks)
-- ============================================================
create table if not exists public.savings_boxes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  name        text not null,
  target      numeric(14,2) not null default 0,
  start_date  date,
  member_id   uuid references public.members (id) on delete set null,
  description text,
  balance     numeric(14,2) not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists savings_boxes_user_id_idx on public.savings_boxes (user_id);

-- ============================================================
--  SAVINGS LOG  (deposit / withdraw history)
-- ============================================================
create table if not exists public.savings_log (
  id          uuid primary key default gen_random_uuid(),
  box_id      uuid not null references public.savings_boxes (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  type        text not null check (type in ('deposit','withdraw')),
  amount      numeric(14,2) not null check (amount > 0),
  date        date not null,
  note        text,
  created_at  timestamptz not null default now()
);
create index if not exists savings_log_box_id_idx  on public.savings_log (box_id);
create index if not exists savings_log_user_id_idx on public.savings_log (user_id);

-- ============================================================
--  TRIGGER: keep savings_boxes.balance in sync with the log
-- ============================================================
create or replace function public.apply_savings_log()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  delta numeric(14,2);
begin
  if (tg_op = 'INSERT') then
    delta := case when new.type = 'deposit' then new.amount else -new.amount end;
    update public.savings_boxes set balance = balance + delta where id = new.box_id;
    return new;
  elsif (tg_op = 'DELETE') then
    delta := case when old.type = 'deposit' then old.amount else -old.amount end;
    update public.savings_boxes set balance = balance - delta where id = old.box_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_savings_log on public.savings_log;
create trigger trg_savings_log
  after insert or delete on public.savings_log
  for each row execute function public.apply_savings_log();

-- ============================================================
--  TRIGGER: auto-create a profile row on signup
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, fname, lname)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'fname', ''),
    coalesce(new.raw_user_meta_data ->> 'lname', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
--  ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles      enable row level security;
alter table public.members        enable row level security;
alter table public.transactions   enable row level security;
alter table public.savings_boxes  enable row level security;
alter table public.savings_log    enable row level security;

-- profiles: a user can see/edit only their own profile
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- generic owner policies for the user-owned tables
create policy "members_all_own" on public.members
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "transactions_all_own" on public.transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "savings_boxes_all_own" on public.savings_boxes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "savings_log_all_own" on public.savings_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
