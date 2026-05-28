# DailyLog iOS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建 DailyLog iOS SwiftUI 原生应用 MVP，连接 Supabase 后端，实现预置账号登录、Today 任务管理（创建/筛选/完成）和 Profile 展示（金币/统计/流水/退出），全中文界面。

**Architecture:** SwiftUI 分层架构：App 层管理全局状态和路由，Core 层封装 Supabase 客户端、Auth/Task/Profile 服务和 Models，Features 层按页面组织 Login/Today/Profile。采用 @Observable (iOS 17+) 管理状态，async/await 处理异步。视觉参考 iOS 26 Liquid Glass 但优先保证可读性。

**Tech Stack:** SwiftUI、iOS 17+、Swift Package Manager、supabase-swift SDK、Xcode 16+。

**前置条件：** Plan A（Supabase MVP）已完成，远端数据库 schema、RLS、RPC、预置账号均已就位。

**约定：**
- Supabase URL: `https://yvpnuagkykpbhlljexnt.supabase.co`
- Bundle ID: `com.wangjinlong.DailyLog`
- iOS Deployment Target: 17.0
- 所有用户可见文案使用中文
- 不实现注册、邀请、APNs、奖励兑换、转盘、完整动态流

---

## File Structure

```text
DailyLog/
├── DailyLog.xcodeproj
├── DailyLog/
│   ├── App/
│   │   ├── DailyLogApp.swift          # @main 入口，初始化 AppState
│   │   ├── AppState.swift             # 全局状态：session、user、路由
│   │   └── ContentView.swift          # 根据登录态切换 Login/Main
│   ├── Core/
│   │   ├── Supabase/
│   │   │   └── SupabaseClient.swift   # 单例，配置 URL + anon key
│   │   ├── Models/
│   │   │   ├── User.swift             # public.users 映射
│   │   │   ├── TaskItem.swift         # public.tasks 映射
│   │   │   ├── CoinTransaction.swift  # public.coin_transactions 映射
│   │   │   └── CompleteTaskResponse.swift # complete_task RPC 返回
│   │   ├── Services/
│   │   │   ├── AuthService.swift      # 登录、退出、session 恢复
│   │   │   ├── TaskService.swift      # 任务 CRUD + complete_task RPC
│   │   │   └── ProfileService.swift   # profile + 金币流水
│   │   └── DesignSystem/
│   │       ├── Colors.swift           # 应用颜色定义
│   │       ├── Spacing.swift          # 间距常量
│   │       └── Components.swift       # 通用 UI 组件
│   ├── Features/
│   │   ├── Login/
│   │   │   └── LoginView.swift        # 邮箱密码登录页
│   │   ├── Today/
│   │   │   ├── TodayView.swift        # 任务列表主页
│   │   │   ├── TaskRowView.swift      # 单条任务行
│   │   │   └── CreateTaskSheet.swift  # 创建任务表单
│   │   └── Profile/
│   │       └── ProfileView.swift      # 个人资料页
│   └── Resources/
│       └── Assets.xcassets            # 图标、颜色资源
```

---

### Task 1: 创建 Xcode 项目和 SPM 依赖

**目的：** 初始化 iOS 项目骨架，添加 supabase-swift SDK 依赖，确保项目能编译通过。

**Files:**
- Create: `DailyLog/DailyLog.xcodeproj`（Xcode 生成）
- Create: `DailyLog/DailyLog/App/DailyLogApp.swift`
- Create: `DailyLog/DailyLog/App/ContentView.swift`

- [ ] **Step 1: 用 Xcode 命令行创建项目**

```bash
cd /Users/wangjinlong/ai_app_VibeCoding_study/XiuLi
mkdir -p DailyLog
```

在 Xcode 中创建新项目（或用 `xcodegen` / 手动 `Package.swift`）：
- Product Name: `DailyLog`
- Organization Identifier: `com.wangjinlong`
- Interface: SwiftUI
- Language: Swift
- Minimum Deployments: iOS 17.0

如果使用纯 SPM（推荐），创建 `DailyLog/Package.swift`：

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DailyLog",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DailyLog",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "DailyLog"
        )
    ]
)
```

注意：如果使用 Xcode 项目（.xcodeproj），则通过 File → Add Package Dependencies 添加 `https://github.com/supabase/supabase-swift.git`，版本 `2.0.0` 起。推荐使用 Xcode 项目方式，因为需要设置 Bundle ID 和签名。

- [ ] **Step 2: 写入最小 App 入口**

Create `DailyLog/DailyLog/App/DailyLogApp.swift`:

```swift
import SwiftUI

@main
struct DailyLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Create `DailyLog/DailyLog/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("DailyLog")
    }
}
```

- [ ] **Step 3: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。如果 SPM 依赖解析需要时间，等待完成。

- [ ] **Step 4: Commit**

```bash
git add DailyLog/
git commit -m "feat(ios): initialize DailyLog Xcode project with supabase-swift dependency"
```

---

### Task 2: Supabase 客户端配置

**目的：** 创建 Supabase 客户端单例，集中管理 URL 和 anon key。

**Files:**
- Create: `DailyLog/DailyLog/Core/Supabase/SupabaseClient.swift`

- [ ] **Step 1: 创建 SupabaseClient 单例**

Create `DailyLog/DailyLog/Core/Supabase/SupabaseClient.swift`:

```swift
import Supabase
import Foundation

enum AppSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://yvpnuagkykpbhlljexnt.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6Inl2cG51YWdreWtwYmhsbGpleG50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2ODU4ODYsImV4cCI6MjA5NTI2MTg4Nn0.RjJjUP3jsShhlUtCU-su-nTvypmn0x0ZugM69TYy1vE"
    )
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Core/Supabase/SupabaseClient.swift
git commit -m "feat(ios): add Supabase client singleton with project config"
```

---

### Task 3: 数据模型

**目的：** 定义与 Supabase 表对应的 Swift 模型，用于 JSON 解码和 UI 绑定。

**Files:**
- Create: `DailyLog/DailyLog/Core/Models/User.swift`
- Create: `DailyLog/DailyLog/Core/Models/TaskItem.swift`
- Create: `DailyLog/DailyLog/Core/Models/CoinTransaction.swift`
- Create: `DailyLog/DailyLog/Core/Models/CompleteTaskResponse.swift`

- [ ] **Step 1: 创建 User 模型**

Create `DailyLog/DailyLog/Core/Models/User.swift`:

```swift
import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var nickname: String
    var avatarUrl: String?
    var coins: Int
    var totalCompleted: Int
    var pushEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, nickname, coins
        case avatarUrl = "avatar_url"
        case totalCompleted = "total_completed"
        case pushEnabled = "push_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

- [ ] **Step 2: 创建 TaskItem 模型**

Create `DailyLog/DailyLog/Core/Models/TaskItem.swift`:

```swift
import Foundation

enum TaskType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "日任务"
        case .weekly: return "周任务"
        case .monthly: return "月任务"
        }
    }
}

enum TaskStatus: String, Codable {
    case pending
    case completed
}

struct TaskItem: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var notes: String?
    var taskType: TaskType
    var status: TaskStatus
    var orderInDay: Int
    var coinsEarned: Int
    var taskDate: String
    var expireDate: String?
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, notes, status
        case userId = "user_id"
        case taskType = "task_type"
        case orderInDay = "order_in_day"
        case coinsEarned = "coins_earned"
        case taskDate = "task_date"
        case expireDate = "expire_date"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isCompleted: Bool { status == .completed }
}
```

- [ ] **Step 3: 创建 CoinTransaction 模型**

Create `DailyLog/DailyLog/Core/Models/CoinTransaction.swift`:

```swift
import Foundation

struct CoinTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Int
    let balanceAfter: Int
    let reason: String
    let referenceType: String?
    let referenceId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, reason
        case userId = "user_id"
        case balanceAfter = "balance_after"
        case referenceType = "reference_type"
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }

    var reasonDisplay: String {
        switch reason {
        case "task_complete": return "完成任务"
        case "reward_redeem": return "兑换奖励"
        case "spin_cost": return "转盘消耗"
        case "spin_win": return "转盘中奖"
        case "adjustment": return "调整"
        default: return reason
        }
    }
}
```

- [ ] **Step 4: 创建 CompleteTaskResponse 模型**

Create `DailyLog/DailyLog/Core/Models/CompleteTaskResponse.swift`:

```swift
import Foundation

struct CompleteTaskResponse: Codable {
    let task: TaskItem
    let coins: Int
    let totalCompleted: Int
    let alreadyCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case task, coins
        case totalCompleted = "total_completed"
        case alreadyCompleted = "already_completed"
    }
}
```

- [ ] **Step 5: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 6: Commit**

```bash
git add DailyLog/DailyLog/Core/Models/
git commit -m "feat(ios): add data models for User, TaskItem, CoinTransaction"
```

---

### Task 4: AuthService

**目的：** 封装 Supabase Auth 的登录、退出和 session 恢复逻辑。

**Files:**
- Create: `DailyLog/DailyLog/Core/Services/AuthService.swift`

- [ ] **Step 1: 创建 AuthService**

Create `DailyLog/DailyLog/Core/Services/AuthService.swift`:

```swift
import Foundation
import Supabase
import Auth

final class AuthService {
    private let client = AppSupabase.client

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func restoreSession() async throws -> Bool {
        let session = try await client.auth.session
        return session.user.id != nil
    }

    var currentUserId: UUID? {
        try? client.auth.session.user.id
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Core/Services/AuthService.swift
git commit -m "feat(ios): add AuthService for login, logout, session restore"
```

---

### Task 5: TaskService

**目的：** 封装任务的查询、创建和完成（RPC 调用）逻辑。

**Files:**
- Create: `DailyLog/DailyLog/Core/Services/TaskService.swift`

- [ ] **Step 1: 创建 TaskService**

Create `DailyLog/DailyLog/Core/Services/TaskService.swift`:

```swift
import Foundation
import Supabase

struct CreateTaskParams: Encodable {
    let userId: UUID
    let title: String
    let notes: String?
    let taskType: String
    let taskDate: String
    let expireDate: String?
    let coinsEarned: Int
    let orderInDay: Int

    enum CodingKeys: String, CodingKey {
        case title, notes
        case userId = "user_id"
        case taskType = "task_type"
        case taskDate = "task_date"
        case expireDate = "expire_date"
        case coinsEarned = "coins_earned"
        case orderInDay = "order_in_day"
    }
}

final class TaskService {
    private let client = AppSupabase.client

    func fetchTasks(userId: UUID, taskType: TaskType, date: Date) async throws -> [TaskItem] {
        let dateString = Self.dateFormatter.string(from: date)
        return try await client.from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("task_type", value: taskType.rawValue)
            .eq("task_date", value: dateString)
            .order("order_in_day")
            .execute()
            .value
    }

    func createTask(_ params: CreateTaskParams) async throws -> TaskItem {
        return try await client.from("tasks")
            .insert(params)
            .select()
            .single()
            .execute()
            .value
    }

    func completeTask(taskId: UUID) async throws -> CompleteTaskResponse {
        return try await client.rpc(
            "complete_task",
            params: ["p_task_id": taskId.uuidString]
        )
        .execute()
        .value
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Core/Services/TaskService.swift
git commit -m "feat(ios): add TaskService for task CRUD and complete_task RPC"
```

---

### Task 6: ProfileService

**目的：** 封装 profile 读取和金币流水查询。

**Files:**
- Create: `DailyLog/DailyLog/Core/Services/ProfileService.swift`

- [ ] **Step 1: 创建 ProfileService**

Create `DailyLog/DailyLog/Core/Services/ProfileService.swift`:

```swift
import Foundation
import Supabase

final class ProfileService {
    private let client = AppSupabase.client

    func fetchProfile(userId: UUID) async throws -> User {
        return try await client.from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchRecentTransactions(userId: UUID, limit: Int = 10) async throws -> [CoinTransaction] {
        return try await client.from("coin_transactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Core/Services/ProfileService.swift
git commit -m "feat(ios): add ProfileService for profile and coin transactions"
```

---

### Task 7: Design System

**目的：** 定义应用颜色、间距和通用 UI 组件，参考 iOS 26 Liquid Glass 但优先保证可读性。

**Files:**
- Create: `DailyLog/DailyLog/Core/DesignSystem/Colors.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/Spacing.swift`
- Create: `DailyLog/DailyLog/Core/DesignSystem/Components.swift`

- [ ] **Step 1: 创建颜色定义**

Create `DailyLog/DailyLog/Core/DesignSystem/Colors.swift`:

```swift
import SwiftUI

extension Color {
    static let dlPrimary = Color.blue
    static let dlSecondary = Color.gray
    static let dlSuccess = Color.green
    static let dlWarning = Color.orange
    static let dlCoin = Color.yellow
    static let dlBackground = Color(.systemGroupedBackground)
    static let dlCardBackground = Color(.secondarySystemGroupedBackground)
}
```

- [ ] **Step 2: 创建间距常量**

Create `DailyLog/DailyLog/Core/DesignSystem/Spacing.swift`:

```swift
import Foundation

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

- [ ] **Step 3: 创建通用组件**

Create `DailyLog/DailyLog/Core/DesignSystem/Components.swift`:

```swift
import SwiftUI

struct DLEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.lg)
    }
}

struct DLErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DLLoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dlPrimary)
        .foregroundStyle(.white)
        .font(.headline)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isLoading)
    }
}
```

- [ ] **Step 4: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 5: Commit**

```bash
git add DailyLog/DailyLog/Core/DesignSystem/
git commit -m "feat(ios): add design system with colors, spacing, and shared components"
```

---

### Task 8: AppState 全局状态管理

**目的：** 实现 AppState，管理 session 恢复、登录状态、当前用户 profile 和路由。

**Files:**
- Create: `DailyLog/DailyLog/App/AppState.swift`
- Modify: `DailyLog/DailyLog/App/DailyLogApp.swift`
- Modify: `DailyLog/DailyLog/App/ContentView.swift`

- [ ] **Step 1: 创建 AppState**

Create `DailyLog/DailyLog/App/AppState.swift`:

```swift
import Foundation
import Observation

@Observable
final class AppState {
    var isAuthenticated = false
    var isLoading = true
    var currentUser: User?

    private let authService = AuthService()
    private let profileService = ProfileService()

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let hasSession = try await authService.restoreSession()
            if hasSession, let userId = authService.currentUserId {
                currentUser = try await profileService.fetchProfile(userId: userId)
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func onLoginSuccess() async {
        guard let userId = authService.currentUserId else { return }
        do {
            currentUser = try await profileService.fetchProfile(userId: userId)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signOut() async {
        try? await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }

    func refreshProfile() async {
        guard let userId = authService.currentUserId else { return }
        currentUser = try? await profileService.fetchProfile(userId: userId)
    }
}
```

- [ ] **Step 2: 更新 DailyLogApp.swift 注入 AppState**

Modify `DailyLog/DailyLog/App/DailyLogApp.swift`:

```swift
import SwiftUI

@main
struct DailyLogApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 3: 更新 ContentView 根据登录态路由**

Modify `DailyLog/DailyLog/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView("加载中...")
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await appState.restoreSession()
        }
    }
}
```

- [ ] **Step 4: 创建 MainTabView 占位**

Create `DailyLog/DailyLog/App/MainTabView.swift`:

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("今日", systemImage: "checkmark.circle") {
                TodayView()
            }
            Tab("我的", systemImage: "person.circle") {
                ProfileView()
            }
        }
    }
}
```

注意：`TodayView` 和 `ProfileView` 在后续 Task 中创建。此步骤先创建占位 View 以通过编译：

Create `DailyLog/DailyLog/Features/Today/TodayView.swift`:

```swift
import SwiftUI

struct TodayView: View {
    var body: some View {
        Text("Today placeholder")
    }
}
```

Create `DailyLog/DailyLog/Features/Profile/ProfileView.swift`:

```swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        Text("Profile placeholder")
    }
}
```

- [ ] **Step 5: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 6: Commit**

```bash
git add DailyLog/DailyLog/App/
git add DailyLog/DailyLog/Features/Today/TodayView.swift
git add DailyLog/DailyLog/Features/Profile/ProfileView.swift
git commit -m "feat(ios): add AppState, ContentView routing, and MainTabView"
```

---

### Task 9: LoginView

**目的：** 实现登录页面，支持邮箱密码输入、登录按钮、中文错误提示。

**Files:**
- Create: `DailyLog/DailyLog/Features/Login/LoginView.swift`

- [ ] **Step 1: 创建 LoginView**

Create `DailyLog/DailyLog/Features/Login/LoginView.swift`:

```swift
import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let authService = AuthService()

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("DailyLog")
                .font(.largeTitle.bold())

            Text("每日打卡，积累金币")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.md) {
                TextField("邮箱", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("密码", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage {
                DLErrorBanner(message: errorMessage)
            }

            DLLoadingButton(title: "登录", isLoading: isLoading) {
                Task { await login() }
            }
            .disabled(email.isEmpty || password.isEmpty)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            await appState.onLoginSuccess()
        } catch {
            errorMessage = mapError(error)
        }
    }

    private func mapError(_ error: Error) -> String {
        let desc = error.localizedDescription.lowercased()
        if desc.contains("invalid") || desc.contains("credentials") {
            return "邮箱或密码不正确"
        }
        if desc.contains("network") || desc.contains("connection") {
            return "网络连接失败，请检查网络后重试"
        }
        return "登录失败，请稍后重试"
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Features/Login/LoginView.swift
git commit -m "feat(ios): add LoginView with email/password and Chinese error messages"
```

---

### Task 10: TodayView 任务列表和筛选

**目的：** 实现 Today 主页面，包含日期显示、金币提示、任务类型切换（日/周/月）和任务列表。

**Files:**
- Modify: `DailyLog/DailyLog/Features/Today/TodayView.swift`
- Create: `DailyLog/DailyLog/Features/Today/TaskRowView.swift`

- [ ] **Step 1: 创建 TaskRowView**

Create `DailyLog/DailyLog/Features/Today/TaskRowView.swift`:

```swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onComplete: () -> Void
    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {
                guard !task.isCompleted else { return }
                isCompleting = true
                onComplete()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .disabled(task.isCompleted || isCompleting)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(.dlCoin)
                Text("+\(task.coinsEarned)")
                    .font(.subheadline.bold())
                    .foregroundStyle(task.isCompleted ? .secondary : .dlCoin)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}
```

- [ ] **Step 2: 实现完整 TodayView**

Modify `DailyLog/DailyLog/Features/Today/TodayView.swift`:

```swift
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedType: TaskType = .daily
    @State private var tasks: [TaskItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false

    private let taskService = TaskService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("任务类型", selection: $selectedType) {
                    ForEach(TaskType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                if let errorMessage {
                    DLErrorBanner(message: errorMessage)
                        .padding(.horizontal, Spacing.md)
                }

                if isLoading && tasks.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if tasks.isEmpty {
                    DLEmptyState(message: emptyMessage)
                } else {
                    List {
                        ForEach(tasks) { task in
                            TaskRowView(task: task) {
                                Task { await completeTask(task) }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await loadTasks() }
                }
            }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let user = appState.currentUser {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .foregroundStyle(.dlCoin)
                            Text("\(user.coins)")
                                .font(.subheadline.bold())
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTaskSheet(taskType: selectedType) { newTask in
                    tasks.insert(newTask, at: 0)
                }
            }
        }
        .task { await loadTasks() }
        .onChange(of: selectedType) { _, _ in
            Task { await loadTasks() }
        }
    }

    private var emptyMessage: String {
        switch selectedType {
        case .daily: return "今天还没有日任务"
        case .weekly: return "本周还没有周任务"
        case .monthly: return "本月还没有月任务"
        }
    }

    private func loadTasks() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await taskService.fetchTasks(
                userId: userId,
                taskType: selectedType,
                date: Date()
            )
        } catch {
            errorMessage = "加载任务失败，下拉刷新重试"
        }
    }

    private func completeTask(_ task: TaskItem) async {
        errorMessage = nil
        do {
            let response = try await taskService.completeTask(taskId: task.id)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = response.task
            }
            await appState.refreshProfile()
        } catch {
            errorMessage = "完成任务失败，请重试"
            await loadTasks()
        }
    }
}
```

- [ ] **Step 3: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 4: Commit**

```bash
git add DailyLog/DailyLog/Features/Today/
git commit -m "feat(ios): implement TodayView with task list, filtering, and completion"
```

---

### Task 11: CreateTaskSheet

**目的：** 实现创建任务的表单 sheet，支持标题、备注、任务类型、任务日期、到期日期和金币值。

**Files:**
- Create: `DailyLog/DailyLog/Features/Today/CreateTaskSheet.swift`

- [ ] **Step 1: 创建 CreateTaskSheet**

Create `DailyLog/DailyLog/Features/Today/CreateTaskSheet.swift`:

```swift
import SwiftUI

struct CreateTaskSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var taskType: TaskType
    @State private var taskDate = Date()
    @State private var expireDate: Date?
    @State private var hasExpireDate = false
    @State private var coinsEarned = 10
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let taskService = TaskService()
    let onCreated: (TaskItem) -> Void

    init(taskType: TaskType, onCreated: @escaping (TaskItem) -> Void) {
        self._taskType = State(initialValue: taskType)
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("任务信息") {
                    TextField("任务标题", text: $title)
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("任务设置") {
                    Picker("任务类型", selection: $taskType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    DatePicker("任务日期", selection: $taskDate, displayedComponents: .date)

                    Toggle("设置到期日", isOn: $hasExpireDate)
                    if hasExpireDate {
                        DatePicker("到期日期", selection: Binding(
                            get: { expireDate ?? taskDate },
                            set: { expireDate = $0 }
                        ), displayedComponents: .date)
                    }

                    Stepper("金币奖励：\(coinsEarned)", value: $coinsEarned, in: 1...100)
                }

                if let errorMessage {
                    Section {
                        DLErrorBanner(message: errorMessage)
                    }
                }
            }
            .navigationTitle("创建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await createTask() }
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
        }
    }

    private func createTask() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let params = CreateTaskParams(
            userId: userId,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            taskType: taskType.rawValue,
            taskDate: dateFormatter.string(from: taskDate),
            expireDate: hasExpireDate ? dateFormatter.string(from: expireDate ?? taskDate) : nil,
            coinsEarned: coinsEarned,
            orderInDay: 0
        )

        do {
            let newTask = try await taskService.createTask(params)
            onCreated(newTask)
            dismiss()
        } catch {
            errorMessage = "创建失败，请重试"
        }
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Features/Today/CreateTaskSheet.swift
git commit -m "feat(ios): add CreateTaskSheet for task creation with type, date, coins"
```

---

### Task 12: ProfileView

**目的：** 实现 Profile 页面，展示头像、昵称、金币、完成统计、最近金币流水、推送禁用态和退出登录。

**Files:**
- Modify: `DailyLog/DailyLog/Features/Profile/ProfileView.swift`

- [ ] **Step 1: 实现完整 ProfileView**

Modify `DailyLog/DailyLog/Features/Profile/ProfileView.swift`:

```swift
import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var transactions: [CoinTransaction] = []
    @State private var isLoading = false
    @State private var showLogoutConfirm = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                statsSection
                transactionsSection
                settingsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的")
            .refreshable { await loadData() }
            .confirmationDialog("确认退出登录？", isPresented: $showLogoutConfirm) {
                Button("退出登录", role: .destructive) {
                    Task { await appState.signOut() }
                }
            }
        }
        .task { await loadData() }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: Spacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(appState.currentUser?.nickname ?? "加载中")
                        .font(.title2.bold())
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(.dlCoin)
                        Text("\(appState.currentUser?.coins ?? 0) 金币")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var statsSection: some View {
        Section("统计") {
            HStack {
                Label("完成任务", systemImage: "checkmark.circle")
                Spacer()
                Text("\(appState.currentUser?.totalCompleted ?? 0) 次")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var transactionsSection: some View {
        Section("最近金币记录") {
            if transactions.isEmpty {
                Text("还没有金币记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(transactions) { tx in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.reasonDisplay)
                                .font(.body)
                            Text(tx.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(tx.amount > 0 ? "+\(tx.amount)" : "\(tx.amount)")
                            .font(.body.bold())
                            .foregroundStyle(tx.amount > 0 ? .green : .red)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        Section("设置") {
            HStack {
                Label("消息推送", systemImage: "bell")
                Spacer()
                Text("稍后开放")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private func loadData() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }

        await appState.refreshProfile()
        transactions = (try? await profileService.fetchRecentTransactions(userId: userId)) ?? []
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: Commit**

```bash
git add DailyLog/DailyLog/Features/Profile/ProfileView.swift
git commit -m "feat(ios): implement ProfileView with stats, transactions, and logout"
```

---

### Task 13: 端到端集成验证

**目的：** 在模拟器上运行完整 App，验证登录 → Today → 创建任务 → 完成任务 → Profile 的金路径。

**Files:** 无新文件，纯验证。

- [ ] **Step 1: 启动模拟器并运行 App**

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

xcrun simctl boot "iPhone 16" 2>/dev/null || true
open -a Simulator
```

然后在 Xcode 中 Run（Cmd+R）或：

```bash
xcodebuild -project DailyLog/DailyLog.xcodeproj \
  -scheme DailyLog \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build/ \
  build

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/DailyLog.app
xcrun simctl launch booted com.wangjinlong.DailyLog
```

- [ ] **Step 2: 验证登录流程**

手动验证：
1. App 启动显示"加载中..."，然后跳转到登录页
2. 输入 `user1@dailylog.local` / `DailyLog!1`
3. 点击"登录"
4. Expected: 进入 Today 页面，顶部显示金币数

验证失败路径：
1. 输入错误密码
2. Expected: 显示"邮箱或密码不正确"

- [ ] **Step 3: 验证 Today 功能**

手动验证：
1. 默认显示"日任务"分段，列表为空显示"今天还没有日任务"
2. 点击右上角 "+" 按钮
3. 填写标题"喝水 2L"，备注"上午下午各一次"，金币 10
4. 点击"创建"
5. Expected: sheet 关闭，任务出现在列表中
6. 点击任务左侧圆圈完成
7. Expected: 圆圈变为绿色勾，标题划线，顶部金币 +10

- [ ] **Step 4: 验证 Profile 功能**

手动验证：
1. 切换到"我的" Tab
2. Expected: 显示昵称"我的昵称"、金币数（与 Today 顶部一致）、完成任务 1 次
3. 最近金币记录显示"完成任务 +10"
4. 推送设置显示"稍后开放"
5. 点击"退出登录" → 确认
6. Expected: 回到登录页

- [ ] **Step 5: 验证 session 恢复**

手动验证：
1. 重新登录
2. 杀掉 App（从多任务中上滑移除）
3. 重新打开 App
4. Expected: 不需要重新登录，直接进入 Today

- [ ] **Step 6: 记录验证结果**

把验证结果追加到 `supabase/_baseline.md`：

```markdown
## iOS MVP E2E Verification (2026-05-28)

- App 启动 session 恢复：PASS/FAIL
- 登录成功：PASS/FAIL
- 登录失败错误提示：PASS/FAIL
- Today 空状态：PASS/FAIL
- 创建日任务：PASS/FAIL
- 完成任务金币增加：PASS/FAIL
- 任务类型切换：PASS/FAIL
- Profile 金币/统计/流水：PASS/FAIL
- 退出登录：PASS/FAIL
- Session 恢复（杀进程后）：PASS/FAIL
```

- [ ] **Step 7: Commit**

```bash
git add supabase/_baseline.md
git commit -m "test(ios): record iOS MVP end-to-end verification results"
```

---

## 完成定义

完成本计划后，DailyLog iOS 项目应处于以下状态：

- Xcode 项目可编译，依赖 supabase-swift SDK 2.0+
- Bundle ID: `com.wangjinlong.DailyLog`，iOS 17.0+
- 连接远端 Supabase 项目 `yvpnuagkykpbhlljexnt`
- 登录页：邮箱密码登录，中文错误提示，无注册入口
- Today 页：日/周/月任务筛选、任务列表、创建任务 sheet、完成任务调用 `complete_task` RPC
- Profile 页：昵称、金币、完成统计、最近金币流水、推送禁用态、退出登录
- AppState 管理 session 恢复和全局用户状态
- 完成任务后金币只增加一次（RPC 幂等）
- 退出登录后回到登录页，session 恢复后直接进入主界面

## Self-Review Checklist

- [x] Spec §iOS 架构 → Task 1-8 覆盖项目结构、SPM 依赖、分层架构。
- [x] Spec §Supabase 数据模型 → Task 3 Models 与 Plan A 产出的 schema 一一对应。
- [x] Spec §RPC 设计 → Task 5 TaskService.completeTask 调用 `complete_task` RPC。
- [x] Spec §登录设计 → Task 9 LoginView 实现邮箱密码登录、中文错误、无注册入口。
- [x] Spec §Today 设计 → Task 10-11 覆盖筛选、列表、创建、完成、空状态、错误处理。
- [x] Spec §Profile 设计 → Task 12 覆盖头像昵称、金币、统计、流水、推送禁用、退出。
- [x] Spec §视觉设计原则 → Task 7 Design System 定义颜色/间距/组件，玻璃感用 `.ultraThinMaterial`。
- [x] Spec §错误处理 → LoginView mapError、TodayView errorMessage、CreateTaskSheet errorMessage、ProfileView 空状态。
- [x] Spec §测试与验证（iOS 部分） → Task 13 端到端手动验证覆盖所有验收路径。
- [x] Spec §不做项 → 无注册、无邀请、无 APNs、无奖励兑换、无转盘、无完整动态流。
- [x] 类型一致性：`CompleteTaskResponse` 字段 (`task`, `coins`, `totalCompleted`, `alreadyCompleted`) 与 Plan A Task 9 RPC 返回的 jsonb 字段名一致（CodingKeys 映射 snake_case）。
- [x] 文件路径一致性：所有 Task 中引用的文件路径与 File Structure 部分一致。
