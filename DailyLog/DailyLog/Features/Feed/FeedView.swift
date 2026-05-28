import SwiftUI
import Auth

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var messages: [FeedMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let feedService = FeedService()

    var body: some View {
        ZStack {
            DLBackground()
            NavigationStack {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if let errorMessage {
                            DLErrorBanner(message: errorMessage)
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        if isLoading && messages.isEmpty {
                            ProgressView()
                                .padding(.top, 100)
                        } else if messages.isEmpty {
                            DLEmptyState(
                                icon: "bubble.left.and.bubble.right",
                                title: "还没有动态",
                                subtitle: "快去完成任务吧"
                            )
                        } else {
                            feedList
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .scrollContentBackground(.hidden)
                .refreshable { await loadFeed() }
                .navigationTitle("动态")
            }
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
                        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
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
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            let desc = error.localizedDescription.lowercased()
            let isAuthError = error is AuthError
                || desc.contains("401")
                || desc.contains("unauthorized")
                || desc.contains("jwt")
            if isAuthError {
                // 登录态失效，退回登录页
                await appState.signOut()
                return
            }
            // 保留旧数据，只展示刷新失败提示
            errorMessage = "刷新失败，数据可能不是最新，下拉重试"
        }
    }
}
