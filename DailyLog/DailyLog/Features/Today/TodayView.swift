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
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    CalendarView(selectedDate: $selectedDate)

                    if let errorMessage {
                        DLErrorBanner(message: errorMessage)
                            .padding(.horizontal, Spacing.md)
                    }

                    if isLoading && allTasksEmpty {
                        ProgressView()
                            .padding(.top, 100)
                    } else if allTasksEmpty {
                        DLEmptyState(message: Calendar.current.isDateInToday(selectedDate) ? "今日无任务" : "该日无任务")
                    } else {
                        taskSections
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .refreshable { await loadAllTasks() }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    coinBadge
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
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
        .task(id: selectedDate) { await loadAllTasks() }
    }

    // MARK: - Coin Badge

    @ViewBuilder
    private var coinBadge: some View {
        if let user = appState.currentUser {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(Color.dlCoin)
                Text("\(user.coins)")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .glassEffect(.regular.tint(.yellow), in: .capsule)
        }
    }

    // MARK: - Task Sections

    private var taskSections: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(spacing: Spacing.md) {
                if !dailyTasks.isEmpty {
                    taskSection(title: "日任务", tasks: dailyTasks, type: .daily)
                }
                if !weeklyTasks.isEmpty {
                    taskSection(title: "周任务", tasks: weeklyTasks, type: .weekly)
                }
                if !monthlyTasks.isEmpty {
                    taskSection(title: "月任务", tasks: monthlyTasks, type: .monthly)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private func taskSection(title: String, tasks: [TaskItem], type: TaskType) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)
            ForEach(tasks) { task in
                TaskRowView(task: task, isToday: isToday) {
                    taskToComplete = task
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
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
