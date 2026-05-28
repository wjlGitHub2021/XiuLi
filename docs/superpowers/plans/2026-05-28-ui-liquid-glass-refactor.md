# DailyLog UI Liquid Glass 重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 DailyLog iOS App 的视觉层全面改为 `UI/system/dailylog-liquid-glass-design-system.md` 描述的 iOS 26 Liquid Glass 风格（淡紫渐变 + 玻璃材质 + 金币色强调），不动 Service / Model / Supabase 任何逻辑。

**Architecture:**
1. 自下而上：先 design tokens（Colors / Spacing / CornerRadius）→ 再共用玻璃组件（DLBackground / DLGlassCard / DLPrimaryButton / DLGlassBadge / DLSectionHeader）→ 然后逐个页面切换到新 tokens 和组件。
2. 每个页面对照 `UI/screens/XX-*.png` 参考图调样式，**只改 View 层的视觉属性**：颜色、圆角、间距、玻璃 tint、字号、布局。已有的 `@State`、handler、`async` 数据流保持不变。
3. 状态屏（empty / loading / error / permission denied）抽到通用组件，应用到各页面已有的空/错状态分支上。

**Tech Stack:** SwiftUI（iOS 26.0 部署目标）、`glassEffect` / `buttonStyle(.glass[Prominent])` / `GlassEffectContainer`、supabase-swift 2.46.0（不动）。

**重要约束：**
- 不动 `Core/Services/`、`Core/Models/`、`Core/Supabase/`、`App/AppState.swift`。
- 每个 Task 完成后 `cd DailyLog && xcodebuild ... build` 必须 exit 0。
- 不写单元测试；UI 重构的"测试"是编译通过 + 对照参考图视觉验证 + 最终 QA 子 agent 端到端走一遍。
- 文件已经在 `xcodegen` `sources: - DailyLog` 路径下，新增 `.swift` 在子目录里**不需要**重新 `xcodegen generate`（除非用户主动让你跑）。
- 工作目录：`/Users/wangjinlong/ai_app_VibeCoding_study/XiuLi/.claude/worktrees/ui+liquid-glass`，分支 `worktree-ui+liquid-glass`。

---

## Phase 1 · 基础层

### Task 1: Design tokens（Colors / Spacing / CornerRadius）

**Files:**
- Modify: `DailyLog/DailyLog/Core/DesignSystem/Colors.swift`（完全重写）
- Modify: `DailyLog/DailyLog/Core/DesignSystem/Spacing.swift`（追加常量）
- Create: `DailyLog/DailyLog/Core/DesignSystem/CornerRadius.swift`

- [ ] **Step 1: 重写 Colors.swift**

完全替换文件内容为：

```swift
import SwiftUI

extension Color {
    // 主色板
    static let dlLavender = Color(red: 142 / 255, green: 106 / 255, blue: 255 / 255)
    static let dlLavenderSoft = Color(red: 217 / 255, green: 208 / 255, blue: 255 / 255)
    static let dlLilac = Color(red: 238 / 255, green: 230 / 255, blue: 255 / 255)
    static let dlRoseMist = Color(red: 248 / 255, green: 221 / 255, blue: 244 / 255)
    static let dlPlum = Color(red: 182 / 255, green: 156 / 255, blue: 255 / 255)

    // 功能色
    static let dlCoin = Color(red: 246 / 255, green: 201 / 255, blue: 72 / 255)
    static let dlSuccess = Color(red: 53 / 255, green: 200 / 255, blue: 137 / 255)
    static let dlWarning = Color(red: 255 / 255, green: 180 / 255, blue: 84 / 255)
    static let dlError = Color(red: 255 / 255, green: 127 / 255, blue: 155 / 255)

    // 文字色
    static let dlTextPrimary = Color(red: 39 / 255, green: 33 / 255, blue: 53 / 255)
    static let dlTextSecondary = Color(red: 95 / 255, green: 88 / 255, blue: 116 / 255)

    // 向后兼容别名：保持旧代码不破（待 Task 4-11 改完后清理）
    static let dlPrimary = dlLavender
    static let dlSecondary = dlTextSecondary
    static let dlBackground = Color(.systemGroupedBackground)
    static let dlCardBackground = Color(.secondarySystemGroupedBackground)
}
```

理由：现有代码（FeedItemView、TaskRowView 等）已经用了 `Color.dlCoin`、`Color.dlPrimary` 这些 token，必须保持别名直到所有页面都改完。

- [ ] **Step 2: 扩展 Spacing.swift**

完全替换文件内容为：

```swift
import Foundation

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    // 页面布局专用
    static let screenHorizontal: CGFloat = 16
    static let section: CGFloat = 20
    static let cardInner: CGFloat = 16
}
```

- [ ] **Step 3: 新建 CornerRadius.swift**

创建新文件，内容：

```swift
import Foundation

enum CornerRadius {
    static let control: CGFloat = 12
    static let smallCard: CGFloat = 16
    static let card: CGFloat = 20
    static let panel: CGFloat = 28
    static let modal: CGFloat = 34
    static let tabBar: CGFloat = 40
}
```

- [ ] **Step 4: 编译验证**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
```
Expected: exit code 0，无 error。warning 关于"never used"是 OK 的。

- [ ] **Step 5: Commit**

```bash
git add DailyLog/DailyLog/Core/DesignSystem/
git commit -m "feat(ui): add liquid-glass design tokens (Colors/Spacing/CornerRadius)"
```

---

### Task 2: 共用玻璃组件 + DLBackground

**Files:**
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLBackground.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLGlassCard.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLPrimaryButton.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLGlassBadge.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLSectionHeader.swift`
- Modify: `DailyLog/DailyLog/Core/DesignSystem/Components.swift`（restyle DLErrorBanner + DLLoadingButton；DLEmptyState 留给 Task 12 重做）

- [ ] **Step 1: DLBackground.swift**

```swift
import SwiftUI

/// 全局淡紫三段渐变背景，所有主页面和 sheet 共用。
struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.dlLilac, .dlRoseMist, .dlLavenderSoft],
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

- [ ] **Step 2: DLGlassCard.swift**

```swift
import SwiftUI

/// 标准玻璃卡片容器。`tint` 给 nil 用 regular，给颜色用 tinted。
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

- [ ] **Step 3: DLPrimaryButton.swift**

```swift
import SwiftUI

/// 主按钮：登录、创建、确认完成、开始转盘。
struct DLPrimaryButton<Label: View>: View {
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    label()
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .disabled(isDisabled || isLoading)
    }
}
```

- [ ] **Step 4: DLGlassBadge.swift**

```swift
import SwiftUI

/// 金币徽标 / capsule 状态徽标。
struct DLGlassBadge: View {
    let icon: String
    let text: String
    var tint: Color = .dlCoin

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .glassEffect(.regular.tint(tint.opacity(0.35)), in: .capsule)
    }
}
```

- [ ] **Step 5: DLSectionHeader.swift**

```swift
import SwiftUI

/// 分组标题，例如"日任务" / "最近金币记录"。
struct DLSectionHeader: View {
    let icon: String?
    let title: String

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.dlPlum)
            }
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.dlTextSecondary)
        }
        .padding(.horizontal, Spacing.xs)
    }
}
```

- [ ] **Step 6: 改 Components.swift 里的 DLErrorBanner**

把 `DLErrorBanner` 整段替换为：

```swift
struct DLErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.dlWarning)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.dlTextPrimary)
            }
            if let onRetry {
                Button(action: onRetry) {
                    Label("重新加载", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.dlWarning.opacity(0.28)),
                     in: .rect(cornerRadius: CornerRadius.control))
    }
}
```

注意：增加可选 `onRetry` 闭包，使老调用点 `DLErrorBanner(message:)` 仍然 compile。

- [ ] **Step 7: DLLoadingButton 保持兼容但改 token**

把 `DLLoadingButton` 内的 `.padding(.vertical, 14)` 保持不变，但**不动接口**，因为有调用方。文件其它内容不动。

- [ ] **Step 8: 编译验证**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
```
Expected: exit 0。

- [ ] **Step 9: Commit**

```bash
git add DailyLog/DailyLog/Core/DesignSystem/
git commit -m "feat(ui): add shared liquid-glass components (DLBackground/DLGlassCard/DLPrimaryButton/DLGlassBadge/DLSectionHeader); restyle DLErrorBanner"
```

---

### Task 3: MainTabView 玻璃 Tab 栏

**Files:**
- Modify: `DailyLog/DailyLog/App/MainTabView.swift`

参考图：`UI/screens/02-today-liquid-glass.png` 底部，4 tab 玻璃 capsule + 紫色选中态。

- [ ] **Step 1: 重写 MainTabView**

替换文件内容：

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "checkmark.circle") }
            FeedView()
                .tabItem { Label("动态", systemImage: "chart.bar") }
            RewardsView()
                .tabItem { Label("奖励", systemImage: "gift") }
            ProfileView()
                .tabItem { Label("我的", systemImage: "person") }
        }
        .tint(.dlLavender)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
```
Expected: exit 0。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/App/MainTabView.swift
git commit -m "feat(ui): apply lavender tint + glass material to MainTabView tab bar"
```

---

## Phase 2 · 逐页应用

> Phase 2 的每个 Task 模板：
> 1. 在页面最外层套 `ZStack { DLBackground(); /* 原 NavigationStack */ }`
> 2. `.scrollContentBackground(.hidden)` 让 ScrollView/Form 透出 DLBackground
> 3. 替换所有 `.glassEffect(.regular.tint(.yellow))` 这类系统色为 `Color.dlXxx`
> 4. 替换 magic number 圆角为 `CornerRadius.xxx`
> 5. 用新组件（DLGlassBadge、DLGlassCard、DLPrimaryButton、DLSectionHeader）替换重复 inline 实现
> 6. 不动 `@State`、`async` handler、数据流

### Task 4: LoginView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Login/LoginView.swift`

参考图：`UI/screens/01-login-liquid-glass.png`

要点：
- 移除当前蓝/紫/橙渐变背景，改用 `DLBackground()`
- 顶部加一个紫色玻璃 logo 卡片（圆角 24，紫色 tint），里面放 `Image(systemName: "checkmark.circle.fill")`，36pt，紫色
- "DailyLog" 标题 `.largeTitle.bold()`，文字色 `.dlTextPrimary`
- 副标题 `.subheadline` 文字色 `.dlTextSecondary`
- 邮箱/密码输入框：玻璃 capsule（圆角 `CornerRadius.control = 12`，水平 16 垂直 12 padding）；左侧加 SF Symbol（`envelope` / `lock`），右侧密码框保留眼睛切换按钮
- 登录按钮换成 `DLPrimaryButton`，`isLoading: isLoading`，label `Text("登录")`，圆角自然由 glassProminent 处理（外层包一层 `Capsule` 形状）
- 整体垂直 spacer 上 30%，下 30%

- [ ] **Step 1: 重写整个 body 部分（保持登录逻辑函数 `login()` / `mapError()` 原样）**

```swift
var body: some View {
    ZStack {
        DLBackground()

        VStack(spacing: Spacing.lg) {
            Spacer()

            // Logo 卡片
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .frame(width: 88, height: 88)
                    .glassEffect(.regular.tint(Color.dlLavender.opacity(0.32)),
                                 in: .rect(cornerRadius: 24))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.dlLavender)
            }
            .frame(width: 88, height: 88)

            Text("DailyLog")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.dlTextPrimary)

            Text("每日打卡，积累金币")
                .font(.subheadline)
                .foregroundStyle(Color.dlTextSecondary)

            // 输入框组
            GlassEffectContainer(spacing: 12.0) {
                VStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope")
                            .foregroundStyle(Color.dlTextSecondary)
                        TextField("邮箱", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .capsule)

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "lock")
                            .foregroundStyle(Color.dlTextSecondary)
                        Group {
                            if isPasswordVisible {
                                TextField("密码", text: $password)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("密码", text: $password)
                                    .textContentType(.password)
                            }
                        }
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .onSubmit { Task { await login() } }

                        Button {
                            let wasFocused = focusedField == .password
                            isPasswordVisible.toggle()
                            if wasFocused {
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(50))
                                    focusedField = .password
                                }
                            }
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(Color.dlTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .capsule)
                }
            }

            if let errorMessage {
                DLErrorBanner(message: errorMessage)
            }

            DLPrimaryButton(
                action: { Task { await login() } },
                isLoading: isLoading,
                isDisabled: email.isEmpty || password.isEmpty
            ) {
                Text("登录")
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
    .onTapGesture {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
```

注意：`login()` 和 `mapError(_:)` 两个私有函数原样保留，不动。

- [ ] **Step 2: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
```
Expected: exit 0。

```bash
git add DailyLog/DailyLog/Features/Login/LoginView.swift
git commit -m "feat(ui): restyle LoginView to liquid glass spec"
```

---

### Task 5: TodayView + CalendarView + TaskRowView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Today/TodayView.swift`
- Modify: `DailyLog/DailyLog/Features/Today/CalendarView.swift`
- Modify: `DailyLog/DailyLog/Features/Today/TaskRowView.swift`

参考图：`UI/screens/02-today-liquid-glass.png` (周历) + `UI/screens/07-calendar-expanded-liquid-glass.png` (月历)

要点：
- TodayView 外层套 `ZStack { DLBackground(); NavigationStack {...} }`，ScrollView 加 `.scrollContentBackground(.hidden)`
- 顶栏金币徽标用 `DLGlassBadge(icon: "bitcoinsign.circle.fill", text: "\(user.coins)", tint: .dlCoin)`
- 右上"创建任务"按钮：`Image(systemName: "plus")` `.buttonStyle(.glass)` capsule 包一下
- CalendarView：
  - 容器圆角改 `CornerRadius.card = 20`
  - 选中日 tint 改 `Color.dlLavender`（从 `Color.dlCoin` 换掉），今日高亮保持金币色但用 `Color.dlCoin.opacity(0.4)`
  - header 月份字体 `.headline` 颜色 `.dlTextPrimary`
  - 周标签字 `.dlTextSecondary`
  - 选中日文字色：`Color.white`；今日（未选）：`Color.dlCoin`；当月其他：`Color.dlTextPrimary`；非当月：`Color.dlTextPrimary.opacity(0.3)`
- TaskRowView：
  - 完成圆圈未完成态用 `Color.dlLavender`，已完成 `Color.dlSuccess`（已经是 `.green` 改成 dlSuccess）
  - 金币 `+\(coins)` 已完成时 `.dlTextSecondary`，未完成 `.dlCoin`
  - 任务图标可选：根据 task type 选一个 SF Symbol 放在标题左前（参考图里 daily 任务有 sunrise/drop 图标）。**不增加 Model 字段，按 `task.taskType` 临时映射**：daily → `sun.max`、weekly → `calendar.badge.checkmark`、monthly → `chart.line.uptrend.xyaxis`
  - 行高保持自适应，内 padding `vertical 12 horizontal 16`
- taskSection 标题用 `DLSectionHeader("日任务", icon: "sun.max")` 等

- [ ] **Step 1: 改 CalendarView**

把 `dayCell` 内的 `.glassEffect(.regular.tint(Color.dlCoin), in: .circle)` 换成 `.glassEffect(.regular.tint(Color.dlLavender), in: .circle)`，今日态 tint 换成 `Color.dlCoin.opacity(0.4)`。

文字色块：
```swift
.foregroundStyle(
    isSelected ? Color.white :
    isToday ? Color.dlCoin :
    isCurrentMonth ? Color.dlTextPrimary : Color.dlTextPrimary.opacity(0.3)
)
```

外层容器圆角改 `CornerRadius.card`。

- [ ] **Step 2: 改 TaskRowView**

完整内容替换为：

```swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isToday: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            taskIcon
                .frame(width: 40, height: 40)
                .glassEffect(.regular.tint(Color.dlLavender.opacity(0.22)),
                             in: .circle)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.dlTextSecondary : Color.dlTextPrimary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(Color.dlCoin)
                Text("+\(task.coinsEarned)")
                    .font(.subheadline.bold())
                    .foregroundStyle(task.isCompleted ? Color.dlTextSecondary : Color.dlCoin)
            }

            Button(action: {
                guard !task.isCompleted && isToday else { return }
                onComplete()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? Color.dlSuccess
                                                       : (isToday ? Color.dlLavender : Color.dlTextSecondary))
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted || !isToday)
            .accessibilityLabel(task.isCompleted ? "已完成" : (isToday ? "标记为完成" : "只能完成今日任务"))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    @ViewBuilder
    private var taskIcon: some View {
        let symbol: String = {
            switch task.taskType {
            case .daily:   return "sun.max.fill"
            case .weekly:  return "calendar.badge.checkmark"
            case .monthly: return "chart.line.uptrend.xyaxis"
            }
        }()
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.dlLavender)
    }
}
```

注意：参考图把 icon 放在最左、完成按钮在最右；这里调整了顺序。原始 onComplete 闭包行为不变。

- [ ] **Step 3: 改 TodayView body**

把 `body` 整段替换为：

```swift
var body: some View {
    ZStack {
        DLBackground()
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    CalendarView(selectedDate: $selectedDate)

                    if let errorMessage {
                        DLErrorBanner(message: errorMessage)
                            .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    if isLoading && allTasksEmpty {
                        ProgressView()
                            .padding(.top, 100)
                    } else if allTasksEmpty {
                        DLEmptyState(
                            icon: "tray",
                            title: Calendar.current.isDateInToday(selectedDate) ? "今日无任务" : "该日无任务",
                            subtitle: "新建一个任务开始打卡",
                            actionTitle: "新建任务",
                            action: { showCreateSheet = true }
                        )
                        .padding(.horizontal, Spacing.screenHorizontal)
                    } else {
                        taskSections
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .scrollContentBackground(.hidden)
            .refreshable { await loadAllTasks() }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { coinBadge }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTaskSheet(taskType: .daily) { newTask in
                    switch newTask.taskType {
                    case .daily: dailyTasks.insert(newTask, at: 0)
                    case .weekly: weeklyTasks.insert(newTask, at: 0)
                    case .monthly: monthlyTasks.insert(newTask, at: 0)
                    }
                }
                .environment(appState)
            }
            .sheet(item: $taskToComplete) { task in
                TaskCompleteSheet(task: task) { completedTask in
                    updateTask(completedTask)
                    Task { await appState.refreshProfile() }
                }
            }
        }
    }
    .task(id: selectedDate) { await loadAllTasks() }
}
```

注意：`DLEmptyState` 新签名（icon/title/subtitle/actionTitle/action）会在 Task 12 里实现。Task 5 实施时如果还没到 Task 12，**先临时用旧 `DLEmptyState(message:)` 接口**，并在 PR 描述里 mark TODO。或在 Task 5 之前确认 Task 12 已合并（更稳）。

**实施顺序建议**：调度时把 Task 12（状态屏组件）放在 Task 5 之前执行。如果按本文档顺序走，Task 5 里这里先写成：

```swift
DLEmptyState(message: Calendar.current.isDateInToday(selectedDate) ? "今日无任务" : "该日无任务")
    .padding(.horizontal, Spacing.screenHorizontal)
```

到 Task 13 再统一加 CTA。**此 Plan 默认按顺序，所以用旧签名版本，并在每页 Task 里同样处理。**

- [ ] **Step 4: 改 coinBadge / taskSections**

```swift
@ViewBuilder
private var coinBadge: some View {
    if let user = appState.currentUser {
        DLGlassBadge(icon: "bitcoinsign.circle.fill",
                     text: "\(user.coins)",
                     tint: .dlCoin)
    }
}

private var taskSections: some View {
    GlassEffectContainer(spacing: 8.0) {
        VStack(spacing: Spacing.md) {
            if !dailyTasks.isEmpty {
                taskSection(title: "日任务", icon: "sun.max", tasks: dailyTasks, type: .daily)
            }
            if !weeklyTasks.isEmpty {
                taskSection(title: "周任务", icon: "calendar", tasks: weeklyTasks, type: .weekly)
            }
            if !monthlyTasks.isEmpty {
                taskSection(title: "月任务", icon: "chart.bar", tasks: monthlyTasks, type: .monthly)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

@ViewBuilder
private func taskSection(title: String, icon: String, tasks: [TaskItem], type: TaskType) -> some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        DLSectionHeader(title, icon: icon)
        ForEach(tasks) { task in
            TaskRowView(task: task, isToday: isToday) {
                taskToComplete = task
            }
            .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
        }
    }
}
```

- [ ] **Step 5: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
git add DailyLog/DailyLog/Features/Today/
git commit -m "feat(ui): restyle Today/Calendar/TaskRow to liquid glass spec"
```

---

### Task 6: FeedView + FeedItemView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Feed/FeedView.swift`
- Modify: `DailyLog/DailyLog/Features/Feed/FeedItemView.swift`

参考图：`UI/screens/03-feed-liquid-glass.png`

要点：
- FeedView 外层 `ZStack { DLBackground(); NavigationStack {...} }`，ScrollView `.scrollContentBackground(.hidden)`
- 移除 `feedErrorBanner(message:)` 这个内嵌实现，统一用 `DLErrorBanner(message:)`
- `feedList` 内每条 `.glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))`
- FeedItemView：
  - icon 容器：40×40 `Circle().fill(iconColor.opacity(0.18))`
  - icon 颜色映射：
    - `task_complete` → `Color.dlSuccess`
    - `reward_redeem` → `Color.dlCoin`
    - `spin_win` → `Color.dlLavender`
    - default → `Color.dlPlum`
  - 标题字 `.subheadline.weight(.medium)` 色 `.dlTextPrimary`
  - 时间字 `.caption2` 色 `.dlTextSecondary`
  - 右侧加金币数：从 message 里读 `coinsDelta` 或类似字段。**Model 不动，如果当前没有这个字段，跳过这个右侧金币的展示**——保持当前布局结构。让 implementer 先看 `FeedMessage.swift` 决定。
- 列表间距 `Spacing.sm`

- [ ] **Step 1: 先读 `Core/Models/FeedMessage.swift`，确认有无 amount/coin 字段。**

如果有 amount/coinDelta：右侧显示 `+10 / -30 / +20` 用 dlCoin 色 capsule。
如果没有：保持当前布局，不强行添加。

- [ ] **Step 2: 改 FeedItemView**

iconColor 映射换 dl token，icon 容器换成 `.fill(iconColor.opacity(0.18))`，文字色统一 dlTextPrimary/dlTextSecondary。

- [ ] **Step 3: 改 FeedView**

```swift
var body: some View {
    ZStack {
        DLBackground()
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let errorMessage {
                        DLErrorBanner(message: errorMessage)
                            .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    if isLoading && messages.isEmpty {
                        ProgressView()
                            .padding(.top, 100)
                    } else if messages.isEmpty {
                        DLEmptyState(message: "还没有动态，快去完成任务吧")
                    } else {
                        feedList
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .scrollContentBackground(.hidden)
            .refreshable { await loadFeed() }
            .navigationTitle("动态")
        }
    }
    .task { await loadFeed() }
}
```

删除 `feedErrorBanner(message:)` 整个函数。

- [ ] **Step 4: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
git add DailyLog/DailyLog/Features/Feed/
git commit -m "feat(ui): restyle Feed/FeedItem to liquid glass spec"
```

---

### Task 7: RewardsView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Rewards/RewardsView.swift`

参考图：`UI/screens/04-rewards-liquid-glass.png`

要点：
- 外层 `ZStack { DLBackground(); NavigationStack {...} }`
- 余额头部 tint 改 `Color.dlCoin`（已是 `.yellow`，换 dlCoin token），圆角 `CornerRadius.card`
- 转盘入口卡 tint 改 `Color.dlLavender`（当前是 `.purple`），圆角 `CornerRadius.card`，"开始转盘"按钮换 `DLPrimaryButton` 或保留 `.buttonStyle(.glass)`+ 紫色 tint
- 直接兑换列表：每行用 `DLGlassCard` 包，或直接 `.glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))`
- "兑换" 按钮保持 `.buttonStyle(.glass)`
- `DLSectionHeader("直接兑换", icon: "gift")` 替换内联标题

- [ ] **Step 1: body 外层包装 + scrollContentBackground**
- [ ] **Step 2: coinBalanceHeader / spinWheelCard tint 替换为 dl token**
- [ ] **Step 3: directRewardsSection 用 DLSectionHeader 替换标题**
- [ ] **Step 4: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
git add DailyLog/DailyLog/Features/Rewards/RewardsView.swift
git commit -m "feat(ui): restyle RewardsView to liquid glass spec"
```

---

### Task 8: SpinWheelView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Rewards/SpinWheelView.swift`

参考图：`UI/screens/08-spinwheel-liquid-glass.png`

要点：
- 外层 `ZStack { DLBackground(); ScrollView {...} }`
- 顶部余额条 tint 改 `Color.dlCoin`，圆角 `CornerRadius.smallCard`
- 转盘外圈 cell 高亮态 tint 改 `Color.dlCoin`，未高亮 `regular`，圆角 `CornerRadius.control`
- 中心开始按钮：放大、玻璃 prominent、tint dlLavender，"开始" 字体 `.title3.bold()`
- 整个 3×3 grid 外圈包 `glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.card))`
- 结果展示保持 `.alert`

- [ ] **Step 1: 外层 ZStack + DLBackground**
- [ ] **Step 2: coinCostHeader tint 替换**
- [ ] **Step 3: startButton 加 `.glassEffect(.regular.tint(Color.dlLavender.opacity(0.4)), in: .rect(cornerRadius: CornerRadius.control))` 或用 `.buttonStyle(.glassProminent)`**
- [ ] **Step 4: rewardCell 高亮 tint dlCoin**
- [ ] **Step 5: 编译 + Commit**

```bash
git add DailyLog/DailyLog/Features/Rewards/SpinWheelView.swift
git commit -m "feat(ui): restyle SpinWheelView to liquid glass spec"
```

---

### Task 9: ProfileView

**Files:**
- Modify: `DailyLog/DailyLog/Features/Profile/ProfileView.swift`

参考图：`UI/screens/05-profile-liquid-glass.png`

要点：
- 外层 `ZStack { DLBackground(); NavigationStack {...} }`，ScrollView `.scrollContentBackground(.hidden)`
- profileHeader tint 改 `Color.dlLavender`（当前 `.blue`），圆角 `CornerRadius.card`
- statsSection 改成两列 grid：完成任务（图标 checkmark + dlSuccess）和连续打卡（图标 flame + dlWarning），同一玻璃卡里
- 最近金币记录区每行：左 icon 容器（`完成任务` → checkmark/dlSuccess；`兑换奖励` → gift/dlError），右金额 + dlCoin/dlError 文字
- settingsSection 推送开关行：图标 bell + dlLavender，tint `Color.dlLavender.opacity(0.18)`
- 退出登录按钮：`.glassEffect(.regular.tint(Color.dlError.opacity(0.28)), in: .rect(cornerRadius: CornerRadius.smallCard))`，文字 `Color.dlError`

- [ ] **Step 1: body 外层 ZStack**
- [ ] **Step 2: profileHeader tint dlLavender**
- [ ] **Step 3: statsSection 改为 HStack 两列，各带图标 + 数值**
- [ ] **Step 4: transactionsSection 用 DLSectionHeader，行内加 icon 容器**
- [ ] **Step 5: settingsSection 推送行 + 退出登录 tint 替换**
- [ ] **Step 6: 编译 + Commit**

```bash
git add DailyLog/DailyLog/Features/Profile/ProfileView.swift
git commit -m "feat(ui): restyle ProfileView to liquid glass spec"
```

---

### Task 10: CreateTaskSheet

**Files:**
- Modify: `DailyLog/DailyLog/Features/Today/CreateTaskSheet.swift`

参考图：规范文字描述 §15.6（系统 `Form` + 玻璃背景）。无独立参考图。

要点：
- 用 `ZStack { DLBackground(); NavigationStack { Form {...} } }`
- `Form` 加 `.scrollContentBackground(.hidden)`
- `Section` header 用 dlTextSecondary 字色（系统 Form 自动处理，只是确认）
- 错误提示 section 里继续用 `DLErrorBanner`
- 工具栏"创建"按钮在 `confirmationAction` 上，加 `.tint(Color.dlLavender)`

- [ ] **Step 1: body 外层 ZStack + DLBackground**
- [ ] **Step 2: Form `.scrollContentBackground(.hidden)`**
- [ ] **Step 3: 工具栏 tint**
- [ ] **Step 4: 编译 + Commit**

```bash
git add DailyLog/DailyLog/Features/Today/CreateTaskSheet.swift
git commit -m "feat(ui): apply liquid glass background to CreateTaskSheet"
```

---

### Task 11: TaskCompleteSheet

**Files:**
- Modify: `DailyLog/DailyLog/Features/Today/TaskCompleteSheet.swift`

参考图：`UI/screens/06-task-complete-liquid-glass.png`

要点：
- 外层 `ZStack { DLBackground(); NavigationStack {...} }`
- 顶部任务信息条：用 `DLGlassCard` 包，左侧 icon 圆容器 + dlLavender，右侧 X 关闭按钮（toolbar 已有"取消"，可只保留 toolbar 的 X）
- 上传占位卡：玻璃卡 + 紫色相机图标 + "还没有照片"
- "选择照片"按钮：`.buttonStyle(.glass)` 不要 `glassProminent`
- "确认完成"按钮：`DLPrimaryButton`，`isLoading: isUploading`，`isDisabled: selectedImage == nil`
- 错误提示用 `DLErrorBanner`
- 移除底部 ConfirmationDialog 之外的内嵌"拍照 / 从相册选择"按钮（如果存在）

- [ ] **Step 1: body ZStack + DLBackground**
- [ ] **Step 2: 上传占位卡换 glassEffect tint dlLavender 0.18**
- [ ] **Step 3: 确认完成按钮换 DLPrimaryButton**
- [ ] **Step 4: 编译 + Commit**

```bash
git add DailyLog/DailyLog/Features/Today/TaskCompleteSheet.swift
git commit -m "feat(ui): restyle TaskCompleteSheet to liquid glass spec"
```

---

## Phase 3 · 状态屏

### Task 12: 丰富 DLEmptyState + 加 DLSkeletonRow / DLPermissionDeniedView

**Files:**
- Modify: `DailyLog/DailyLog/Core/DesignSystem/Components.swift`（重写 DLEmptyState）
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLSkeletonRow.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/DLPermissionDeniedView.swift`

参考图：`UI/screens/09-empty-state-liquid-glass.png`、`10-loading-state-liquid-glass.png`、`12-permission-denied-liquid-glass.png`

- [ ] **Step 1: 重写 DLEmptyState（保留旧 init 签名以保兼容）**

```swift
struct DLEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String = "tray",
         title: String,
         subtitle: String? = nil,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    // 兼容旧调用 DLEmptyState(message:)
    init(message: String) {
        self.init(icon: "tray", title: message, subtitle: nil, actionTitle: nil, action: nil)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dlLavender.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.dlLavender)
            }
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.dlTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.dlTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.dlLavender)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.panel))
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.lg)
    }
}
```

- [ ] **Step 2: DLSkeletonRow.swift**

```swift
import SwiftUI

/// 列表骨架行，用于首屏加载态。
struct DLSkeletonRow: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Capsule()
                    .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                    .frame(height: 14)
                    .frame(maxWidth: 160)
                Capsule()
                    .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                    .frame(height: 10)
                    .frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
```

- [ ] **Step 3: DLPermissionDeniedView.swift**

```swift
import SwiftUI
import UIKit

struct DLPermissionDeniedView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onLater: (() -> Void)?

    init(icon: String = "photo.on.rectangle",
         title: String,
         subtitle: String,
         onLater: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.onLater = onLater
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dlLavender.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.dlLavender)
            }
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.dlTextPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: Spacing.sm) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("去设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.dlLavender)

                if let onLater {
                    Button("稍后再说", action: onLater)
                        .buttonStyle(.glass)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.panel))
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}
```

- [ ] **Step 4: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
git add DailyLog/DailyLog/Core/DesignSystem/
git commit -m "feat(ui): rich DLEmptyState + add DLSkeletonRow & DLPermissionDeniedView"
```

---

### Task 13: 应用富空状态/骨架到各页面

**Files:**
- Modify: `DailyLog/DailyLog/Features/Today/TodayView.swift`（empty CTA）
- Modify: `DailyLog/DailyLog/Features/Feed/FeedView.swift`（empty subtitle）
- Modify: `DailyLog/DailyLog/Features/Profile/ProfileView.swift`（transactions empty）
- Modify: `DailyLog/DailyLog/Features/Rewards/RewardsView.swift`（rewards empty）

- [ ] **Step 1: TodayView 空状态加 CTA**

把 `allTasksEmpty` 分支换成：

```swift
DLEmptyState(
    icon: "tray",
    title: Calendar.current.isDateInToday(selectedDate) ? "今日无任务" : "该日无任务",
    subtitle: Calendar.current.isDateInToday(selectedDate) ? "今天还没有安排任务" : nil,
    actionTitle: Calendar.current.isDateInToday(selectedDate) ? "新建任务" : nil,
    action: Calendar.current.isDateInToday(selectedDate) ? { showCreateSheet = true } : nil
)
```

- [ ] **Step 2: FeedView 空状态加 subtitle**

```swift
DLEmptyState(
    icon: "bubble.left.and.bubble.right",
    title: "还没有动态",
    subtitle: "快去完成任务吧"
)
```

- [ ] **Step 3: ProfileView transactionsSection 空状态**

把现有 `if transactions.isEmpty` 分支替换为：

```swift
DLEmptyState(
    icon: "list.bullet.rectangle",
    title: "还没有金币记录",
    subtitle: nil
)
```
（移除原 inline `Text("还没有金币记录")` + glassEffect 包装）

- [ ] **Step 4: RewardsView directRewards 空状态**

```swift
DLEmptyState(
    icon: "gift",
    title: "暂无可兑换奖励"
)
```
（移除原 inline `Text("暂无可兑换奖励")` 实现）

- [ ] **Step 5: 编译 + Commit**

```bash
cd DailyLog && xcodebuild -project DailyLog.xcodeproj -scheme DailyLog -destination 'generic/platform=iOS Simulator' -quiet build
git add DailyLog/DailyLog/Features/
git commit -m "feat(ui): apply rich empty states across views"
```

---

## Phase 4 · 最终验证

### Task 14: QA 子 agent 端到端测试

**Files:** 无文件修改。

派一个 Claude Sonnet 子 agent，给它当前分支 diff 摘要 + 所有页面参考图路径，要求：
- 编译验证（必须 exit 0）
- 用 `xcrun simctl` 在模拟器跑起来
- 逐页对照参考图，列出明显视觉偏差和 bug（玻璃糊掉、文字不可读、按钮失效、布局错位等）
- 列出所有 console warning
- 报告里**只列问题不修复**，由主 agent 决定怎么处理

- [ ] **Step 1: 主 agent 调度 QA 子 agent，prompt 见 subagent-driven-development 章节描述**
- [ ] **Step 2: 拿到报告后过滤问题**
- [ ] **Step 3: 关键问题修掉，commit**

### Task 15: 收尾

- [ ] **Step 1: 跑最后一次 xcodebuild verify**
- [ ] **Step 2: `git log --oneline main..HEAD` 看 commit 数和 message**
- [ ] **Step 3: 调用 `superpowers:finishing-a-development-branch` 决定合并路径**
- [ ] **Step 4: 把工作总结一下报告给用户，等他做端到端手测**

---

## Self-Review Notes

- 所有 token 改动通过别名（`dlPrimary = dlLavender` 等）保证旧调用点不破。
- `DLEmptyState` 新签名通过保留 `init(message:)` 兼容旧调用，避免 Task 5/6 与 Task 12 顺序绑死。
- `DLErrorBanner` 增加可选 `onRetry` 闭包，老调用点 `DLErrorBanner(message:)` 仍可用。
- 没有任何 Service / Model / Supabase 改动。
- 每个 Task 末尾都有显式 xcodebuild verify + commit。
- Task 编号一致：Task 1-3 = Phase 1，Task 4-11 = Phase 2，Task 12-13 = Phase 3，Task 14-15 = Phase 4。
