import SwiftUI

struct DLGlassCard<Content: View>: View {
    let tint: Color?
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = CornerRadius.card,
        padding: CGFloat = Spacing.cardInner,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.26)).interactive() } ?? .regular.interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
