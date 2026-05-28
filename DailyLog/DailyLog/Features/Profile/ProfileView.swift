import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var transactions: [CoinTransaction] = []
    @State private var isLoading = false
    @State private var showLogoutConfirm = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                statsSection
                transactionsSection
                settingsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的")
            .refreshable { await loadData() }
            .confirmationDialog("确认退出登录？", isPresented: $showLogoutConfirm) {
                Button("退出登录", role: .destructive) {
                    Task { await appState.signOut() }
                }
            }
        }
        .task { await loadData() }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: Spacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(appState.currentUser?.nickname ?? "加载中")
                        .font(.title2.bold())
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(Color.dlCoin)
                        Text("\(appState.currentUser?.coins ?? 0) 金币")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var statsSection: some View {
        Section("统计") {
            HStack {
                Label("完成任务", systemImage: "checkmark.circle")
                Spacer()
                Text("\(appState.currentUser?.totalCompleted ?? 0) 次")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var transactionsSection: some View {
        Section("最近金币记录") {
            if transactions.isEmpty {
                Text("还没有金币记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(transactions) { tx in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.reasonDisplay)
                                .font(.body)
                            Text(tx.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(tx.amount > 0 ? "+\(tx.amount)" : "\(tx.amount)")
                            .font(.body.bold())
                            .foregroundStyle(tx.amount > 0 ? .green : .red)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        Section("设置") {
            HStack {
                Label("消息推送", systemImage: "bell")
                Spacer()
                Text("稍后开放")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private func loadData() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        await appState.refreshProfile()
        transactions = (try? await profileService.fetchRecentTransactions(userId: userId)) ?? []
    }
}
