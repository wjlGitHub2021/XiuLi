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
    @State private var taskToDelete: TaskItem?
    @State private var showDeleteConfirm = false
    @State private var taskToEdit: TaskItem?

    private let taskService = TaskService()

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var allTasksEmpty: Bool {
        dailyTasks.isEmpty && weeklyTasks.isEmpty && monthlyTasks.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        headerArea
                        CalendarView(selectedDate: $selectedDate)

                        if let errorMessage {
                            DLErrorBanner(message: errorMessage, onRetry: {
                                Task { await loadAllTasks() }
                            })
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        if isLoading && allTasksEmpty {
                            DLLoadingState()
                                .padding(.horizontal, Spacing.screenHorizontal)
                        } else if allTasksEmpty {
                            DLEmptyState(
                                icon: "tray",
                                title: isToday ? "今日无任务" : "该日无任务",
                                subtitle: isToday ? "今天还没有安排任务" : "这一天暂时没有任务",
                                actionTitle: isToday ? "新建任务" : nil,
                                action: isToday ? { showCreateSheet = true } : nil
                            )
                            .padding(.horizontal, Spacing.screenHorizontal)
                        } else {
                            taskSections
                        }
                    }
                    .padding(.top, Spacing.screenVertical)
                    .padding(.bottom, Spacing.section)
                }
                .scrollContentBackground(.hidden)
            }
            .refreshable { await loadAllTasks() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.glass)
                    .tint(.dlLavender)
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
            .alert("确认删除", isPresented: $showDeleteConfirm, presenting: taskToDelete) { task in
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task { await deleteTask(task) }
                }
            } message: { task in
                Text("确定要删除「\(task.title)」吗？此操作不可撤销。")
            }
            .sheet(item: $taskToEdit) { task in
                CreateTaskSheet(editing: task) { updatedTask in
                    updateTask(updatedTask)
                }
                .environment(appState)
            }
        }
        .task(id: selectedDate) { await loadAllTasks() }
    }

    private var headerArea: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("今日")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.dlTextPrimary)
                Text(isToday ? "把今天的任务收进来" : selectedDate.formatted(.dateTime.month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextSecondary)
            }
            Spacer()
            if let user = appState.currentUser {
                DLGlassBadge(icon: "bitcoinsign.circle.fill", text: "\(user.coins)", tint: .dlCoin)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var taskSections: some View {
        VStack(spacing: Spacing.section) {
            if !dailyTasks.isEmpty {
                taskSection(title: "日任务", icon: "sun.max", tasks: dailyTasks, count: dailyTasks.count)
            }
            if !weeklyTasks.isEmpty {
                taskSection(title: "周任务", icon: "calendar", tasks: weeklyTasks, count: weeklyTasks.count)
            }
            if !monthlyTasks.isEmpty {
                taskSection(title: "月任务", icon: "chart.bar", tasks: monthlyTasks, count: monthlyTasks.count)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func taskSection(title: String, icon: String, tasks: [TaskItem], count: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                DLSectionHeader(title, icon: icon)
                Spacer()
                Text("\(count)/5")
                    .font(.caption.bold())
                    .foregroundStyle(count >= 5 ? Color.dlWarning : Color.dlTextSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .glassEffect(.regular.tint((count >= 5 ? Color.dlWarning : Color.dlLavender).opacity(0.2)), in: .capsule)
            }
            VStack(spacing: Spacing.xs) {
                ForEach(tasks) { task in
                    DLGlassCard(tint: task.isCompleted ? Color.dlSuccess : Color.dlLavender, cornerRadius: CornerRadius.smallCard, padding: 0) {
                        TaskRowView(task: task, isToday: isToday) {
                            taskToComplete = task
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !task.isCompleted {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                taskToEdit = task
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.dlLavender)
                        }
                    }
                }
            }
        }
    }

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

    private func deleteTask(_ task: TaskItem) async {
        do {
            try await taskService.deleteTask(taskId: task.id)
            dailyTasks.removeAll { $0.id == task.id }
            weeklyTasks.removeAll { $0.id == task.id }
            monthlyTasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }
}
