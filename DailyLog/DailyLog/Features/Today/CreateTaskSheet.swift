import SwiftUI

struct CreateTaskSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var taskType: TaskType
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let taskService = TaskService()
    let onCreated: (TaskItem) -> Void
    private let editingTask: TaskItem?

    init(taskType: TaskType, onCreated: @escaping (TaskItem) -> Void) {
        self._taskType = State(initialValue: taskType)
        self.onCreated = onCreated
        self.editingTask = nil
    }

    init(editing task: TaskItem, onSaved: @escaping (TaskItem) -> Void) {
        self._taskType = State(initialValue: task.taskType)
        self._title = State(initialValue: task.title)
        self._notes = State(initialValue: task.notes ?? "")
        self.onCreated = onSaved
        self.editingTask = task
    }

    private var isEditing: Bool { editingTask != nil }

    private var coinsEarned: Int {
        switch taskType {
        case .daily: return 10
        case .weekly: return 30
        case .monthly: return 100
        }
    }

    private var taskDate: Date { Date() }

    private var computedExpireDate: Date {
        let cal = Calendar(identifier: .gregorian)
        switch taskType {
        case .daily:
            return taskDate
        case .weekly:
            // 本周日 23:59:59（周一为一周起始）
            var c = Calendar(identifier: .gregorian)
            c.firstWeekday = 2
            guard let weekInterval = c.dateInterval(of: .weekOfYear, for: taskDate) else { return taskDate }
            return cal.date(byAdding: .second, value: -1, to: weekInterval.end) ?? taskDate
        case .monthly:
            // 本月最后一天 23:59:59
            guard let monthInterval = cal.dateInterval(of: .month, for: taskDate) else { return taskDate }
            return cal.date(byAdding: .second, value: -1, to: monthInterval.end) ?? taskDate
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        DLGlassPageHeader(title: isEditing ? "编辑任务" : "创建任务", subtitle: isEditing ? "修改任务内容" : "安排一个可完成的小目标") {
                            DLGlassBadge(icon: "bitcoinsign.circle.fill", text: "+\(coinsEarned)", tint: .dlCoin)
                        }

                        DLGlassCard(tint: Color.dlLavender, cornerRadius: CornerRadius.panel) {
                            VStack(spacing: Spacing.md) {
                                DLGlassTextField(icon: "checkmark.circle", placeholder: "任务标题", text: $title)
                                DLGlassTextField(icon: "text.alignleft", placeholder: "备注（可选）", text: $notes, axis: .vertical)
                                    .lineLimit(2...4)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        DLGlassCard(cornerRadius: CornerRadius.panel) {
                            VStack(spacing: Spacing.md) {
                                if !isEditing {
                                    Picker("任务类型", selection: $taskType) {
                                        ForEach(TaskType.allCases, id: \.self) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                HStack {
                                    Label(isEditing ? "任务类型" : "完成奖励", systemImage: isEditing ? "tag" : "bitcoinsign.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.dlTextPrimary)
                                    Spacer()
                                    if isEditing {
                                        Text(taskType.displayName)
                                            .font(.headline.bold())
                                            .foregroundStyle(Color.dlLavender)
                                    } else {
                                        Text("+\(coinsEarned) 金币")
                                            .font(.headline.bold())
                                            .foregroundStyle(Color.dlCoin)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        if let errorMessage {
                            DLErrorBanner(message: errorMessage)
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        DLPrimaryButton(
                            action: { Task { await createTask() } },
                            isLoading: isLoading,
                            isDisabled: title.isEmpty
                        ) {
                            Text(isEditing ? "保存" : "创建")
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }
                    .padding(.vertical, Spacing.screenVertical)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "编辑任务" : "创建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .buttonStyle(.glass)
                }
            }
            .tint(Color.dlLavender)
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
            if let editingTask {
                try await taskService.updateTaskTitle(
                    taskId: editingTask.id,
                    title: title,
                    notes: notes.isEmpty ? nil : notes
                )
                var updated = editingTask
                updated.title = title
                updated.notes = notes.isEmpty ? nil : notes
                onCreated(updated)
                dismiss()
                return
            }

            let totalCount: Int
            switch taskType {
            case .daily:
                let existing = try await taskService.fetchTasks(userId: userId, taskType: .daily, date: taskDate)
                totalCount = existing.count
            case .weekly, .monthly:
                let allPending = try await taskService.fetchAllPendingTasks(userId: userId, taskType: taskType)
                totalCount = allPending.count
            }
            if totalCount >= 5 {
                errorMessage = "\(taskType.displayName)最多5个任务"
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
                errorMessage = isEditing ? "保存失败，请重试" : "创建失败，请重试"
            }
        }
    }
}
