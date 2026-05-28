import SwiftUI

/// 全局淡紫三段渐变背景。
struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.dlLilac, .dlRoseMist, .dlLavenderSoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 520, height: 520)
                .blur(radius: 56)
                .offset(x: -180, y: -160)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.dlLavender.opacity(0.22))
                .frame(width: 620, height: 620)
                .blur(radius: 70)
                .offset(x: 220, y: 260)
        }
        .ignoresSafeArea()
    }
}
