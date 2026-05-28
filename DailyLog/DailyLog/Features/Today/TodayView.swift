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
            ScrollView {
                VStack(spacing: Spacing.md) {
                    Picker("任务类型", selection: $selectedType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)

                    if let errorMessage {
                        DLErrorBanner(message: errorMessage)
                            .padding(.horizontal, Spacing.md)
                    }

                    if isLoading && tasks.isEmpty {
                        ProgressView()
                            .padding(.top, 100)
                    } else if tasks.isEmpty {
                        DLEmptyState(message: emptyMessage)
                    } else {
                        taskList
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .refreshable { await loadTasks() }
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
                CreateTaskSheet(taskType: selectedType) { newTask in
                    tasks.insert(newTask, at: 0)
                }
                .environment(appState)
            }
        }
        .task(id: selectedType) { await loadTasks() }
    }

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

    private var taskList: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(spacing: Spacing.sm) {
                ForEach(tasks) { task in
                    TaskRowView(task: task) {
                        Task { await completeTask(task) }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
            .padding(.horizontal, Spacing.md)
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
                userId: userId, taskType: selectedType, date: Date()
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
