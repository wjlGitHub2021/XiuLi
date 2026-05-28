import SwiftUI

struct DLGlassBadge: View {
    let icon: String
    let text: String
    var tint: Color = .dlCoin

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(Color.dlTextPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .glassEffect(.regular.tint(tint.opacity(0.35)), in: .capsule)
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.40), lineWidth: 0.5)
        )
    }
}
