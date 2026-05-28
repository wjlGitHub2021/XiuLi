# CLAUDE.md

## 项目概述

DailyLog — 两人使用的每日任务打卡 iOS 应用。完成任务获得金币，金币可兑换奖励或参与转盘抽奖。

## 技术栈

- **客户端：** SwiftUI, iOS 17+, supabase-swift 2.46.0
- **后端：** Supabase (PostgreSQL 15, Auth, RLS, RPC, Edge Functions)
- **项目管理工具：** xcodegen (project.yml → .xcodeproj)

## 关键配置

```
SUPABASE_PROJECT_REF=yvpnuagkykpbhlljexnt
SUPABASE_URL=https://yvpnuagkykpbhlljexnt.supabase.co
IOS_BUNDLE_ID=com.wangjinlong.DailyLog
IOS_DEPLOYMENT_TARGET=17.0
```

## 目录结构

```
XiuLi/
├── DailyLog/                    # iOS 项目
│   ├── project.yml              # xcodegen 配置
│   ├── DailyLog.xcodeproj/      # 生成的 Xcode 项目
│   └── DailyLog/                # Swift 源码
│       ├── App/                 # 入口、AppState、路由
│       ├── Core/                # Supabase客户端、Models、Services、DesignSystem
│       ├── Features/            # Login、Today、Profile
│       └── Resources/           # Assets
├── supabase/                    # 数据库迁移（Plan A 产出）
├── docs/superpowers/            # 设计文档和实现计划
└── DailyLog-iOS-Project-Brief.md
```

## 常用命令

```bash
# 重新生成 Xcode 项目（添加/删除文件后必须执行）
cd DailyLog && xcodegen generate

# 编译
xcodebuild -project DailyLog/DailyLog.xcodeproj -scheme DailyLog \
  -destination 'generic/platform=iOS Simulator' build

# 部署到模拟器
xcrun simctl install booted <path-to-.app>
xcrun simctl launch booted com.wangjinlong.DailyLog

# Supabase CLI
supabase --version
```

## 数据库状态

当前数据库是**旧 schema**（Plan A 迁移尚未执行）：
- `public.users` 仍有 `openid` 列（NOT NULL + UNIQUE）
- `coin_transactions` 表不存在
- `handle_new_user` 触发器不存在
- `complete_task` RPC 不存在
- RLS 策略是旧的

已有两个预置账号：
- `wjl@qq.com` (昵称：王锦龙)
- `lyx@qq.com` (昵称：刘雨欣)

## 约束

- 不上架 App Store，本地签名安装即可
- 不实现注册、邀请、微信登录
- 第一阶段不实现 APNs 推送
- 界面文案使用中文
- 视觉参考 iOS 26 Liquid Glass，可读性优先
