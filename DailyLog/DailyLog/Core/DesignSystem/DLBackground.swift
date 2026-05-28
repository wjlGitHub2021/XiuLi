import SwiftUI

/// 全局淡紫三段渐变背景。
/// 渐变和光晕都做了加深处理，保证 ScrollView 在透出背景时仍有明显紫色调，
/// 而不是被默认 light scheme 冲淡成白色。
struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.dlLilac, .dlRoseMist, .dlLavenderSoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 280, style: .continuous)
                .fill(.white.opacity(0.24))
                .frame(width: 560, height: 560)
                .blur(radius: 78)
                .offset(x: -200, y: -150)
        }
        .overlay(alignment: .center) {
            RoundedRectangle(cornerRadius: 260, style: .continuous)
                .fill(Color.dlLavender.opacity(0.14))
                .frame(width: 720, height: 420)
                .blur(radius: 72)
        }
        .overlay(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 300, style: .continuous)
                .fill(Color.dlVioletDeep.opacity(0.22))
                .frame(width: 640, height: 640)
                .blur(radius: 88)
                .offset(x: 240, y: 260)
        }
        .overlay {
            Color.white.opacity(0.04)
        }
        .ignoresSafeArea()
    }
}
