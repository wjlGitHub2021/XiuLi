import SwiftUI
import Auth

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var messages: [FeedMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let feedService = FeedService()

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        DLGlassPageHeader(title: "动态", subtitle: "最近发生了什么") {
                            DLGlassBadge(icon: "bubble.left.and.bubble.right", text: "\(messages.count)", tint: .dlLavender)
                        }

                        if let errorMessage {
                            DLErrorBanner(message: errorMessage, onRetry: {
                                Task { await loadFeed() }
                            })
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        if isLoading && messages.isEmpty {
                            DLLoadingState()
                                .padding(.horizontal, Spacing.screenHorizontal)
                        } else if messages.isEmpty {
                            DLEmptyState(
                                icon: "bubble.left.and.bubble.right",
                                title: "还没有动态",
                                subtitle: "快去完成任务吧"
                            )
                            .padding(.horizontal, Spacing.screenHorizontal)
                        } else {
                            feedList
                        }
                    }
                    .padding(.vertical, Spacing.screenVertical)
                }
                .scrollContentBackground(.hidden)
            }
            .refreshable { await loadFeed() }
            .navigationTitle("动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task { await loadFeed() }
    }

    private var feedList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(messages) { message in
                DLGlassCard(tint: tint(for: message), cornerRadius: CornerRadius.smallCard) {
                    FeedItemView(message: message, currentUserId: appState.currentUser?.id)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }

    private func tint(for message: FeedMessage) -> Color {
        switch message.type {
        case "task_complete": return .dlSuccess
        case "reward_redeem": return .dlCoin
        case "spin_win": return .dlLavender
        default: return .dlPlum
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
                await appState.signOut()
                return
            }
            errorMessage = "刷新失败，数据可能不是最新，下拉重试"
        }
    }
}
