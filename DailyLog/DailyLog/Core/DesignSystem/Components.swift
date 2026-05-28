import SwiftUI

struct DLEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String = "tray",
         title: String,
         subtitle: String? = nil,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    // 兼容旧调用 DLEmptyState(message:)
    init(message: String) {
        self.init(icon: "tray", title: message, subtitle: nil, actionTitle: nil, action: nil)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dlLavender.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.dlLavender)
            }
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.dlTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.dlTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.dlLavender)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.panel))
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.lg)
    }
}

struct DLErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.dlWarning)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextPrimary)
            }
            if let onRetry {
                Button(action: onRetry) {
                    Label("重新加载", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.dlWarning.opacity(0.28)),
                     in: .rect(cornerRadius: CornerRadius.control))
    }
}

struct DLLoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .font(.headline)
        .buttonStyle(.glassProminent)
        .disabled(isLoading)
    }
}
