import SwiftUI

struct DLSkeletonRow: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Capsule()
                    .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                    .frame(height: 14)
                    .frame(maxWidth: 160)
                Capsule()
                    .fill(Color.white.opacity(pulse ? 0.5 : 0.3))
                    .frame(height: 10)
                    .frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
