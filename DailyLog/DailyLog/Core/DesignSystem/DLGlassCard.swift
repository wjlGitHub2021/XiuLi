import SwiftUI

struct DLGlassCard<Content: View>: View {
    let tint: Color?
    let cornerRadius: CGFloat
    let padding: CGFloat
    var elevated: Bool
    @ViewBuilder var content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = CornerRadius.card,
        padding: CGFloat = Spacing.cardInner,
        elevated: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.26)).interactive() } ?? .regular.interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 0.75)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 40)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(elevated ? 0.10 : 0), radius: 12, y: 6)
            .shadow(color: (tint ?? .clear).opacity(elevated ? 0.08 : 0), radius: 8, y: 4)
    }
}
