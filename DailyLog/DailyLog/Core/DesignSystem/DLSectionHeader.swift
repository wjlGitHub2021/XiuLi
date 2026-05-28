import SwiftUI

struct DLSectionHeader: View {
    let icon: String?
    let title: String

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(Color.dlPlum)
            }
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.dlTextSecondary)
        }
        .padding(.horizontal, Spacing.xs)
    }
}
