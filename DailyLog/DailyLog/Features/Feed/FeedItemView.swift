import SwiftUI

struct FeedItemView: View {
    let message: FeedMessage
    let currentUserId: UUID?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Type icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(senderLabel)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(message.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let body = message.body, !body.isEmpty {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var iconName: String {
        switch message.type {
        case "task_complete": return "checkmark.circle.fill"
        case "reward_redeem": return "gift.fill"
        case "spin_win":      return "star.fill"
        default:              return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch message.type {
        case "task_complete": return .green
        case "reward_redeem": return Color.dlCoin
        case "spin_win":      return .purple
        default:              return .blue
        }
    }

    private var senderLabel: String {
        guard let currentId = currentUserId else { return "用户" }
        return message.userId == currentId ? "我" : "对方"
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(message.createdAt)
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return "\(Int(interval / 86400))天前"
        }
    }
}
