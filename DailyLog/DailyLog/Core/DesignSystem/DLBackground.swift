import SwiftUI

/// 全局淡紫三段渐变背景。
/// 渐变和光晕都做了加深处理，保证 ScrollView 在透出背景时仍有明显紫色调，
/// 而不是被默认 light scheme 冲淡成白色。
struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.dlLavenderSoft, .dlRoseMist, .dlPlum],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 520, height: 520)
                .blur(radius: 56)
                .offset(x: -180, y: -160)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.dlLavender.opacity(0.45))
                .frame(width: 620, height: 620)
                .blur(radius: 70)
                .offset(x: 220, y: 260)
        }
        .ignoresSafeArea()
    }
}
