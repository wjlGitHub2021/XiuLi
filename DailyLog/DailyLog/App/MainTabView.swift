import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "checkmark.circle")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}
