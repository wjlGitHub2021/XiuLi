import SwiftUI

struct CreateTaskSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var taskType: TaskType
    @State private var taskDate = Date()
    @State private var coinsEarned = 10
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let taskService = TaskService()
    let onCreated: (TaskItem) -> Void

    init(taskType: TaskType, onCreated: @escaping (TaskItem) -> Void) {
        self._taskType = State(initialValue: taskType)
        self.onCreated = onCreated
    }

    /// Auto-calculated expire date based on task type
    private var computedExpireDate: Date {
        switch taskType {
        case .daily:
            return taskDate
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: 7, to: taskDate) ?? taskDate
        case .monthly:
            return Calendar.current.date(byAdding: .day, value: 30, to: taskDate) ?? taskDate
        }
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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func createTask() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Enforce 5 active task limit per type
            let existing = try await taskService.fetchTasks(userId: userId, taskType: taskType, date: taskDate)
            let pendingCount = existing.filter { $0.status == .pending }.count
            if pendingCount >= 5 {
                errorMessage = "\(taskType.displayName)最多同时存在5个待完成任务"
                return
            }

            let params = CreateTaskParams(
                userId: userId,
                title: title,
                notes: notes.isEmpty ? nil : notes,
                taskType: taskType.rawValue,
                taskDate: Self.dateFormatter.string(from: taskDate),
                expireDate: Self.dateFormatter.string(from: computedExpireDate),
                coinsEarned: coinsEarned,
                orderInDay: 0
            )

            let newTask = try await taskService.createTask(params)
            onCreated(newTask)
            dismiss()
        } catch {
            if errorMessage == nil {
                errorMessage = "创建失败，请重试"
            }
        }
    }
}