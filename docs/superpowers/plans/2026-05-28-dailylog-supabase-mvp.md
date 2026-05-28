# DailyLog Supabase MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Supabase 项目 `yvpnuagkykpbhlljexnt` 的数据库整改为 DailyLog iOS MVP 的正式 schema，落地 RLS、`complete_task` RPC 和 `handle_new_user` 触发器，预置两个可登录的 iOS MVP 账号，并通过 SQL 端到端验证完成任务的金币写入链路。

**Architecture:** 在现有 5 个 migration 基础上做正向规范化迁移（不回滚旧迁移），每条迁移都先落 `supabase/migrations/<timestamp>_<name>.sql` 本地源码文件，再通过 `mcp__supabase__apply_migration` 应用到远端。原子化操作 `complete_task` 通过 `SECURITY DEFINER` PL/pgSQL 函数实现，确保金币、统计、流水、动态四张表的写入在一个事务里完成。RLS 策略遵守 spec：用户只能读写自己的资源，金币和动态的写入只走 RPC。

**Tech Stack:** Supabase Postgres 15、PL/pgSQL、Row Level Security、`mcp__supabase__apply_migration` + `mcp__supabase__execute_sql` + `mcp__supabase__get_advisors`、Supabase Dashboard（仅用于创建预置 auth 账号）。

**约定：**
- 远端项目 ID `yvpnuagkykpbhlljexnt`，所有 MCP 调用都填这个值。
- 本地 migration 文件命名 `supabase/migrations/<YYYYMMDDHHMMSS>_<snake_name>.sql`，时间戳按顺序自增即可（远端记录的 version 由 Supabase 自动生成，本地与远端的 version 字符串不必一致，只要 name 一致就行）。
- 所有 SQL 中文注释只放在 migration 文件顶部说明意图，DDL 主体不加注释。
- 现有 5 张表当前行数都是 0 行（已确认），可以直接 ALTER 不需要数据迁移脚本。
- 执行前请确认 `supabase/migrations/` 目录尚不存在；如果已存在请先暂停并向用户确认。

---

### Task 1: 探查并固定基线

**目的：** 在动手改之前，把现状写到本地一个临时探查文档里，以便回滚和对照。不修改数据库。

**Files:**
- Create: `supabase/migrations/` (空目录)
- Create: `supabase/_baseline.md` (基线快照，纯文档)

- [ ] **Step 1: 创建本地目录结构**

```bash
mkdir -p supabase/migrations
```

- [ ] **Step 2: 查询 5 张表的列定义、约束、行数，写入基线文档**

Run via `mcp__supabase__execute_sql`:

```sql
select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema='public'
order by table_name, ordinal_position;
```

再跑：

```sql
select tablename, policyname, cmd, qual, with_check
from pg_policies where schemaname='public'
order by tablename, policyname;
```

再跑：

```sql
select 'users' as t, count(*) from public.users
union all select 'tasks', count(*) from public.tasks
union all select 'feed_messages', count(*) from public.feed_messages
union all select 'rewards', count(*) from public.rewards
union all select 'redemption_history', count(*) from public.redemption_history;
```

Expected：5 张表里 `rewards=21`，其它都是 `0`。如果任何不为 0，停止并通知用户——基线已有数据，迁移策略需要调整。

- [ ] **Step 3: 将查询结果写入 `supabase/_baseline.md`**

把上面 3 段 SQL 和结果摘要写入文件，结构：

```markdown
# Baseline 2026-05-28

## Columns
... (粘贴查询 1 的结果)

## Policies
... (粘贴查询 2 的结果)

## Row counts
... (粘贴查询 3 的结果)
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations supabase/_baseline.md
git commit -m "chore(supabase): record schema baseline before MVP migrations"
```

---

### Task 2: 规范 users 表（去 openid，绑定 auth.users.id）

**目的：** 删除小程序时代的 `openid` 列，把 `users.id` 改成引用 `auth.users(id) on delete cascade`，让客户端登录后用 `auth.uid()` 直接关联 profile。`nickname` 改为 NOT NULL，新增 `coins >= 0` check，补 `updated_at`。

**Files:**
- Create: `supabase/migrations/20260528010000_normalize_users.sql`

- [ ] **Step 1: 写一条预期失败的验证 SQL（确认当前 schema 还是旧的）**

通过 `mcp__supabase__execute_sql` 跑：

```sql
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='users' and column_name='openid') as has_openid,
  (select is_nullable from information_schema.columns
     where table_schema='public' and table_name='users' and column_name='nickname') as nickname_nullable,
  (select count(*) from information_schema.table_constraints
     where table_schema='public' and table_name='users' and constraint_name='users_id_fkey') as id_fk_count;
```

Expected (迁移前)：`has_openid=1`, `nickname_nullable='YES'`, `id_fk_count=0`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010000_normalize_users.sql`:

```sql
-- normalize_users: 去除 openid，绑定 auth.users.id，加 NOT NULL 和 check
begin;

alter table public.users drop column if exists openid;

alter table public.users alter column id drop default;
alter table public.users alter column nickname set not null;
alter table public.users alter column coins set not null;
alter table public.users alter column coins set default 0;
alter table public.users alter column total_completed set not null;
alter table public.users alter column total_completed set default 0;
alter table public.users alter column push_enabled set not null;
alter table public.users alter column push_enabled set default false;
alter table public.users alter column created_at set not null;
alter table public.users alter column updated_at set not null;

alter table public.users
  drop constraint if exists users_coins_check;
alter table public.users
  add constraint users_coins_check check (coins >= 0);

alter table public.users
  drop constraint if exists users_id_fkey;
alter table public.users
  add constraint users_id_fkey
  foreign key (id) references auth.users(id) on delete cascade;

commit;
```

- [ ] **Step 3: 应用 migration**

Call `mcp__supabase__apply_migration` with:

```json
{
  "project_id": "yvpnuagkykpbhlljexnt",
  "name": "normalize_users",
  "query": "<paste the exact SQL body without the leading comment>"
}
```

Expected: migration 成功返回，无错误。

- [ ] **Step 4: 验证 schema 已变更**

跑 Step 1 的同一段 SQL。Expected (迁移后)：`has_openid=0`, `nickname_nullable='NO'`, `id_fk_count=1`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010000_normalize_users.sql
git commit -m "feat(supabase): normalize users table, drop openid, bind to auth.users"
```

---

### Task 3: 规范 tasks 表

**目的：** 去掉旧的 `order_in_day >=1 and <=5` 范围限制，让客户端可以自由排序；补齐 NOT NULL、default 和 `updated_at` 字段及更新触发器；加索引加速 Today 列表查询。

**Files:**
- Create: `supabase/migrations/20260528010100_normalize_tasks.sql`

- [ ] **Step 1: 验证当前 tasks 还是旧 schema**

```sql
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='tasks' and column_name='updated_at') as has_updated_at,
  (select check_clause from information_schema.check_constraints
     where constraint_schema='public' and constraint_name like 'tasks_order_in_day%' limit 1) as order_check;
```

Expected (迁移前)：`has_updated_at=0`，`order_check` 包含 `>= 1`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010100_normalize_tasks.sql`:

```sql
-- normalize_tasks: 去 order_in_day 范围限制，补 updated_at，加触发器和索引
begin;

alter table public.tasks
  drop constraint if exists tasks_order_in_day_check;
alter table public.tasks alter column order_in_day set not null;
alter table public.tasks alter column order_in_day set default 0;

alter table public.tasks alter column title set not null;
alter table public.tasks alter column coins_earned set not null;
alter table public.tasks alter column coins_earned set default 10;
alter table public.tasks alter column task_date set not null;
alter table public.tasks alter column task_date drop default;
alter table public.tasks alter column status set not null;
alter table public.tasks alter column created_at set not null;

alter table public.tasks
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create index if not exists tasks_user_date_idx
  on public.tasks (user_id, task_date);
create index if not exists tasks_user_status_idx
  on public.tasks (user_id, status);

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`normalize_tasks`, query=本文件 SQL 主体。

- [ ] **Step 4: 验证**

跑 Step 1 的 SQL，再加一条：

```sql
select indexname from pg_indexes
where schemaname='public' and tablename='tasks'
order by indexname;
```

Expected：`has_updated_at=1`、`order_check` 为 null（约束已删除）、索引列表包含 `tasks_user_date_idx`、`tasks_user_status_idx`、`tasks_pkey`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010100_normalize_tasks.sql
git commit -m "feat(supabase): normalize tasks table, add updated_at trigger and indexes"
```

---

### Task 4: 创建 coin_transactions 表

**目的：** 为 Profile 的最近金币流水和 `complete_task` RPC 提供金币流水落地表。

**Files:**
- Create: `supabase/migrations/20260528010200_create_coin_transactions.sql`

- [ ] **Step 1: 验证表当前不存在**

```sql
select count(*) as t_count from information_schema.tables
where table_schema='public' and table_name='coin_transactions';
```

Expected：`t_count=0`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010200_create_coin_transactions.sql`:

```sql
-- create_coin_transactions: 金币流水表
begin;

create table public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  amount integer not null,
  balance_after integer not null,
  reason text not null check (reason in ('task_complete', 'reward_redeem', 'spin_cost', 'spin_win', 'adjustment')),
  reference_type text,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create index coin_transactions_user_created_idx
  on public.coin_transactions (user_id, created_at desc);

alter table public.coin_transactions enable row level security;

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`create_coin_transactions`, query=本文件 SQL 主体。

- [ ] **Step 4: 验证表已建好且 RLS 已开启**

```sql
select
  (select count(*) from information_schema.tables
     where table_schema='public' and table_name='coin_transactions') as t_count,
  (select relrowsecurity from pg_class
     where oid='public.coin_transactions'::regclass) as rls_on;
```

Expected：`t_count=1`，`rls_on=true`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010200_create_coin_transactions.sql
git commit -m "feat(supabase): create coin_transactions table"
```

---

### Task 5: 规范 feed_messages 表

**目的：** 把现有 `content text` 改成 spec 要求的 `title text not null` + `body text`，并把 `metadata` 设为 NOT NULL default `'{}'`。

**Files:**
- Create: `supabase/migrations/20260528010300_normalize_feed_messages.sql`

- [ ] **Step 1: 验证当前 feed_messages 是旧 schema**

```sql
select column_name, is_nullable, column_default
from information_schema.columns
where table_schema='public' and table_name='feed_messages'
order by ordinal_position;
```

Expected (迁移前)：列里有 `content`，没有 `title`、`body`；`metadata` nullable。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010300_normalize_feed_messages.sql`:

```sql
-- normalize_feed_messages: content -> body，新增 title NOT NULL，metadata NOT NULL default '{}'
begin;

alter table public.feed_messages rename column content to body;
alter table public.feed_messages alter column body drop not null;

alter table public.feed_messages add column title text not null default '';
alter table public.feed_messages alter column title drop default;

alter table public.feed_messages alter column type set not null;
alter table public.feed_messages alter column metadata set not null;
alter table public.feed_messages alter column metadata set default '{}'::jsonb;
alter table public.feed_messages alter column created_at set not null;

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`normalize_feed_messages`。

- [ ] **Step 4: 验证**

跑 Step 1 的 SQL。Expected：列里有 `title` (NOT NULL)、`body` (nullable)，没有 `content`；`metadata` 不允许 null 且默认 `'{}'::jsonb`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010300_normalize_feed_messages.sql
git commit -m "feat(supabase): normalize feed_messages, rename content to body, add title"
```

---

### Task 6: 创建 user_devices 表（APNs 预留）

**目的：** spec 要求建表但客户端不上传 token；本任务只建表，权限策略在 Task 8 一并处理。

**Files:**
- Create: `supabase/migrations/20260528010400_create_user_devices.sql`

- [ ] **Step 1: 验证表当前不存在**

```sql
select count(*) as t_count from information_schema.tables
where table_schema='public' and table_name='user_devices';
```

Expected：`t_count=0`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010400_create_user_devices.sql`:

```sql
-- create_user_devices: APNs 设备表（第一阶段仅建表）
begin;

create table public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  device_token text not null,
  platform text not null default 'ios',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_token)
);

create trigger user_devices_set_updated_at
  before update on public.user_devices
  for each row execute function public.set_updated_at();

alter table public.user_devices enable row level security;

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`create_user_devices`。

- [ ] **Step 4: 验证**

```sql
select
  (select count(*) from information_schema.tables
     where table_schema='public' and table_name='user_devices') as t_count,
  (select count(*) from information_schema.table_constraints
     where table_schema='public' and table_name='user_devices'
       and constraint_type='UNIQUE') as unique_count;
```

Expected：`t_count=1`, `unique_count=1`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010400_create_user_devices.sql
git commit -m "feat(supabase): create user_devices table (APNs placeholder)"
```

---

### Task 7: 重置 RLS 策略

**目的：** 删除现有 9 条策略，按 spec 重新建一套：用户只读写自己的资源；`coin_transactions`、`feed_messages` 的写入只能由 RPC 用 `SECURITY DEFINER` 完成，普通登录角色不允许直接 INSERT/UPDATE/DELETE。

**Files:**
- Create: `supabase/migrations/20260528010500_reset_rls_policies.sql`

- [ ] **Step 1: 验证当前 policy 总数**

```sql
select count(*) as policy_count from pg_policies where schemaname='public';
```

Expected (迁移前)：`policy_count=9`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010500_reset_rls_policies.sql`:

```sql
-- reset_rls_policies: 按 spec 重建公开表的 RLS 策略
begin;

alter table public.users enable row level security;
alter table public.tasks enable row level security;
alter table public.coin_transactions enable row level security;
alter table public.feed_messages enable row level security;
alter table public.rewards enable row level security;
alter table public.redemption_history enable row level security;
alter table public.user_devices enable row level security;

drop policy if exists "users: select own" on public.users;
drop policy if exists "users: update own" on public.users;
drop policy if exists "users: insert service_role" on public.users;
drop policy if exists "tasks: all own" on public.tasks;
drop policy if exists "feed_messages: select all users" on public.feed_messages;
drop policy if exists "feed_messages: insert own" on public.feed_messages;
drop policy if exists "rewards: select all" on public.rewards;
drop policy if exists "redemption_history: select own" on public.redemption_history;
drop policy if exists "redemption_history: insert own" on public.redemption_history;

create policy "users_select_own" on public.users
  for select to authenticated using (auth.uid() = id);
create policy "users_update_own" on public.users
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "tasks_select_own" on public.tasks
  for select to authenticated using (auth.uid() = user_id);
create policy "tasks_insert_own" on public.tasks
  for insert to authenticated with check (auth.uid() = user_id);
create policy "tasks_update_own" on public.tasks
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "tasks_delete_own" on public.tasks
  for delete to authenticated using (auth.uid() = user_id);

create policy "coin_transactions_select_own" on public.coin_transactions
  for select to authenticated using (auth.uid() = user_id);

create policy "feed_messages_select_authenticated" on public.feed_messages
  for select to authenticated using (true);

create policy "rewards_select_authenticated" on public.rewards
  for select to authenticated using (true);

create policy "redemption_history_select_own" on public.redemption_history
  for select to authenticated using (auth.uid() = user_id);

create policy "user_devices_select_own" on public.user_devices
  for select to authenticated using (auth.uid() = user_id);
create policy "user_devices_insert_own" on public.user_devices
  for insert to authenticated with check (auth.uid() = user_id);
create policy "user_devices_update_own" on public.user_devices
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "user_devices_delete_own" on public.user_devices
  for delete to authenticated using (auth.uid() = user_id);

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`reset_rls_policies`。

- [ ] **Step 4: 验证 policy 总数和分布**

```sql
select tablename, count(*) as n
from pg_policies where schemaname='public'
group by tablename order by tablename;
```

Expected：`coin_transactions=1`, `feed_messages=1`, `redemption_history=1`, `rewards=1`, `tasks=4`, `user_devices=4`, `users=2`，总共 14 条。

注意：`coin_transactions`、`feed_messages` 上没有 INSERT/UPDATE/DELETE 策略，这是有意为之——只让 `SECURITY DEFINER` RPC 写入。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010500_reset_rls_policies.sql
git commit -m "feat(supabase): reset RLS policies per MVP spec"
```

---

### Task 8: handle_new_user 触发器

**目的：** Supabase Dashboard 创建 auth 用户后，自动在 `public.users` 写一行 profile，避免运维步骤遗漏。`nickname` 从 `raw_user_meta_data.nickname` 取，缺省 "我的昵称"。

**Files:**
- Create: `supabase/migrations/20260528010600_handle_new_user.sql`

- [ ] **Step 1: 验证触发器当前不存在**

```sql
select count(*) as trg_count from pg_trigger
where tgname='on_auth_user_created' and tgrelid='auth.users'::regclass;
```

Expected (迁移前)：`trg_count=0`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010600_handle_new_user.sql`:

```sql
-- handle_new_user: auth.users 新增时自动创建 public.users profile
begin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, nickname)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nickname', '我的昵称')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`handle_new_user`。

- [ ] **Step 4: 验证触发器和函数已就位**

```sql
select
  (select count(*) from pg_trigger
     where tgname='on_auth_user_created' and tgrelid='auth.users'::regclass) as trg_count,
  (select prosecdef from pg_proc
     where proname='handle_new_user' and pronamespace='public'::regnamespace) as is_security_definer;
```

Expected：`trg_count=1`, `is_security_definer=true`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010600_handle_new_user.sql
git commit -m "feat(supabase): add handle_new_user trigger to auto-create profile"
```

---

### Task 9: complete_task RPC

**目的：** 实现 spec §RPC 设计的 `complete_task(task_id uuid)`，原子地把任务标记完成、加金币、加完成统计、写流水、写动态。`SECURITY DEFINER` 保证函数能写 `coin_transactions` 和 `feed_messages`（RLS 不允许直接写）。重复完成幂等，不重复加金币。

**Files:**
- Create: `supabase/migrations/20260528010700_complete_task_rpc.sql`

- [ ] **Step 1: 验证函数当前不存在**

```sql
select count(*) as fn_count from pg_proc
where proname='complete_task' and pronamespace='public'::regnamespace;
```

Expected (迁移前)：`fn_count=0`。

- [ ] **Step 2: 写本地 migration 文件**

Create `supabase/migrations/20260528010700_complete_task_rpc.sql`:

```sql
-- complete_task: 原子化完成任务，加金币、写流水、写动态
begin;

create or replace function public.complete_task(p_task_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks%rowtype;
  v_user public.users%rowtype;
  v_new_balance integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select * into v_task from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_task.user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_task.status = 'completed' then
    select * into v_user from public.users where id = v_uid;
    return jsonb_build_object(
      'task', to_jsonb(v_task),
      'coins', v_user.coins,
      'total_completed', v_user.total_completed,
      'already_completed', true
    );
  end if;

  update public.tasks
    set status = 'completed',
        completed_at = now()
    where id = p_task_id
    returning * into v_task;

  update public.users
    set coins = coins + v_task.coins_earned,
        total_completed = total_completed + 1
    where id = v_uid
    returning * into v_user;

  v_new_balance := v_user.coins;

  insert into public.coin_transactions
    (user_id, amount, balance_after, reason, reference_type, reference_id)
  values
    (v_uid, v_task.coins_earned, v_new_balance, 'task_complete', 'task', v_task.id);

  insert into public.feed_messages (user_id, type, title, body, metadata)
  values (
    v_uid,
    'task_complete',
    '完成任务：' || v_task.title,
    coalesce(v_task.notes, ''),
    jsonb_build_object(
      'task_id', v_task.id,
      'coins_earned', v_task.coins_earned,
      'task_type', v_task.task_type
    )
  );

  return jsonb_build_object(
    'task', to_jsonb(v_task),
    'coins', v_new_balance,
    'total_completed', v_user.total_completed,
    'already_completed', false
  );
end;
$$;

revoke all on function public.complete_task(uuid) from public;
grant execute on function public.complete_task(uuid) to authenticated;

commit;
```

- [ ] **Step 3: 应用 migration**

`mcp__supabase__apply_migration` name=`complete_task_rpc`。

- [ ] **Step 4: 验证函数签名、权限、SECURITY DEFINER**

```sql
select
  p.proname,
  p.prosecdef as is_security_definer,
  pg_get_function_arguments(p.oid) as args,
  pg_get_function_result(p.oid) as result_type,
  has_function_privilege('authenticated', p.oid, 'execute') as auth_can_execute,
  has_function_privilege('anon', p.oid, 'execute') as anon_can_execute
from pg_proc p
where p.proname='complete_task' and p.pronamespace='public'::regnamespace;
```

Expected：`is_security_definer=true`, `args='p_task_id uuid'`, `result_type='jsonb'`, `auth_can_execute=true`, `anon_can_execute=false`。

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260528010700_complete_task_rpc.sql
git commit -m "feat(supabase): add complete_task RPC with atomic coin write-through"
```

---

### Task 10: 运行 Supabase advisors 并处理关键告警

**目的：** spec §测试与验证 要求"Supabase advisors 无关键安全问题"。这一步只检查、按需补丁，不引入新功能。

**Files:**
- Possibly create: `supabase/migrations/20260528010800_advisor_fixes.sql`（如果有 ERROR 级告警需要修复）

- [ ] **Step 1: 跑安全 advisor**

调用 `mcp__supabase__get_advisors` with `type=security`。

- [ ] **Step 2: 跑性能 advisor**

调用 `mcp__supabase__get_advisors` with `type=performance`。

- [ ] **Step 3: 判定**

把两份报告中 level=`ERROR` 的条目列出来。

判定规则：
- 如果只有 INFO/WARN 告警（例如 "unused index"），跳到 Step 6，不写迁移。
- 如果有 `function_search_path_mutable` 类型的 ERROR：这通常已经被我们 `set search_path = public` 覆盖；如果 advisor 仍然报告，需要在新迁移里追加 `alter function ... set search_path = public`。
- 如果有 RLS 相关 ERROR（例如某张表 RLS 未启用），写补丁迁移。
- 任何 ERROR 都必须修复，WARN 由人工判断。

- [ ] **Step 4 (条件): 如有需要，写补丁 migration**

只在 Step 3 判定需要修复时执行。Create `supabase/migrations/20260528010800_advisor_fixes.sql` with the minimal SQL that addresses each ERROR. 每条 SQL 上方写一行 `-- fix: <advisor-name> on <object>` 注释。

- [ ] **Step 5 (条件): 应用补丁并重跑 advisor**

`mcp__supabase__apply_migration` name=`advisor_fixes`，然后重跑 Step 1 / Step 2 的 advisor，确认 ERROR 列表清空。

- [ ] **Step 6: 把 advisor 结果摘要追加到 `supabase/_baseline.md`**

在文件末尾追加：

```markdown
## Advisors after Task 10 (2026-05-28)

### Security
- ERROR: <none|...>
- WARN: <list>

### Performance
- ERROR: <none|...>
- WARN: <list>
```

- [ ] **Step 7: Commit**

```bash
git add supabase/_baseline.md supabase/migrations/20260528010800_advisor_fixes.sql
git commit -m "chore(supabase): run advisors and apply fixes if needed"
```

如果没创建补丁文件，把 `supabase/migrations/...` 从 `git add` 里去掉。

---

### Task 11: 创建预置账号（人工 + 自动验证）

**目的：** spec 要求"用户范围：Supabase 后台预置两个账号"。这一步需要人工到 Supabase Dashboard 创建 auth 用户，然后由本任务用 SQL 验证 trigger 是否生效。

**Files:** 无文件变更，纯验证。

- [ ] **Step 1: 通知用户并暂停**

向用户输出（中文）：

> 现在需要你在 Supabase Dashboard 创建 2 个测试账号：
> 1. 打开 https://supabase.com/dashboard/project/yvpnuagkykpbhlljexnt/auth/users
> 2. 点 "Add user" → "Create new user"
> 3. 账号 1：邮箱 `user1@dailylog.local`，密码 `DailyLog!1`，勾选 "Auto Confirm User"
> 4. 账号 2：邮箱 `user2@dailylog.local`，密码 `DailyLog!2`，勾选 "Auto Confirm User"
> 5. 完成后告诉我"已创建"。
>
> 如果你想用其他邮箱/密码，直接给我替换值。

等待用户确认。

- [ ] **Step 2: 验证 auth.users 有两行**

```sql
select id, email, email_confirmed_at is not null as confirmed
from auth.users
where email in ('user1@dailylog.local', 'user2@dailylog.local')
order by email;
```

Expected：返回 2 行，`confirmed=true`。如果只有 1 行或 0 行，向用户报错并停止。

如果用户用了自定义邮箱，按用户提供的邮箱替换查询条件。

- [ ] **Step 3: 验证 public.users profile 已通过 trigger 自动创建**

```sql
select u.id, u.nickname, u.coins, u.total_completed, au.email
from public.users u
join auth.users au on au.id = u.id
where au.email in ('user1@dailylog.local', 'user2@dailylog.local')
order by au.email;
```

Expected：返回 2 行，每行 `nickname='我的昵称'`、`coins=0`、`total_completed=0`。

如果返回 0 行，触发器未生效——回到 Task 8 检查。

- [ ] **Step 4: 把两个 user_id 记录到本地文档以便后续使用**

把 Step 3 查询出的两个 `id` 追加到 `supabase/_baseline.md`：

```markdown
## Seed accounts (2026-05-28)

| email | user_id |
| --- | --- |
| user1@dailylog.local | <uuid> |
| user2@dailylog.local | <uuid> |
```

- [ ] **Step 5: Commit**

```bash
git add supabase/_baseline.md
git commit -m "docs(supabase): record seed account user IDs"
```

---

### Task 12: 端到端验证 complete_task 链路

**目的：** 用预置账号的 user_id 模拟 `auth.uid()`，跑一遍"创建任务 → 完成任务 → 检查金币/流水/动态"的完整路径，确认 RPC 和 RLS 都按 spec 工作。重复完成也要验证幂等。

**Files:** 无文件变更，纯 SQL 验证。

约定：以下 SQL 用 `set local "request.jwt.claims" = '{"sub":"<USER_ID>","role":"authenticated"}'` 模拟登录态。把 `<USER1_ID>` 替换为 Task 11 Step 4 记录的 user1 uuid。

- [ ] **Step 1: 以 user1 身份创建一个 daily 任务**

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER1_ID>","role":"authenticated"}';

insert into public.tasks (user_id, title, notes, task_type, task_date, coins_earned)
values ('<USER1_ID>', '喝水 2L', '上午下午各一次', 'daily', current_date, 10)
returning id, title, status, coins_earned;
commit;
```

Expected：插入成功，返回 1 行 `status='pending'`, `coins_earned=10`。

把返回的 task id 记作 `<TASK_ID>` 在后续 step 复用。

- [ ] **Step 2: 验证任务确实写入并能被 user1 查到**

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER1_ID>","role":"authenticated"}';
select id, title, status from public.tasks where id = '<TASK_ID>';
commit;
```

Expected：返回 1 行。

- [ ] **Step 3: 验证 user2 无法看到 user1 的任务（RLS 隔离）**

把 `<USER1_ID>` 换成 `<USER2_ID>`：

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER2_ID>","role":"authenticated"}';
select count(*) from public.tasks where id = '<TASK_ID>';
commit;
```

Expected：返回 `count=0`。

- [ ] **Step 4: 以 user1 身份调用 complete_task**

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER1_ID>","role":"authenticated"}';
select public.complete_task('<TASK_ID>');
commit;
```

Expected：返回 jsonb，结构包含 `coins=10`, `total_completed=1`, `already_completed=false`, `task.status='completed'`。

- [ ] **Step 5: 验证四张表都按预期更新**

```sql
select id, coins, total_completed from public.users where id = '<USER1_ID>';
-- Expected: coins=10, total_completed=1

select id, status, completed_at is not null as has_completed_at
from public.tasks where id = '<TASK_ID>';
-- Expected: status='completed', has_completed_at=true

select amount, balance_after, reason, reference_id
from public.coin_transactions where user_id = '<USER1_ID>';
-- Expected: 1 行，amount=10, balance_after=10, reason='task_complete', reference_id=<TASK_ID>

select type, title, body, metadata->>'coins_earned' as coins_earned
from public.feed_messages where user_id = '<USER1_ID>';
-- Expected: 1 行，type='task_complete', title='完成任务：喝水 2L', coins_earned='10'
```

如果任何一项不符合，停止并把 RPC 改回 Task 9 排查。

- [ ] **Step 6: 重复调用 complete_task 验证幂等**

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER1_ID>","role":"authenticated"}';
select public.complete_task('<TASK_ID>');
commit;
```

Expected：返回 jsonb 中 `already_completed=true`, `coins=10`（仍然是 10，没有变成 20），`total_completed=1`。

再次确认底层数据没变：

```sql
select coins, total_completed from public.users where id = '<USER1_ID>';
-- Expected: coins=10, total_completed=1（不变）

select count(*) from public.coin_transactions where user_id = '<USER1_ID>';
-- Expected: 1（不重复写流水）

select count(*) from public.feed_messages where user_id = '<USER1_ID>';
-- Expected: 1（不重复写动态）
```

- [ ] **Step 7: 验证 user2 不能完成 user1 的任务**

```sql
begin;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"<USER2_ID>","role":"authenticated"}';
select public.complete_task('<TASK_ID>');
commit;
```

Expected：抛出错误 `forbidden`（errcode 42501）。

- [ ] **Step 8: 验证未登录不能完成任务**

```sql
begin;
set local role anon;
select public.complete_task('<TASK_ID>');
commit;
```

Expected：抛出 `permission denied for function complete_task`（anon 无 execute 权限）。

- [ ] **Step 9: 清理测试数据**

```sql
delete from public.feed_messages where user_id = '<USER1_ID>';
delete from public.coin_transactions where user_id = '<USER1_ID>';
delete from public.tasks where id = '<TASK_ID>';
update public.users set coins = 0, total_completed = 0 where id = '<USER1_ID>';
```

验证：

```sql
select coins, total_completed from public.users where id = '<USER1_ID>';
-- Expected: 0, 0

select count(*) from public.tasks where user_id = '<USER1_ID>';
-- Expected: 0
```

- [ ] **Step 10: 把验证摘要追加到 `supabase/_baseline.md`**

```markdown
## End-to-end verification (2026-05-28)

- 创建任务 (RLS insert)：PASS
- 跨用户读取隔离 (RLS select)：PASS
- complete_task 首次调用：PASS（金币+10，流水+1，动态+1）
- complete_task 重复调用幂等：PASS
- 跨用户完成 (forbidden)：PASS
- 未登录调用 (permission denied)：PASS
```

- [ ] **Step 11: Commit**

```bash
git add supabase/_baseline.md
git commit -m "test(supabase): record end-to-end RPC verification results"
```

---

## 完成定义

完成本计划后，Supabase 项目 `yvpnuagkykpbhlljexnt` 应该处于以下状态：

- 7 张表：`users`、`tasks`、`coin_transactions`、`feed_messages`、`rewards`、`redemption_history`、`user_devices`，全部启用 RLS。
- `users.id` 引用 `auth.users(id)`，`openid` 已删除。
- 14 条 RLS 策略，按 spec 限制只读自己 + 任务可自管。`coin_transactions`、`feed_messages` 无写策略。
- `handle_new_user` trigger 自动建 profile。
- `complete_task(uuid)` RPC 在 RLS 下原子写入金币 + 统计 + 流水 + 动态，幂等且权限正确。
- 2 个预置 auth 账号已创建，profile 自动落地。
- Supabase advisors 无 ERROR 级告警。
- 本地 `supabase/migrations/` 有 8 个 SQL 文件（advisor_fixes 可能不存在）作为源码。

Plan B（iOS）会以本计划完成的远端 schema 为前提。

## Self-Review Checklist

- [x] Spec §iOS 架构 → 不在本计划范围，Plan B 处理。
- [x] Spec §Supabase 数据模型 → Task 2-6 覆盖 7 张表的字段、约束、索引。
- [x] Spec §RPC 设计 → Task 9 实现 9 项职责（auth 校验、user_id 校验、幂等、状态更新、金币、统计、流水、动态、返回 jsonb）。
- [x] Spec §RLS 策略 → Task 7 覆盖所有 7 张表的策略边界。
- [x] Spec §测试与验证（数据库部分） → Task 10（advisors）+ Task 12（端到端 RPC 验证）。
- [x] Spec §发行边界 / §不做项 → 本计划不涉及客户端实现，自然合规。
- [x] Spec §错误处理（重复完成、forbidden、未登录） → Task 12 Step 6/7/8 显式验证。
- [x] Spec 提到的"预置两个账号" → Task 11 包含人工步骤和 trigger 自动建 profile 的验证。
- [x] 类型一致性：`complete_task` 在 Task 9 返回 jsonb 字段 (`task`, `coins`, `total_completed`, `already_completed`)；Task 12 Step 4 Expected 中用同样字段名校验。
