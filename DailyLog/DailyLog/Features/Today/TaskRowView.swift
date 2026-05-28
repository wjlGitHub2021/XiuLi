import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onComplete: () -> Void
    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {
                guard !task.isCompleted else { return }
                isCompleting = true
                onComplete()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .disabled(task.isCompleted || isCompleting)

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
