import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "checkmark.circle") }
            FeedView()
                .tabItem { Label("动态", systemImage: "chart.bar") }
            RewardsView()
                .tabItem { Label("奖励", systemImage: "gift") }
            ProfileView()
                .tabItem { Label("我的", systemImage: "person") }
        }
        .tint(.dlLavender)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
