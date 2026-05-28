# DailyLog iOS MVP 设计

日期：2026-05-27

## 目标

DailyLog 第一阶段要搭建一个真实连接 Supabase 的原生 iOS MVP，而不是 mock 原型。MVP 先完成项目骨架、登录、Profile 和 Today 基础模块，其中 Today 包含日/周/月任务创建、筛选、列表和完成任务。

本阶段使用 SwiftUI + Supabase Swift SDK。视觉参考 iOS 26 Liquid Glass，但所有设计以可用性、可读性、稳定交互和清晰错误反馈为先。

## 已确认配置

- Supabase project ref：`yvpnuagkykpbhlljexnt`
- Supabase URL：`https://yvpnuagkykpbhlljexnt.supabase.co`
- iOS Bundle Identifier：`com.wangjinlong.DailyLog`
- 登录方式：Supabase Auth email/password
- 用户范围：Supabase 后台预置两个账号
- 客户端语言：中文界面文案
- 发行方式：不上架 App Store，第一阶段以本地签名安装包或开发设备安装为目标

`SUPABASE_ANON_KEY` 可以进入 iOS 客户端，但必须配合 RLS 和 RPC。`SUPABASE_SERVICE_ROLE_KEY` 不能进入客户端，只能用于 Supabase Edge Function 或受控后端环境。

## 发行与安装边界

第一阶段不编写 App Store 上架、审核、营销素材或 TestFlight 外测流程。交付目标是可以在开发设备或受信任设备上安装运行的 iOS App 包：优先支持 Xcode 连接设备安装；如具备 Apple Developer 签名条件，再导出 Development 或 Ad Hoc `.ipa`。安装包流程只包含必要的 bundle identifier、签名配置、归档、导出和安装验证。

## 不做项

第一阶段明确不做以下内容：

- 微信小程序迁移
- 微信登录、微信订阅消息、微信 openid 链路
- 注册入口
- 情侣邀请、邀请码、绑定流程
- APNs 推送实现
- App Store 上架流程
- App Store Connect 元数据、截图和审核材料
- 九宫格转盘
- 奖励兑换
- 完整动态流页面

推送按 iOS App 软件消息推送规划，数据库可以预留设备表，但第一阶段不请求通知权限、不上传 APNs device token、不部署推送 Edge Function。

## 方案选择

采用“正式 schema + RLS + RPC 的真实 MVP”。

不选择最小补丁式接入，因为当前数据库仍有旧小程序痕迹，例如 `users.openid`、`feed_messages.content`、`rewards.name/type`，且缺少金币流水。继续沿用会让 iOS 第一版带着错误边界前进。

不选择一次性完整产品骨架，因为 Feed、Rewards、兑换、转盘和 APNs 会扩大第一阶段范围，影响登录、Profile、Today 的闭环质量。

## iOS 架构

工程采用 SwiftUI 分层结构：

```text
DailyLog/
  App/
    DailyLogApp.swift
    AppState.swift
  Core/
    Supabase/
    Auth/
    Models/
    Services/
    DesignSystem/
  Features/
    Login/
    Today/
    Profile/
  Resources/
```

### AppState

`AppState` 管理会话恢复、登录状态、当前用户 profile、全局 loading 和退出登录。启动时优先恢复 Supabase session，有有效 session 时进入主界面，否则进入登录页。

### Core

- `SupabaseClientProvider`：集中配置 Supabase URL 和 anon key。
- `AuthService`：登录、退出、会话恢复。
- `ProfileService`：读取 profile、金币余额、完成统计、最近金币流水。
- `TaskService`：读取任务、创建任务、调用 `complete_task`。
- `DesignSystem`：颜色、间距、按钮、列表行、空状态和错误提示组件。

### Features

- `Login`：邮箱、密码、登录按钮、中文错误提示；不显示注册或邀请入口。
- `Today`：默认首页；日/周/月任务筛选；任务列表；创建任务 sheet；完成任务按钮。
- `Profile`：默认头像、昵称、金币、完成统计、最近金币流水、推送设置禁用态、退出登录。

第一阶段主界面使用 Today 和 Profile 两个入口。可以用系统 TabView 或轻量自定义底部切换，视觉上允许局部玻璃感，但不影响可读性和点击目标。

## Supabase 数据模型

数据库迁移以当前项目为准，保留可复用奖励种子数据，整理旧字段和权限策略。

### users

使用 Supabase Auth 用户 ID 作为主键。删除或废弃 `openid`。

关键字段：

- `id uuid primary key references auth.users(id) on delete cascade`
- `nickname text not null`
- `avatar_url text`
- `coins integer not null default 0 check (coins >= 0)`
- `total_completed integer not null default 0`
- `push_enabled boolean not null default false`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### tasks

支持日/周/月任务。第一阶段不拆任务模板和任务实例。

关键字段：

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references public.users(id) on delete cascade`
- `title text not null`
- `notes text`
- `task_type text not null default 'daily' check (task_type in ('daily', 'weekly', 'monthly'))`
- `status text not null default 'pending' check (status in ('pending', 'completed'))`
- `order_in_day integer not null default 0`
- `coins_earned integer not null default 10`
- `task_date date not null`
- `expire_date date`
- `completed_at timestamptz`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

任务创建由客户端在 RLS 约束下直接插入自己的任务。完成任务必须走 RPC。

### coin_transactions

新增金币流水表，支撑 Profile 最近流水和后续金币明细。

关键字段：

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references public.users(id) on delete cascade`
- `amount integer not null`
- `balance_after integer not null`
- `reason text not null check (reason in ('task_complete', 'reward_redeem', 'spin_cost', 'spin_win', 'adjustment'))`
- `reference_type text`
- `reference_id uuid`
- `created_at timestamptz not null default now()`

### feed_messages

动态记录第一阶段仅由完成任务 RPC 写入，不做完整页面。

关键字段：

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references public.users(id) on delete set null`
- `type text not null check (type in ('task_complete', 'reward_redeem', 'spin_win'))`
- `title text not null`
- `body text`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`

### rewards 与 redemption_history

`rewards` 保留现有 21 条种子数据，并在迁移中规范字段命名。`redemption_history` 可以保留或整理为正式结构，但第一阶段不接 UI、不实现兑换 RPC。

### user_devices

第一阶段可以建表作为 APNs 预留，但不接客户端 token 上传。

关键字段：

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references public.users(id) on delete cascade`
- `device_token text not null`
- `platform text not null default 'ios'`
- `is_active boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `unique(user_id, device_token)`

## RPC 设计

### complete_task(task_id)

客户端完成任务时只调用 `complete_task(task_id)`。

RPC 职责：

1. 校验当前用户已登录。
2. 查询任务并确认 `tasks.user_id = auth.uid()`。
3. 如果任务已完成，返回当前任务和 profile 状态，不重复发金币。
4. 将任务状态更新为 `completed`，写入 `completed_at`。
5. 将 `users.coins` 增加 `tasks.coins_earned`。
6. 将 `users.total_completed` 加 1。
7. 写入 `coin_transactions`，reason 为 `task_complete`。
8. 写入 `feed_messages`，type 为 `task_complete`。
9. 返回更新后的任务、金币余额和完成统计，供客户端刷新 UI。

RPC 必须保证原子性，避免重复点击或并发完成导致重复加金币。

## RLS 策略

策略目标：

- `users`：用户只能读取和更新自己的 profile。profile 初始化由后台或受控脚本完成。
- `tasks`：用户只能读取、创建、更新自己的任务；完成任务的金币相关写入不由客户端直接执行。
- `coin_transactions`：用户只能读取自己的流水；写入只通过 RPC 或服务端路径完成。
- `feed_messages`：登录用户可读；写入只通过 RPC 或服务端路径完成。
- `rewards`：登录用户可读；写入仅后台管理。
- `redemption_history`：用户可读自己的记录；第一阶段不开放客户端写入。
- `user_devices`：用户只管理自己的设备；第一阶段客户端不使用。

迁移后需要运行 Supabase advisors，检查 RLS 和性能风险。

## Today 设计

Today 是第一阶段默认首页。

核心能力：

- 显示今天日期。
- 显示当前金币轻提示。
- 使用分段控件切换日任务、周任务、月任务。
- 展示任务标题、备注、金币值、状态、到期信息。
- 创建任务 sheet 支持标题、备注、任务类型、任务日期、到期日期和金币值。
- 点击完成按钮调用 `complete_task`。
- 完成成功后刷新任务列表、金币余额、完成统计和最近流水。

空状态：

- 当前筛选下没有任务时，显示“今天还没有任务”或对应周/月任务空状态。
- 创建失败时保留用户输入。
- 完成失败时取消 loading 并刷新任务状态。

## Profile 设计

Profile 用于展示用户状态和基础设置。

核心能力：

- 显示默认头像、昵称。
- 显示金币余额。
- 显示完成任务总数。
- 显示最近金币流水。
- 显示推送设置行，第一阶段为禁用或“稍后开放”。
- 提供退出登录。

若没有金币流水，显示“还没有金币记录”。若 profile 不存在，显示中文错误提示，引导检查 Supabase 后台预置账号资料。

## 登录设计

登录页只支持预置账号登录。

输入：

- 邮箱
- 密码

行为：

- 登录成功后恢复 session 并进入 Today。
- 登录失败显示中文错误。
- 网络失败允许重试。
- 不提供注册、找回密码、邀请入口。

## 视觉设计原则

使用 iOS 26 Liquid Glass 作为参考：

- 局部使用玻璃感容器、底部导航或浮动创建按钮。
- 多个玻璃元素需要控制数量和层级，避免页面花哨。
- 表单、任务列表、错误提示和统计数字优先保证对比度。
- 点击目标遵循 iOS 常规尺寸，避免为了视觉效果缩小操作区。
- 中文文案简短、明确，不使用营销式空话。

## 错误处理

- 登录错误：提示“邮箱或密码不正确”或网络相关中文提示。
- session 恢复失败：清理本地状态并回到登录页。
- profile 缺失：提示“账号资料未初始化，请检查后台预置资料”。
- 创建任务失败：保留输入，提示重试。
- 完成任务失败：取消 loading，刷新任务状态。
- 重复完成：RPC 不重复加金币，客户端展示已完成状态。
- 无任务、无流水：显示中文空状态。

## 测试与验证

数据库验证：

- 迁移可应用到 `yvpnuagkykpbhlljexnt`。
- RLS 策略符合第一阶段权限边界。
- `complete_task` 对未登录、非本人任务、重复完成、正常完成都有明确结果。
- Supabase advisors 无关键安全问题。

iOS 验证：

- 项目能构建。
- 登录成功和失败路径可验证。
- session 恢复后能直接进入 Today。
- Today 能创建日/周/月任务。
- 完成任务后金币只增加一次。
- Profile 展示最新金币、完成统计和最近流水。
- 退出登录后回到登录页。

手动验收流程：

```text
登录 → 创建日任务 → 创建周任务 → 创建月任务 → 切换筛选 → 完成任务 → 查看金币变化 → 查看 Profile → 退出登录
```

## 后续阶段

第二阶段再接入：

- Rewards 奖励列表和兑换
- 九宫格转盘
- 完整动态流
- iOS APNs 推送
- Supabase Realtime
- 头像上传和更多设置

第一阶段完成后再决定是否扩展 Tab 结构和服务层。
