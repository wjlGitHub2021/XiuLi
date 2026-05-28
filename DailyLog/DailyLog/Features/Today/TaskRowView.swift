import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isToday: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {
                guard !task.isCompleted && isToday else { return }
                onComplete()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : (isToday ? .primary : .secondary))
            }
            .buttonStyle(.glass)
            .disabled(task.isCompleted || !isToday)
            .accessibilityLabel(task.isCompleted ? "已完成" : (isToday ? "标记为完成" : "只能完成今日任务"))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                if task.isCompleted {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(Color.dlCoin)
                Text("+\(task.coinsEarned)")
                    .font(.subheadline.bold())
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.dlCoin)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}
