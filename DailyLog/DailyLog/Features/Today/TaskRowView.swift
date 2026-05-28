import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isToday: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            taskIcon
                .frame(width: 40, height: 40)
                .glassEffect(.regular.tint(Color.dlLavender.opacity(0.22)),
                             in: .circle)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.dlTextSecondary : Color.dlTextPrimary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
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
        .padding(.vertical, Spacing.sm)
    }

    @ViewBuilder
    private var taskIcon: some View {
        let symbol: String = {
            switch task.taskType {
            case .daily:   return "sun.max.fill"
            case .weekly:  return "calendar.badge.checkmark"
            case .monthly: return "chart.line.uptrend.xyaxis"
            }
        }()
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.dlLavender)
    }
}
