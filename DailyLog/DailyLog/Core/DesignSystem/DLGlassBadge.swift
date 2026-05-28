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
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .glassEffect(.regular.tint(tint.opacity(0.35)), in: .capsule)
    }
}
