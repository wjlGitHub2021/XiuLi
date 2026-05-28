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
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let errorMessage {
                        feedErrorBanner(message: errorMessage)
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

    @ViewBuilder
    private func feedErrorBanner(message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.sm)
        .background(.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.orange.opacity(0.4), lineWidth: 1)
        )
    }

    private func loadFeed() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            messages = try await feedService.fetchFeed()
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
