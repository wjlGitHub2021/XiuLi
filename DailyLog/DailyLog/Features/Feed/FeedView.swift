import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var messages: [FeedMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let feedService = FeedService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let errorMessage {
                        DLErrorBanner(message: errorMessage)
                            .padding(.horizontal, Spacing.md)
                    }

                    if isLoading && messages.isEmpty {
                        ProgressView()
                            .padding(.top, 100)
                    } else if messages.isEmpty {
                        DLEmptyState(message: "还没有动态，快去完成任务吧")
                    } else {
                        feedList
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .refreshable { await loadFeed() }
            .navigationTitle("动态")
        }
        .task { await loadFeed() }
    }

    private var feedList: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(spacing: Spacing.sm) {
                ForEach(messages) { message in
                    FeedItemView(message: message, currentUserId: appState.currentUser?.id)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private func loadFeed() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            messages = try await feedService.fetchFeed()
        } catch {
            errorMessage = "加载动态失败，下拉刷新重试"
        }
    }
}
