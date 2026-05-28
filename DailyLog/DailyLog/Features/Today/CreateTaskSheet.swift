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