# 绣历 (XiuLi)

一款两人协作的任务打卡 + 金币奖励 iOS 应用，使用 SwiftUI + iOS 26 Liquid Glass 设计语言构建。

## 功能概览

- **任务管理**：日任务/周任务/月任务，每类最多 5 个
- **金币系统**：完成任务获得金币（日10/周30/月100）
- **奖励兑换**：四档奖励（基础/稀有/传说/神圣），用金币兑换
- **转盘抽奖**：每次 10 金币，随机获得奖励
- **个人中心**：头像上传、昵称修改、推送设置、金币记录

## 技术栈

- **前端**：SwiftUI, iOS 26 SDK, Liquid Glass Effect
- **后端**：Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **最低部署**：iOS 26 / Xcode 26 beta

## 如何运行

### 1. 克隆项目

```bash
git clone https://github.com/wjlGitHub2021/XiuLi.git
cd XiuLi/DailyLog
```

### 2. 配置后端连接

本项目前端代码使用 Supabase Swift SDK。你需要提供自己的后端地址和密钥：

```bash
cp DailyLog/Core/Supabase/SupabaseClient.swift.example \
   DailyLog/Core/Supabase/SupabaseClient.swift
```

编辑 `SupabaseClient.swift`，填入你的后端项目地址和 API Key。

### 3. 构建后端

本项目使用 Supabase 作为后端，但你可以用任何支持以下能力的后端替代：

**数据存储需求：**
- 用户表（昵称、头像、金币余额、累计完成数、推送开关）
- 任务表（标题、备注、类型 daily/weekly/monthly、状态 pending/completed、日期、过期日期、奖励金币数）
- 奖励表（名称、图标、价格、类型 direct/spin、档次 basic/rare/legendary/sacred、概率）
- 金币流水表（金额、余额快照、原因）
- 兑换记录表
- 动态消息表（用于双人 feed）

**业务逻辑需求：**
- 完成任务：原子操作 — 更新任务状态 + 发放金币 + 记录流水
- 兑换奖励：原子操作 — 扣除金币 + 记录流水 + 写入兑换记录
- 转盘抽奖：扣 10 金币 + 按概率随机选奖励 + 记录
- 用户注册时自动创建 profile

**安全需求：**
- 用户只能操作自己的数据（行级安全）
- 奖励表对用户只读
- 金币余额不能为负数

**文件存储：**
- 需要一个头像上传的存储桶（公开读取）

**账号系统：**
- 本项目为邮箱+密码登录，不支持注册（需后端手动创建账号）
- 这是一个两人协作应用，你需要在后端 Auth 中手动创建两个用户账号
- 创建账号后，用户首次登录会自动生成 profile（昵称默认"我的昵称"）

### 4. 安装到真机

> 系统要求：iPhone 需升级至 iOS 26 或以上（目前为 Developer Beta）。本项目使用了 iOS 26 独有的 Liquid Glass API，低版本系统无法运行。

**方式一：Xcode 直装（免费，无需开发者账号）**

1. 用数据线连接 iPhone 到 Mac
2. 打开 Xcode，选择你的 iPhone 作为运行目标
3. 在 Signing & Capabilities 中选择你的 Apple ID（免费即可）
4. Command+R 运行，app 会安装到手机上
5. 首次安装需要在 iPhone 上信任开发者：设置 → 通用 → VPN与设备管理 → 信任

> 注意：免费账号安装的 app 每 7 天过期，需要重新连电脑运行一次。

**方式二：付费开发者账号 + TestFlight（688元/年）**

1. 注册 Apple Developer Program（https://developer.apple.com/cn/）
2. 在 Xcode 中 Archive 项目，上传到 App Store Connect
3. 在 TestFlight 中添加测试人员邮箱
4. 测试人员通过 TestFlight app 下载安装
5. 支持推送通知，有效期 90 天

**方式三：模拟器运行**

```bash
open DailyLog.xcodeproj
```

选择 iOS 26 模拟器，Command+R 运行。

## 奖励策略

| 任务类型 | 完成奖励 |
|---------|---------|
| 日任务 | 10 金币 |
| 周任务 | 30 金币 |
| 月任务 | 100 金币 |

| 奖励档次 | 兑换价格 | 大约需要 |
|---------|---------|---------|
| 基础 | 50~100 币 | 1~2 天 |
| 稀有 | 200~300 币 | 约 1 周 |
| 传说 | 500~800 币 | 约 2~3 周 |
| 神圣 | 1500~2000 币 | 约 1~2 个月 |

## 截图

应用使用 iOS 26 Liquid Glass 设计语言，支持毛玻璃效果、动态光影和半透明层叠。

## License

MIT
