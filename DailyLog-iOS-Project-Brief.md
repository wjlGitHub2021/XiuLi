# DailyLog iOS 项目简介

更新时间：2026-05-27

## 1. 项目定位

DailyLog 是一个面向两个人使用的每日任务打卡应用。两个人可以创建和完成日常任务，完成后获得金币，金币可以兑换奖励或参与九宫格转盘抽奖。应用还包含动态流，用来展示任务完成、奖励兑换、转盘中奖等事件。

后续不再继续微信小程序路线，改为原生 iOS 应用：

- 客户端：SwiftUI
- 后端：Supabase（PostgreSQL、Auth、RLS、Storage、RPC / Edge Functions）
- 数据同步：MVP 阶段使用页面刷新；后续可接 Supabase Realtime
- 登录：Supabase Auth 后台预置两个账号，App 只提供登录和退出登录，不提供注册
- 推送：按 iOS App 软件消息推送处理，使用 APNs + Supabase Edge Function，不再使用微信订阅消息
- 邀请：不做情侣邀请、邀请码、绑定流程；两个预置账号默认就是本应用的全部使用者

当前工作重点不是保留小程序代码，而是复用已有 Supabase 项目和可用的业务规则，重建 iOS 客户端与正式数据库结构。

## 2. 当前仓库状态

当前这个目录下只有项目简要文档，没有实际小程序源码目录。原项目曾经是微信小程序结构，包含今日页、创建任务页、动态流、奖励页、我的页面、微信登录、PostgREST 客户端、任务服务、Edge Function 和 Supabase SQL 草案等内容。

原功能可以作为产品参考：

- 用户登录和资料保存
- 日/周/月任务创建
- 今日任务列表和日历查看
- 完成任务获得金币
- 动态流记录
- 奖励兑换
- 九宫格转盘抽奖
- 金币明细和兑换记录
- 推送开关入口

但小程序平台能力不再迁移：WXML、WXSS、`wx.login`、`wx.request`、`wx.requestSubscribeMessage`、自定义 tabbar、微信 openid 登录链路都应废弃。

## 3. iOS 迁移结论

这个项目适合迁移为原生 SwiftUI + Supabase，但不能直接复用小程序 UI 代码。iOS 版应把客户端定位为轻量业务界面，把金币、任务完成、奖励兑换、抽奖等关键写操作放到数据库 RPC 或 Edge Function 中。

可以复用的内容：

- 产品结构和页面信息架构
- 任务、金币、奖励、动态流等业务规则
- Supabase 项目和数据库思路
- 奖励配置
- 部分边界规则，例如每日最多 5 个任务、金币倍率、转盘消耗

建议重做或下沉到后端的内容：

- 登录认证：改为 Supabase Auth email/password
- 金币发放、扣减和抽奖：改为 RPC 或 Edge Function 原子事务
- 任务完成事务：后端保证不能重复完成
- 奖励兑换事务：后端保证金币不足不能兑换
- 推送通知：改为 iOS APNs
- 数据库迁移脚本：整理成正式 schema，不继续沿用小程序草案

## 4. 推荐 iOS 架构

建议采用 SwiftUI 分层结构：

```text
DailyLogApp/
  App/
    DailyLogApp.swift
    AppState.swift
  Features/
    Today/
    CreateTask/
    Feed/
    Rewards/
    Profile/
  Core/
    Supabase/
    Auth/
    Models/
    Services/
    DesignSystem/
  Resources/
```

推荐页面结构：

- `TodayView`：今日任务、日历、日/周/月任务切换、完成任务
- `CreateTaskView`：创建日/周/月任务
- `FeedView`：动态流
- `RewardsView`：金币余额、九宫格转盘、奖励兑换
- `ProfileView`：头像昵称、金币、完成统计、连续天数、金币记录、兑换记录、设置

推荐服务层：

- `AuthService`：登录、退出、会话恢复
- `TaskService`：任务查询、创建、完成
- `RewardService`：奖励列表、兑换、转盘
- `FeedService`：动态流查询
- `ProfileService`：用户资料、统计、金币记录
- `NotificationService`：通知权限、device token 上传、推送开关

## 5. Supabase 项目配置

这个项目只保留并复用下面这个 Supabase 项目。项目 ref 是关键数据库 ID，不要删除：

```text
SUPABASE_PROJECT_REF=yvpnuagkykpbhlljexnt
SUPABASE_URL=https://yvpnuagkykpbhlljexnt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6Inl2cG51YWdreWtwYmhsbGpleG50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2ODU4ODYsImV4cCI6MjA5NTI2MTg4Nn0.RjJjUP3jsShhlUtCU-su-nTvypmn0x0ZugM69TYy1vE
```

`SUPABASE_ANON_KEY` 可以进入 iOS 客户端，但必须配合 RLS 和 RPC 控制敏感写操作。`SUPABASE_SERVICE_ROLE_KEY` 不能进入 iOS 客户端，只能保存在 Supabase Edge Function 或受控后端环境变量中。

已配置 Codex 全局 Supabase MCP：

```text
MCP_NAME=supabase
MCP_URL=https://mcp.supabase.com/mcp?project_ref=yvpnuagkykpbhlljexnt
```

Supabase MCP 已通过 OAuth 授权，并限定到 `SUPABASE_PROJECT_REF=yvpnuagkykpbhlljexnt`。

2026-05-27 通过 Supabase MCP 盘点并清理后的状态：

- `public.users`：0 行，旧小程序用户资料已删除
- `public.tasks`：0 行，旧任务数据已通过用户级联删除
- `public.feed_messages`：0 行，旧动态数据已通过用户级联删除
- `public.redemption_history`：0 行，旧兑换记录已通过用户级联删除
- `public.rewards`：21 行，作为可复用奖励种子数据保留
- `storage.buckets.avatars`：bucket 保留，当前只剩 1 个 0 字节 `.emptyFolderPlaceholder` 占位对象；旧头像文件已删除
- Edge Functions：0 个，旧 `wechat-login` 已通过 Supabase CLI 删除
- Edge Function secrets：旧 `WECHAT_APP_ID`、`WECHAT_APP_SECRET` 已删除

后续需要补齐或确认：

```text
SUPABASE_SERVICE_ROLE_KEY      # 仅用于 Edge Function，不进客户端
IOS_BUNDLE_ID                  # iOS App Bundle Identifier
DEFAULT_ACCOUNT_1_EMAIL        # 后台预置账号 1，只记录邮箱，不写死密码
DEFAULT_ACCOUNT_2_EMAIL        # 后台预置账号 2，只记录邮箱，不写死密码
APNS_KEY_ID                    # Apple Push Notification
APNS_TEAM_ID                   # Apple Developer Team ID
APNS_BUNDLE_ID                 # 推送对应的 Bundle ID
APNS_PRIVATE_KEY               # APNs Auth Key，仅后端保存
```

## 6. 推荐正式数据库结构

iOS 版建议整理为新的正式 schema。旧库中如果已经存在同名表，需要通过 Supabase MCP 或 SQL 先盘点字段；能复用的保留，不能复用的旧表、旧字段、旧数据都可以删除或重建。

### users

使用 Supabase Auth 用户 ID 作为主键。`openid` 不再作为 iOS 主身份，建议删除或废弃。

```sql
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  avatar_url text,
  coins integer not null default 0 check (coins >= 0),
  total_completed integer not null default 0,
  push_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### tasks

任务表保留日/周/月任务能力。为了兼容 MVP，可以先继续使用 `task_date` + `task_type` + `expire_date`，后续如果任务重复规则变复杂，再拆成任务模板和任务实例。

```sql
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  notes text,
  task_type text not null default 'daily' check (task_type in ('daily', 'weekly', 'monthly')),
  status text not null default 'pending' check (status in ('pending', 'completed')),
  order_in_day integer not null default 0,
  coins_earned integer not null default 10,
  task_date date not null,
  expire_date date,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### coin_transactions

建议新增金币流水表。单靠 `users.coins` 很难排查金币变化，也不利于“金币明细”页面。

```sql
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
```

### feed_messages

动态流记录任务完成、奖励兑换和转盘中奖。

```sql
create table public.feed_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  type text not null check (type in ('task_complete', 'reward_redeem', 'spin_win')),
  title text not null,
  body text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
```

### rewards

奖励配置可以复用旧种子数据，但建议确认字段后统一整理。

```sql
create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  reward_type text not null check (reward_type in ('direct', 'spin')),
  cost integer not null default 0 check (cost >= 0),
  probability numeric,
  stock integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### redemption_history

记录直接兑换和转盘中奖历史。

```sql
create table public.redemption_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  reward_id uuid references public.rewards(id) on delete set null,
  source text not null check (source in ('direct', 'spin')),
  cost integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
```

### user_devices

用于 iOS 软件消息推送。客户端保存 APNs device token，服务端在任务完成、兑换、中奖等事件后发推送。

```sql
create table public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  device_token text not null,
  platform text not null default 'ios',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, device_token)
);
```

## 7. RPC / Edge Function 建议

金币相关写操作必须后端化，客户端只调用 RPC 或 Edge Function：

- `complete_task(task_id)`：完成任务、加金币、写金币流水、写动态流、触发推送
- `redeem_reward(reward_id)`：校验金币、扣金币、写兑换记录、写金币流水、写动态流、触发推送
- `spin_reward()`：扣转盘消耗、按服务端概率抽奖、写中奖记录、写金币流水、写动态流、触发推送
- `register_device(device_token)`：保存或更新当前用户设备 token

这样可以保证：

- 金币增减是原子的
- 任务不能重复完成
- 金币不足时不能被并发绕过
- 转盘概率不暴露在客户端
- feed、history、coin ledger 与金币事务一致
- 推送只由受控服务端触发

## 8. 认证与权限建议

iOS 版认证流程：

1. 在 Supabase Auth 后台手动创建两个 email/password 用户。
2. 在 `users` 表中为这两个 Auth 用户创建 profile。
3. 关闭公开注册，不在 iOS App 中提供注册、找回密码、邀请注册等流程。
4. iOS App 只提供登录页：邮箱、密码、登录按钮。
5. 登录成功后保存 Supabase session，后续自动进入应用。
6. 退出登录时清除 session 并回到登录页。

RLS 建议：

- `users`：用户只能读写自己的 profile；如两人需要互看昵称和头像，可开放只读字段。
- `tasks`：用户可以管理自己的任务；如需要两人都能看全部任务，可用一个固定 app scope 或 RPC 读视图处理。
- `feed_messages`：两人都能读取；只允许 RPC / service role 写入。
- `rewards`：所有登录用户可读；只允许后台管理写入。
- `redemption_history`、`coin_transactions`：用户可读自己的记录；只允许 RPC / service role 写入。
- `user_devices`：用户只管理自己的设备 token。

不做情侣邀请后，不需要 `couples`、`couple_members`、邀请码表或绑定流程。两人共享体验可以通过“仅两个账号存在 + RLS/视图允许两人读取必要数据”来实现。

## 9. 数据库清理策略

Supabase MCP 接入后先盘点当前项目中的表、函数、Edge Functions、Storage buckets、RLS policies 和已有数据，再按以下原则处理：

保留或迁移：

- `users` 中能映射到 Supabase Auth UUID 的 profile 数据
- `rewards` 中仍适合 iOS 版的奖励配置
- 与任务、金币、动态流、兑换记录直接相关且字段可修正的表

删除或重建：

- 微信小程序登录相关对象，例如 `openid` 主身份、`wechat-login` Edge Function、微信 session/JWT 交换逻辑
- 情侣邀请、邀请码、绑定关系相关对象
- 与当前 iOS MVP 无关的测试表、临时表、旧草案表
- 不可复用的旧业务数据，包括旧任务、旧动态、旧兑换记录、旧金币流水
- 与新 schema 冲突且迁移成本高于重建的表和策略

清理前应先导出或记录对象清单。当前你已允许删除不可复用内容和旧数据，但真正执行时仍要先确认 MCP 已连接到 `SUPABASE_PROJECT_REF=yvpnuagkykpbhlljexnt`，避免误删其他项目。

## 10. 主要风险点与改进建议

1. 旧 SQL 与实际业务可能不同步  
   需要以当前 Supabase 数据库为准盘点，再生成新的正式迁移脚本。

2. 金币和抽奖不能放客户端  
   小程序和 iOS 都不应该长期把金币扣减、奖励发放、概率抽奖放在客户端。

3. 微信 openid 不适合 iOS 主身份  
   iOS 版应使用 Supabase Auth 用户 ID，并删除或废弃 openid 相关链路。

4. 缺少金币流水  
   建议新增 `coin_transactions`，否则“金币明细”和异常排查都很弱。

5. 推送要从产品入口变成完整链路  
   iOS 版需要通知权限、device token、设备表、Edge Function、APNs 密钥和失败重试策略。

6. 不做情侣邀请后权限模型要更简单  
   不引入 `couples` / `couple_members`，避免为了两个固定账号设计过度复杂的绑定系统。

7. Service role 不能进入 iOS App  
   所有高权限操作必须放在 Edge Function、RPC 或 Supabase 后台环境中。

## 11. 建议下一步

1. 配置 Supabase MCP，限定到 `SUPABASE_PROJECT_REF=yvpnuagkykpbhlljexnt`。
2. 通过 MCP 盘点当前数据库、函数、Storage 和已有数据。
3. 删除不可复用对象和旧数据，保留项目 ref、可用奖励配置和可映射的用户资料。
4. 生成 iOS 版正式 schema 和 RLS policies。
5. 在 Supabase 后台创建两个默认 Auth 账号，并初始化对应 `users` profile。
6. 新建 SwiftUI iOS 项目并配置 Supabase Swift SDK。
7. 先完成登录 + Profile + Today 三个基础模块。
8. 再迁移 Feed、Rewards、Profile 子页面。
9. 最后接入 APNs 推送和九宫格转盘。

建议第一版 MVP 范围：

- 预置账号登录
- 用户资料
- 日/周/月任务创建
- 今日任务列表
- 完成任务得金币
- 金币明细
- 奖励列表
- 兑换奖励
- 基础动态流

第二阶段范围：

- 九宫格转盘
- iOS 软件消息推送
- Supabase Realtime
- 头像上传和更多设置
