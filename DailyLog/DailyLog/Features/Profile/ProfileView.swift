import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var transactions: [CoinTransaction] = []
    @State private var isLoading = false
    @State private var showLogoutConfirm = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    @State private var streak: Int = 0
    @State private var pushEnabled: Bool = false
    // Bug #15: 防止 loadData 初始赋值 pushEnabled 时误触发 DB 写
    @State private var isInitializing = true
    // Bug #25: 错误反馈
    @State private var errorMessage: String?
    @State private var showError = false
    // 附加任务 nit: 复用 NotificationService 实例
    @State private var notificationService = NotificationService()

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
        // Bug #25: 错误弹窗
        .alert("加载失败", isPresented: $showError) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var avatarView: some View {
        Group {
            if let avatarUrl = appState.currentUser?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if isUploadingAvatar {
                ProgressView()
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: Spacing.md) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                avatarView
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task { await handlePhotoSelection(newValue) }
            }
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
        VStack(spacing: Spacing.sm) {
            HStack {
                Label("完成任务", systemImage: "checkmark.circle")
                Spacer()
                Text("\(appState.currentUser?.totalCompleted ?? 0) 次")
                    .foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Label("连续打卡", systemImage: "flame")
                Spacer()
                Text("\(streak) 天")
                    .foregroundStyle(.secondary)
            }
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
                Toggle("", isOn: $pushEnabled)
                    .labelsHidden()
            }
            .padding(Spacing.md)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: pushEnabled) { _, newValue in
                // Bug #15: loadData 初始化阶段不触发 DB 写
                guard !isInitializing else { return }
                Task { await togglePush(newValue) }
            }

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
        // Nit #14: 先置 isLoading=true，再清空，loading 态盖住空列表避免闪烁
        isLoading = true
        transactions = []
        streak = 0
        isInitializing = true
        defer { isLoading = false }
        // Bug #13: 强制拉最新 users 数据，保证金币余额一致性
        await appState.refreshProfile()
        do {
            // Bug #25: try? 改为 do/catch，错误时展示 alert
            transactions = try await profileService.fetchRecentTransactions(userId: userId)
            streak = try await profileService.fetchStreak(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        pushEnabled = appState.currentUser?.pushEnabled ?? false
        // Bug #15: 赋值完成后才允许 onChange 触发 DB 写
        isInitializing = false
    }

    private func togglePush(_ enabled: Bool) async {
        // 附加任务 nit: 使用复用的 notificationService 实例
        if enabled {
            let granted = await notificationService.requestPermission()
            if !granted {
                pushEnabled = false
                return
            }
        }
        guard let userId = appState.currentUser?.id else { return }
        try? await AppSupabase.client.from("users")
            .update(["push_enabled": enabled])
            .eq("id", value: userId.uuidString)
            .execute()
        await appState.refreshProfile()
    }

    @MainActor
    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        // Fix #4: @MainActor 确保 check-and-set 在同一个 run loop tick 内同步完成，彻底消除 TOCTOU
        if isUploadingAvatar { return }
        isUploadingAvatar = true  // 必须在第一个 await 之前
        defer { isUploadingAvatar = false }
        guard let item, let userId = appState.currentUser?.id else { return }
        // Bug #3: 原始 Data 直接传给 ProfileService，由 Service 负责降采样+压缩
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        do {
            // Bug #25: 上传失败时展示错误
            _ = try await profileService.uploadAvatar(userId: userId, imageData: data)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        await appState.refreshProfile()
    }
}
