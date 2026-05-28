import SwiftUI

struct DLGlassCard<Content: View>: View {
    let tint: Color?
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = CornerRadius.card,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.cardInner)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.28)) } ?? .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
