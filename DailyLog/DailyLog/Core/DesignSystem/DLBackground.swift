import SwiftUI

struct DLBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.dlLilac, .dlRoseMist, .dlLavenderSoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.dlPlum.opacity(0.38))
                .frame(width: 480, height: 480)
                .blur(radius: 90)
                .offset(x: -160, y: -120)
        }
        .overlay(alignment: .center) {
            Ellipse()
                .fill(Color.dlLavender.opacity(0.22))
                .frame(width: 600, height: 360)
                .blur(radius: 80)
                .offset(y: 60)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.dlVioletDeep.opacity(0.32))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
                .offset(x: 180, y: 200)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.dlRoseMist.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 80, y: -40)
        }
        .ignoresSafeArea()
    }
}
