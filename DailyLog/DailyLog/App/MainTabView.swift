import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "checkmark.circle")
                }
            FeedView()
                .tabItem {
                    Label("动态", systemImage: "bubble.left.and.bubble.right")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}
