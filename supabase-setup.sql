-- =====================================================
-- 写作打卡 - Supabase 初始化脚本
-- 使用方法：Supabase 控制台 -> SQL Editor -> New query，
-- 整段粘贴运行一次即可。管理员设置见文件末尾。
-- =====================================================

-- 1) 用户资料表（role: user/admin；banned: 是否被停用）
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique not null,
  role text not null default 'user' check (role in ('user','admin')),
  banned boolean not null default false,
  created_at timestamptz not null default now()
);

-- 2) 打卡记录表（每个账号独立）
create table if not exists public.records (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  date text not null,                     -- 格式：YYYY-MM-DD
  words integer not null default 0 check (words >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, date)
);
create index if not exists records_user_date_idx on public.records (user_id, date);

-- 3) 注册时自动创建 profile
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role, banned)
  values (new.id, new.email, 'user', false)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4) 辅助函数
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and not banned
  );
$$;

create or replace function public.banned_user()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select banned from public.profiles where id = auth.uid()), false);
$$;

-- 5) 开启行级安全（RLS）
alter table public.profiles enable row level security;
alter table public.records enable row level security;

-- profiles 策略
drop policy if exists "profiles own select" on public.profiles;
create policy "profiles own select" on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles admin select" on public.profiles;
create policy "profiles admin select" on public.profiles for select
  using (is_admin());

drop policy if exists "profiles admin update" on public.profiles;
create policy "profiles admin update" on public.profiles for update
  using (is_admin()) with check (is_admin());

-- records 策略（普通用户只能读写自己的；被停用后全部拒绝）
drop policy if exists "records own select" on public.records;
create policy "records own select" on public.records for select
  using (user_id = auth.uid() and not banned_user());

drop policy if exists "records own insert" on public.records;
create policy "records own insert" on public.records for insert
  with check (user_id = auth.uid() and not banned_user() and words >= 0);

drop policy if exists "records own update" on public.records;
create policy "records own update" on public.records for update
  using (user_id = auth.uid() and not banned_user())
  with check (user_id = auth.uid() and not banned_user() and words >= 0);

drop policy if exists "records own delete" on public.records;
create policy "records own delete" on public.records for delete
  using (user_id = auth.uid() and not banned_user());

drop policy if exists "records admin select" on public.records;
create policy "records admin select" on public.records for select
  using (is_admin());

-- =====================================================
-- 管理员设置：注册好管理员账号后，把邮箱换成你的，再运行一次：
-- update public.profiles set role = 'admin' where email = '你的管理员邮箱@example.com';
-- =====================================================