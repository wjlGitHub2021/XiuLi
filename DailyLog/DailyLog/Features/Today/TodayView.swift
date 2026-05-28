import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDate: Date = Date()
    @State private var dailyTasks: [TaskItem] = []
    @State private var weeklyTasks: [TaskItem] = []
    @State private var monthlyTasks: [TaskItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var taskToComplete: TaskItem?

    private let taskService = TaskService()

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var allTasksEmpty: Bool {
        dailyTasks.isEmpty && weeklyTasks.isEmpty && monthlyTasks.isEmpty
    }

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
                            let isTodayDate = Calendar.current.isDateInToday(selectedDate)
                            DLEmptyState(
                                icon: "tray",
                                title: isTodayDate ? "今日无任务" : "该日无任务",
                                subtitle: isTodayDate ? "今天还没有安排任务" : nil,
                                actionTitle: isTodayDate ? "新建任务" : nil,
                                action: isTodayDate ? { showCreateSheet = true } : nil
                            )
                        } else {
                            taskSections
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .scrollContentBackground(.hidden)
                .refreshable { await loadAllTasks() }
                .navigationTitle("今日")
                .toolbarBackground(.hidden, for: .navigationBar)
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

    // MARK: - Coin Badge

    @ViewBuilder
    private var coinBadge: some View {
        if let user = appState.currentUser {
            DLGlassBadge(icon: "bitcoinsign.circle.fill",
                         text: "\(user.coins)",
                         tint: .dlCoin)
        }
    }

    // MARK: - Task Sections

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

    // MARK: - Data Loading

    private func loadAllTasks() async {
        guard let userId = appState.currentUser?.id else { return }
        let captured = selectedDate
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await taskService.fetchAllTasks(userId: userId, date: captured)
            guard captured == selectedDate else { return }
            dailyTasks = result.daily
            weeklyTasks = result.weekly
            monthlyTasks = result.monthly
        } catch is CancellationError {
            // CancellationError 是良性的：SwiftUI 视图重组或 supabase-swift token 刷新
            // 都会取消进行中的请求。下次 refresh/.task 触发会重新拉取，不应展示为"失败"。
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
    }

    private func updateTask(_ task: TaskItem) {
        if let index = dailyTasks.firstIndex(where: { $0.id == task.id }) {
            dailyTasks[index] = task
        } else if let index = weeklyTasks.firstIndex(where: { $0.id == task.id }) {
            weeklyTasks[index] = task
        } else if let index = monthlyTasks.firstIndex(where: { $0.id == task.id }) {
            monthlyTasks[index] = task
        }
        Task { await appState.refreshProfile() }
    }
}
