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
            ZStack {
                DLBackground()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        DLGlassPageHeader(title: "创建任务", subtitle: "安排一个可完成的小目标") {
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
                                Picker("任务类型", selection: $taskType) {
                                    ForEach(TaskType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)

                                DatePicker("任务日期", selection: $taskDate, displayedComponents: .date)
                                    .foregroundStyle(Color.dlTextPrimary)

                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        Label("金币奖励", systemImage: "bitcoinsign.circle.fill")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.dlTextPrimary)
                                        Spacer()
                                        Text("\(coinsEarned)")
                                            .font(.headline.bold())
                                            .foregroundStyle(Color.dlCoin)
                                    }
                                    Stepper("金币奖励：\(coinsEarned)", value: $coinsEarned, in: 1...100)
                                        .labelsHidden()
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
                            Text("创建")
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }
                    .padding(.vertical, Spacing.screenVertical)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("创建任务")
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
            let pendingCount: Int
            switch taskType {
            case .daily:
                let existing = try await taskService.fetchTasks(userId: userId, taskType: .daily, date: taskDate)
                pendingCount = existing.filter { $0.status == .pending }.count
            case .weekly, .monthly:
                let allPending = try await taskService.fetchAllPendingTasks(userId: userId, taskType: taskType)
                pendingCount = allPending.count
            }
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
