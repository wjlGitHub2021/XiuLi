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
            RewardsView()
                .tabItem {
                    Label("奖励", systemImage: "gift")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}
