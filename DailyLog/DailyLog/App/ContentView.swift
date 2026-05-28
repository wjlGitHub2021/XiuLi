import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ZStack {
                    DLBackground()
                    DLLoadingState()
                        .padding(.horizontal, Spacing.screenHorizontal)
                }
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await appState.restoreSession()
        }
    }
}
