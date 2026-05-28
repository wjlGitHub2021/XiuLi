import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isToday: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            taskIcon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.body.weight(.medium))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.dlTextSecondary : Color.dlTextPrimary)
                    .lineLimit(1)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.sm)

            HStack(spacing: 4) {
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
        .padding(.vertical, 13)
    }

    private var taskIcon: some View {
        ZStack {
            Circle()
                .fill((task.isCompleted ? Color.dlSuccess : Color.dlLavender).opacity(0.16))
                .frame(width: 42, height: 42)
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(task.isCompleted ? Color.dlSuccess : Color.dlLavender)
        }
    }

    private var symbol: String {
        switch task.taskType {
        case .daily: "sun.max.fill"
        case .weekly: "calendar.badge.checkmark"
        case .monthly: "chart.line.uptrend.xyaxis"
        }
    }
}
