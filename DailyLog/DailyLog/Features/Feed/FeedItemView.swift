import SwiftUI

struct FeedItemView: View {
    let message: FeedMessage
    let currentUserId: UUID?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Type icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(senderLabel)
                        .font(.caption.bold())
                        .foregroundStyle(Color.dlTextSecondary)
                    Spacer()
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(Color.dlTextSecondary.opacity(0.7))
                }

                Text(message.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dlTextPrimary)

                if let body = message.body, !body.isEmpty {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
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
        case "task_complete": return Color.dlSuccess
        case "reward_redeem": return Color.dlCoin
        case "spin_win":      return Color.dlLavender
        default:              return Color.dlPlum
        }
    }

    private var senderLabel: String {
        guard let currentId = currentUserId else { return "用户" }
        return message.userId == currentId ? "我" : "对方"
    }

    private var relativeTime: String {
        let interval = max(0, Date().timeIntervalSince(message.createdAt))
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
