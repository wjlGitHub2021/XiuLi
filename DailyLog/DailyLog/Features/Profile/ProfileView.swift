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
        isLoading = true
        defer { isLoading = false }
        await appState.refreshProfile()
        transactions = (try? await profileService.fetchRecentTransactions(userId: userId)) ?? []
        streak = (try? await profileService.fetchStreak(userId: userId)) ?? 0
        pushEnabled = appState.currentUser?.pushEnabled ?? false
    }

    private func togglePush(_ enabled: Bool) async {
        let service = NotificationService()
        if enabled {
            let granted = await service.requestPermission()
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

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let userId = appState.currentUser?.id else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data),
              let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return }
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        _ = try? await profileService.uploadAvatar(userId: userId, imageData: jpegData)
        await appState.refreshProfile()
    }
}
