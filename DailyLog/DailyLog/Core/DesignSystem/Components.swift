import SwiftUI

struct DLEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.lg)
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
