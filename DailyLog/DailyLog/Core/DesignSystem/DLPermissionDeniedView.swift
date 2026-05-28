import SwiftUI
import UIKit

struct DLPermissionDeniedView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onLater: (() -> Void)?

    init(icon: String = "photo.on.rectangle",
         title: String,
         subtitle: String,
         onLater: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.onLater = onLater
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
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: Spacing.sm) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("去设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.dlLavender)

                if let onLater {
                    Button("稍后再说", action: onLater)
                        .buttonStyle(.glass)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.panel))
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}
