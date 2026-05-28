import SwiftUI

struct DLEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String = "tray",
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    init(message: String) {
        self.init(icon: "tray", title: message)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dlLavender.opacity(0.16))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
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
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.panel))
    }
}

struct DLErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)?

    init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dlWarning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let onRetry {
                    Button(action: onRetry) {
                        Label("重新加载", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.dlWarning.opacity(0.24)),
                     in: .rect(cornerRadius: CornerRadius.smallCard))
    }
}

struct DLLoadingState: View {
    var title: String = "加载中"
    var subtitle: String? = "正在同步最新数据"

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(.dlLavender)
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.dlTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(Color.dlLavender.opacity(0.14)),
                     in: .rect(cornerRadius: CornerRadius.panel))
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
        .tint(.dlLavender)
        .disabled(isLoading)
    }
}

struct DLGlassTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.dlTextSecondary)
                .frame(width: 20)
                .padding(.top, axis == .vertical ? 3 : 0)
            TextField(placeholder, text: $text, axis: axis)
                .foregroundStyle(Color.dlTextPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 13)
        .glassEffect(.regular.tint(Color.white.opacity(0.08)),
                     in: .rect(cornerRadius: CornerRadius.control))
    }
}

struct DLGlassPageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.dlTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.dlTextSecondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.md)
    }
}

extension View {
    func dlPageChrome() -> some View {
        self
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(Color.dlLavender)
    }
}
