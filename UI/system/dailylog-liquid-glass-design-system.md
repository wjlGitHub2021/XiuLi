# DailyLog iOS 26 Liquid Glass 设计系统

适用范围：DailyLog iOS App（SwiftUI + Supabase Swift SDK）

目标：
- 以 iOS 26 Liquid Glass 为视觉基础
- 以淡紫色渐变为主调
- 保持高可读性、低干扰、强操作性
- 直接服务开发落地，而不是偏概念展示

---

## 1. 设计原则

1. 先可用，再好看。玻璃效果必须服务信息层级，不可影响阅读和点击。
2. 全局统一使用淡紫系渐变作为主背景，避免页面之间风格断裂。
3. 玻璃元素只用于容器、按钮、卡片、标签和底部栏，不滥用。
4. 文本、状态、按钮、表单、列表都要保留清晰对比度。
5. 组件尺寸和间距固定，避免内容变化导致布局漂移。
6. 所有页面都要支持空状态、加载态、错误态、权限拒绝态。
7. 动效克制，优先 spring 过渡、轻微缩放、轻微高亮，不做强闪烁。

---

## 2. 视觉基调

### 2.1 主色调

- 主背景：淡紫、浅薰衣草、浅粉紫渐变
- 主强调色：紫罗兰
- 次强调色：柔金色，用于金币、奖励和选中状态
- 成功色：柔和薄荷绿
- 警告色：琥珀橙
- 错误色：温和珊瑚红，不使用高饱和红底

### 2.2 推荐色值

可作为 SwiftUI 设计令牌起点：

| 名称 | 建议值 | 用途 |
|---|---|---|
| `dlLavender` | `#8E6AFF` | 主强调、按钮、选中态 |
| `dlLavenderSoft` | `#D9D0FF` | 背景渐变辅助色 |
| `dlPlum` | `#B69CFF` | 次级强调、玻璃高光 |
| `dlCoin` | `#F6C948` | 金币、余额、奖励 |
| `dlSuccess` | `#35C889` | 完成状态 |
| `dlWarning` | `#FFB454` | 提示和警告 |
| `dlError` | `#FF7F9B` | 错误提示 |
| `dlTextPrimary` | `#272135` | 主文字 |
| `dlTextSecondary` | `#5F5874` | 次文字 |
| `dlGlassWhite` | `rgba(255,255,255,0.42~0.72)` | 玻璃底层 |

### 2.3 背景渐变

推荐使用三段式渐变：

- 左上：`#EEE6FF`
- 右上：`#F8DDF4`
- 下部：`#CFC2FF`

背景上叠加：
- 大面积柔光晕
- 低对比弧形光带
- 极轻微颗粒感

不要：
- 深色霓虹背景
- 强烈霓虹边缘
- 高对比阴影块
- 纯白扁平背景

---

## 3. 字体与排版

### 3.1 字体建议

- 中文：`PingFang SC`
- 英文/数字：`SF Pro`

### 3.2 字号层级

| 层级 | 建议字号 | 用途 |
|---|---|---|
| Display | 40-58 | 页面标题、品牌名 |
| Title | 24-32 | 卡片标题、模块标题 |
| Body | 16-18 | 正文、列表主信息 |
| Caption | 12-14 | 辅助说明、时间、标签 |

### 3.3 排版规则

- 页面标题使用 semibold
- 模块标题使用 medium 或 semibold
- 数字金额可加粗
- 辅助文字统一降低饱和度和透明度
- 不做夸张字间距
- 不使用响应式字号随屏幕宽度变化

---

## 4. 间距与圆角

### 4.1 间距系统

沿用项目里的间距基线：

- `4`
- `8`
- `16`
- `24`
- `32`

### 4.2 圆角系统

| 类型 | 建议值 | 用途 |
|---|---|---|
| 小控件 | 12-16 | 小按钮、标签、提示条 |
| 标准卡片 | 20-24 | 任务条、信息卡 |
| 大面板 | 28-36 | 表单页、抽屉页 |
| 底部栏/大容器 | 48-58 | 底部 Tab、模态页 |

### 4.3 规则

- 卡片不要超过页面宽度的两端安全边界
- 列表项之间保留 8-12 间距
- 表单字段高度保持一致
- 底部操作区与内容区之间要有明显分隔

---

## 5. Liquid Glass 材质规范

### 5.1 玻璃层级

建议分三层：

1. `regular`：普通信息卡、列表项
2. `tinted`：强调卡、选中状态、奖励卡
3. `prominent`：主按钮、关键 CTA

### 5.2 推荐 SwiftUI 用法

```swift
.glassEffect(.regular, in: .rect(cornerRadius: 20))
.glassEffect(.regular.tint(Color.dlLavender.opacity(0.35)), in: .rect(cornerRadius: 20))
.buttonStyle(.glass)
.buttonStyle(.glassProminent)
```

### 5.3 玻璃样式细则

- 背景模糊要轻，避免糊成一团
- 边缘高光要有，但不能像霓虹描边
- 填充透明度控制在可读范围
- 交互态只做微缩放、微亮度变化
- 多个玻璃元素并列时，使用容器管理视觉融合

### 5.4 玻璃容器

多个相邻玻璃元素时，建议使用：

- `GlassEffectContainer`
- `glassEffectUnion`
- `glassEffectID`

适用场景：
- 底部 Tab
- 任务列表中的多个条目
- 奖励面板
- 日历卡片

不要：
- 每个小图标都单独做重玻璃效果
- 在一个页面里混入太多不同材质

---

## 6. 组件规范

### 6.1 顶部导航

页面标题区应保持简洁：
- 左侧可放余额或状态徽标
- 右侧放主要操作按钮
- 标题文字简短

推荐页面：
- 今日
- 动态
- 奖励
- 我的

### 6.2 底部 Tab

底部 Tab 是全局主导航。

规范：
- 4 个入口：今日、动态、奖励、我的
- 选中态使用紫色或淡金紫高亮
- 未选中态使用低饱和灰紫
- 图标 + 文案都要有
- 底部栏必须有玻璃感，但不遮挡内容

### 6.3 按钮

按钮分 3 级：

1. 主按钮：提交、登录、创建、确认完成、开始抽奖
2. 次按钮：取消、选择照片、重新加载
3. 危险按钮：退出登录、删除类操作

按钮规则：
- 主按钮优先使用 `glassProminent`
- 次按钮使用 `glass`
- 危险按钮不要做成纯红大块，建议在玻璃底上轻度 tinted
- 按钮文字保持简短

### 6.4 卡片

卡片分 4 类：

- 信息卡：余额、统计、概览
- 任务卡：任务条目、状态、奖励
- 设置卡：开关、权限、退出登录
- 视觉卡：转盘、日历、状态提示

卡片规则：
- 默认圆角 20-24
- 卡片内部保持 16 间距
- 卡片标题与内容分层清晰
- 视觉卡可以更强一点 tint，但不能抢主流程

### 6.5 列表项

列表项适合：
- 任务
- 金币记录
- 动态消息
- 奖励条目

规则：
- 左图标 / 中主文本 / 右操作或数值
- 主文本一行优先，必要时两行
- 辅助文本用次级色
- 数字奖励、金币变化要高对比

### 6.6 表单

用于新建任务、登录、设置输入。

规则：
- 表单字段高度统一
- placeholder 用中文
- 必须支持键盘类型、文本校正、输入内容类型
- 错误提示要直接落在表单附近
- 表单页优先系统原生 Form 结构，再做局部玻璃化

### 6.7 开关与权限

- 开关用于消息推送等设置
- 权限请求前要说明用途
- 权限拒绝后要提供回到系统设置的路径

---

## 7. 页面规范

### 7.1 登录页

目标：
- 建立品牌第一印象
- 尽量简洁

布局：
- 顶部品牌名 DailyLog
- 一行副标题
- 两个输入框：邮箱、密码
- 一个主登录按钮

注意：
- 不提供注册入口
- 不提供第三方登录
- 不提供邀请码

### 7.2 今日页

目标：
- 作为主工作台
- 集中展示当日任务

布局：
- 顶部金币徽标
- 右上创建任务按钮
- 中部日历卡
- 下方日 / 周 / 月任务分组
- 完成态和未完成态要明确区分

交互：
- 点击任务进入完成流程
- 下拉刷新
- 切换日期重新拉取数据

### 7.3 动态页

目标：
- 呈现任务完成、兑换、抽奖等事件流

布局：
- 顶部标题
- 纵向动态卡片列表
- 每条动态带图标、时间、描述

状态：
- 无动态时显示空状态

### 7.4 奖励页

目标：
- 展示金币余额和可兑换奖励

布局：
- 余额卡
- 转盘入口卡
- 直接兑换列表

交互：
- 兑换前确认
- 兑换成功后提示余额变化

### 7.5 我的页

目标：
- 展示个人信息、统计、记录和设置

布局：
- 头像与昵称
- 金币与打卡统计
- 最近金币记录
- 消息推送开关
- 退出登录按钮

### 7.6 新建任务页

目标：
- 快速创建日 / 周 / 月任务

布局：
- 任务标题
- 备注
- 任务类型
- 日期
- 金币奖励

规则：
- 支持错误提示
- 创建按钮在右上或底部都可以，但必须明显

### 7.7 完成任务页

目标：
- 上传打卡照片并完成任务

布局：
- 上传区
- 照片预览区
- 照片来源选择
- 提交按钮

规则：
- 已完成任务要阻止重复提交
- 上传失败时保留当前输入

### 7.8 日历页

目标：
- 作为日期选择器和任务视图切换器

规则：
- 默认周视图
- 可展开月视图
- 当前日高亮
- 选中日使用明显的玻璃圆点

### 7.9 转盘页

目标：
- 作为奖励玩法入口

规则：
- 中间开始按钮明确
- 周围奖品格固定 3x3 结构
- 抽奖中状态要清晰
- 抽奖结果通过系统提示或结果弹窗展示

---

## 8. 状态规范

### 8.1 空状态

适用：
- 今日无任务
- 动态为空
- 奖励为空
- 金币记录为空

要求：
- 图标 + 标题 + 说明 + 行动按钮
- 文案简短
- 不要空得像报错

### 8.2 加载态

适用：
- 首次进入
- 刷新中
- 数据同步中

要求：
- 页面主体可用骨架或轻量进度指示
- 不要让布局抖动
- 不要长时间只显示纯转圈

### 8.3 错误态

适用：
- 网络失败
- 拉取失败
- 兑换失败
- 上传失败

要求：
- 错误信息就近展示
- 给出重试路径
- 使用温和琥珀或珊瑚色，不要极端红色警报风

### 8.4 权限拒绝态

适用：
- 相册权限
- 相机权限
- 通知权限

要求：
- 解释用途
- 提供去系统设置入口
- 不循环弹窗骚扰

---

## 9. 文案规范

### 9.1 语言

- 界面默认中文
- 技术名词、API 名称、服务名保留英文原文

### 9.2 文案风格

- 短句优先
- 直接说明动作
- 少用感叹号
- 少用营销腔

### 9.3 推荐文案

- 登录
- 今日
- 动态
- 奖励
- 我的
- 创建任务
- 完成任务
- 选择照片
- 确认完成
- 重新加载
- 去设置

### 9.4 禁止项

- 注册入口
- 邀请码
- 绑定流程
- 微信登录
- 微信订阅消息
- 过度解释性的说明文案

---

## 10. 开发落地建议

### 10.1 SwiftUI 结构

建议按以下层次实现：

1. Design tokens
2. 通用玻璃组件
3. 页面级容器
4. 状态组件
5. 页面视图

### 10.2 组件优先级

优先抽象这些通用组件：

- `DLGlassCard`
- `DLGlassButton`
- `DLGlassBadge`
- `DLTaskRow`
- `DLErrorBanner`
- `DLEmptyState`
- `DLLoadingButton`
- `DLSectionHeader`

### 10.3 推荐状态管理

- 页面状态：loading / content / empty / error
- 表单状态：editing / submitting / failed
- 权限状态：unknown / granted / denied

### 10.4 动效建议

- 页面切换：标准 navigation transition
- 玻璃按钮：轻微 scale
- 日历展开：spring
- 完成任务弹窗：淡入淡出 + 轻微位移
- 转盘结果：短暂停顿后展示结果

---

## 11. 页面清单

当前建议覆盖：

- 登录页
- 今日页
- 动态页
- 奖励页
- 我的页
- 新建任务页
- 完成任务页
- 日历展开页
- 转盘页
- 空状态
- 加载态
- 错误态
- 权限拒绝态

---

## 12. 参考图路径

参考图用于确认整体氛围、布局密度和玻璃层级。开发时以本文档的文字规范和 SwiftUI 参数为准，图片中的小字不作为最终文案来源。

| 页面 / 状态 | 路径 |
|---|---|
| 登录页 | `UI/screens/01-login-liquid-glass.png` |
| 今日页 | `UI/screens/02-today-liquid-glass.png` |
| 动态页 | `UI/screens/03-feed-liquid-glass.png` |
| 奖励页 | `UI/screens/04-rewards-liquid-glass.png` |
| 我的页 | `UI/screens/05-profile-liquid-glass.png` |
| 新建任务页 | `UI/screens/06-create-task-generated-liquid-glass.png` |
| 完成任务页 | `UI/screens/06-task-complete-liquid-glass.png` |
| 日历展开页 | `UI/screens/07-calendar-expanded-liquid-glass.png` |
| 转盘抽奖页 | `UI/screens/08-spinwheel-liquid-glass.png` |
| 空状态 | `UI/screens/09-empty-state-liquid-glass.png` |
| 加载态 | `UI/screens/10-loading-state-liquid-glass.png` |
| 错误态 | `UI/screens/11-error-state-liquid-glass.png` |
| 权限拒绝态 | `UI/screens/12-permission-denied-liquid-glass.png` |
| 设计系统总览图 | `UI/system/dailylog-liquid-glass-overview.png` |

---

## 13. 可复现设计令牌

这一节用于直接指导 SwiftUI 实现。后续开发应优先把这些 token 落到 `DailyLog/DailyLog/Core/DesignSystem` 中，再在页面中复用。

### 13.1 颜色 Token

建议将当前 `Colors.swift` 从系统默认色扩展为 DailyLog 专用色板：

```swift
extension Color {
    static let dlLavender = Color(red: 142 / 255, green: 106 / 255, blue: 255 / 255)
    static let dlLavenderSoft = Color(red: 217 / 255, green: 208 / 255, blue: 255 / 255)
    static let dlLilac = Color(red: 238 / 255, green: 230 / 255, blue: 255 / 255)
    static let dlRoseMist = Color(red: 248 / 255, green: 221 / 255, blue: 244 / 255)
    static let dlPlum = Color(red: 182 / 255, green: 156 / 255, blue: 255 / 255)
    static let dlCoin = Color(red: 246 / 255, green: 201 / 255, blue: 72 / 255)
    static let dlSuccess = Color(red: 53 / 255, green: 200 / 255, blue: 137 / 255)
    static let dlWarning = Color(red: 255 / 255, green: 180 / 255, blue: 84 / 255)
    static let dlError = Color(red: 255 / 255, green: 127 / 255, blue: 155 / 255)
}
```

文字色建议：

```swift
extension Color {
    static let dlTextPrimary = Color(red: 39 / 255, green: 33 / 255, blue: 53 / 255)
    static let dlTextSecondary = Color(red: 95 / 255, green: 88 / 255, blue: 116 / 255)
}
```

### 13.2 背景 Token

所有主页面使用同一种背景，不要每个页面单独配色。

```swift
struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                .dlLilac,
                .dlRoseMist,
                .dlLavenderSoft
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 520, height: 520)
                .blur(radius: 56)
                .offset(x: -180, y: -160)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.dlLavender.opacity(0.22))
                .frame(width: 620, height: 620)
                .blur(radius: 70)
                .offset(x: 220, y: 260)
        }
        .ignoresSafeArea()
    }
}
```

### 13.3 间距 Token

沿用已有 `Spacing`，可补充页面边距：

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    static let screenHorizontal: CGFloat = 16
    static let section: CGFloat = 20
    static let cardInner: CGFloat = 16
}
```

### 13.4 圆角 Token

```swift
enum CornerRadius {
    static let control: CGFloat = 12
    static let smallCard: CGFloat = 16
    static let card: CGFloat = 20
    static let panel: CGFloat = 28
    static let modal: CGFloat = 34
    static let tabBar: CGFloat = 40
}
```

---

## 14. 可复现玻璃组件

### 14.1 标准玻璃卡片

用途：任务条、动态条、奖励条、统计卡。

```swift
struct DLGlassCard<Content: View>: View {
    let tint: Color?
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = CornerRadius.card,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.cardInner)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.28)) } ?? .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
```

### 14.2 主按钮

用途：登录、创建、确认完成、开始转盘。

```swift
struct DLPrimaryButton<Label: View>: View {
    let action: () -> Void
    let isDisabled: Bool
    @ViewBuilder var label: Label

    var body: some View {
        Button(action: action) {
            label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .disabled(isDisabled)
    }
}
```

### 14.3 次级按钮

用途：取消、选择照片、重新加载、去设置。

```swift
Button {
    // action
} label: {
    Label("重新加载", systemImage: "arrow.clockwise")
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
}
.buttonStyle(.glass)
```

### 14.4 金币徽标

```swift
HStack(spacing: Spacing.xs) {
    Image(systemName: "bitcoinsign.circle.fill")
        .foregroundStyle(Color.dlCoin)
    Text("\(coins)")
        .font(.subheadline.bold())
}
.padding(.horizontal, Spacing.sm)
.padding(.vertical, Spacing.xs)
.glassEffect(.regular.tint(Color.dlCoin.opacity(0.35)), in: .capsule)
```

### 14.5 错误提示条

```swift
HStack(spacing: Spacing.sm) {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(Color.dlWarning)
    Text(message)
        .font(.subheadline)
        .foregroundStyle(.primary)
}
.padding(Spacing.md)
.frame(maxWidth: .infinity, alignment: .leading)
.glassEffect(.regular.tint(Color.dlWarning.opacity(0.28)), in: .rect(cornerRadius: CornerRadius.control))
```

---

## 15. 页面落地参数

### 15.1 主 Tab 页面

所有主 Tab 页面结构统一：

```swift
ZStack {
    DLBackground()
    NavigationStack {
        ScrollView {
            VStack(spacing: Spacing.section) {
                // page content
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(pageTitle)
    }
}
```

### 15.2 今日页

参考图：`UI/screens/02-today-liquid-glass.png`

布局顺序：
1. 顶部金币徽标
2. 右上新建按钮
3. 周日历 / 月日历卡
4. 日任务
5. 周任务
6. 月任务

任务条参数：
- 高度：内容自适应，最小 64
- 圆角：16
- 内边距：水平 16，垂直 12
- 未完成图标：`circle`
- 已完成图标：`checkmark.circle.fill`
- 今日可完成：按钮启用
- 非今日或已完成：按钮禁用

### 15.3 动态页

参考图：`UI/screens/03-feed-liquid-glass.png`

动态条参数：
- 左侧图标容器：40x40 circle
- 主标题：`subheadline.weight(.medium)`
- 时间：`caption2`
- 卡片圆角：16
- 列表间距：8

图标映射：
- `task_complete`：`checkmark.circle.fill`，成功绿
- `reward_redeem`：`gift.fill`，金币色
- `spin_win`：`star.fill`，紫色
- 默认：`bell.fill`，淡蓝紫

### 15.4 奖励页

参考图：`UI/screens/04-rewards-liquid-glass.png`

布局顺序：
1. 余额卡
2. 转盘入口卡
3. 直接兑换列表

余额卡：
- tint：金币色 0.28
- 圆角：20
- 左侧金币 icon，右侧“我的余额”

转盘入口卡：
- tint：主紫 0.28
- 主按钮：`buttonStyle(.glass)`
- 不使用老虎机、赌场、强闪烁视觉

### 15.5 我的页

参考图：`UI/screens/05-profile-liquid-glass.png`

布局顺序：
1. 头像与昵称
2. 金币余额
3. 完成任务和连续打卡统计
4. 最近金币记录
5. 消息推送开关
6. 退出登录

头像：
- 尺寸：56x56
- 形状：circle
- 上传中覆盖 `ProgressView` + ultra thin material

### 15.6 新建任务页

参考图：`UI/screens/06-create-task-generated-liquid-glass.png`

优先使用系统 `Form`，但保留全局淡紫背景和玻璃提示。

表单字段：
- 任务标题：必填
- 备注：可选，多行 2-4
- 任务类型：日任务 / 周任务 / 月任务
- 任务日期
- 金币奖励：1-100

错误提示：
- 放在表单内就近位置
- 文案示例：`日任务最多同时存在5个待完成任务`

### 15.7 完成任务页

参考图：`UI/screens/06-task-complete-liquid-glass.png`

状态：
- 未选照片：显示上传占位卡
- 已选照片：显示图片预览
- 上传中：按钮禁用，显示进度
- 失败：保留照片和当前状态，显示错误提示

按钮：
- 选择照片：次级玻璃按钮
- 确认完成：主玻璃按钮

### 15.8 日历展开

参考图：`UI/screens/07-calendar-expanded-liquid-glass.png`

规则：
- 默认周视图
- 点击 chevron 展开月视图
- 当前日用金币色弱高亮
- 选中日用主紫或金币 tint 的 glass circle
- 月视图 grid 为 7 列

### 15.9 转盘抽奖

参考图：`UI/screens/08-spinwheel-liquid-glass.png`

规则：
- 3x3 grid
- 中心按钮为开始按钮
- 外圈 8 个奖品格
- 高亮态使用金币色 tint
- 抽奖中按钮禁用
- 抽奖结果通过系统 alert 或结果卡展示

---

## 16. 状态页落地参数

### 16.1 空状态

参考图：`UI/screens/09-empty-state-liquid-glass.png`

结构：
- 图标：`tray` 或页面语义图标
- 标题：一句话
- 说明：一句辅助说明
- 行动按钮：可选

文案示例：
- 今日无任务
- 还没有动态，快去完成任务吧
- 暂无可兑换奖励
- 还没有金币记录

### 16.2 加载态

参考图：`UI/screens/10-loading-state-liquid-glass.png`

规则：
- 首屏加载：可使用 `ProgressView`
- 列表加载：优先 skeleton rows
- 刷新加载：使用系统 `refreshable`
- 避免整页突然跳动

### 16.3 错误态

参考图：`UI/screens/11-error-state-liquid-glass.png`

规则：
- 错误提示就近出现
- 保留已加载内容，不要直接清空页面
- 重试按钮靠近错误信息
- 警告 tint 使用 `dlWarning.opacity(0.28)`

### 16.4 权限拒绝态

参考图：`UI/screens/12-permission-denied-liquid-glass.png`

适用：
- 相册
- 相机
- 通知

结构：
- 标题：需要相册权限 / 需要相机权限 / 需要通知权限
- 说明：解释用途
- 主按钮：去设置
- 次按钮：稍后再说

---

## 17. 设计系统总览文字版

设计系统总览图路径：`UI/system/dailylog-liquid-glass-overview.png`

总览应被理解为以下可复现规则：

1. 背景统一：淡紫三段渐变 + 柔光，不按页面改变主背景。
2. 玻璃分层：普通卡片 regular，强调卡 tinted，主操作 prominent。
3. 主色统一：主紫 `#8E6AFF`，辅助浅紫 `#D9D0FF`，金币色 `#F6C948`。
4. 页面密度：主页面保持可扫描，不做大面积营销 hero。
5. 卡片圆角：小控件 12-16，标准卡片 20，面板 28-34，底部栏 40+。
6. 字体层级：标题 24-32，正文 16-18，辅助 12-14。
7. 状态完整：每个列表页必须有 loading / empty / error。
8. 权限友好：解释用途，不做反复弹窗。
9. 动效克制：玻璃按钮轻微缩放，日历展开使用 spring，转盘高亮不强闪。
10. 文案中文：用户可见文案默认中文，不添加注册、邀请码、微信能力。

---

## 18. 备注

- 本规范优先适配当前 DailyLog MVP
- 不包含微信小程序能力
- 不包含情侣邀请、邀请码、注册流程
- 不包含 APNs 第一阶段实现
- 视觉上参考 iOS 26 Liquid Glass，但可用性优先
