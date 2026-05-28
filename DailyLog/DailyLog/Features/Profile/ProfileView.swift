import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var transactions: [CoinTransaction] = []
    @State private var isLoading = false
    @State private var showLogoutConfirm = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 16.0) {
                    VStack(spacing: Spacing.md) {
                        profileHeader
                        statsSection
                        transactionsSection
                        settingsSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .refreshable { await loadData() }
            .navigationTitle("我的")
            .confirmationDialog("确认退出登录？", isPresented: $showLogoutConfirm) {
                Button("退出登录", role: .destructive) {
                    Task { await appState.signOut() }
                }
            }
        }
        .task { await loadData() }
    }

    private var profileHeader: some View {
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
            Spacer()
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(.blue), in: .rect(cornerRadius: 20))
    }

    private var statsSection: some View {
        HStack {
            Label("完成任务", systemImage: "checkmark.circle")
            Spacer()
            Text("\(appState.currentUser?.totalCompleted ?? 0) 次")
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("最近金币记录")
                .font(.headline)
                .padding(.horizontal, Spacing.sm)

            if transactions.isEmpty {
                Text("还没有金币记录")
                    .foregroundStyle(.secondary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            } else {
                VStack(spacing: Spacing.xs) {
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
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Label("消息推送", systemImage: "bell")
                Spacer()
                Text("稍后开放")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.md)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))

            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                    Spacer()
                }
                .padding(Spacing.md)
            }
            .glassEffect(.regular.tint(.red), in: .rect(cornerRadius: 16))
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
