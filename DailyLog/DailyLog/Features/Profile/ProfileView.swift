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
    @State private var isInitializing = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var notificationService = NotificationService()
    @State private var localAvatarImage: UIImage?
    @State private var showNicknameSheet = false
    @State private var editingNickname = ""

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()
                ScrollView {
                    GlassEffectContainer(spacing: 16.0) {
                        VStack(spacing: Spacing.section) {
                            DLGlassPageHeader(title: "我的", subtitle: "账户、金币和提醒") {
                                DLGlassBadge(icon: "bitcoinsign.circle.fill",
                                             text: "\(appState.currentUser?.coins ?? 0)",
                                             tint: .dlCoin)
                            }
                            profileHeader
                            statsSection
                            transactionsSection
                            settingsSection
                        }
                        .padding(.vertical, Spacing.screenVertical)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .refreshable { await loadData() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .confirmationDialog("确认退出登录？", isPresented: $showLogoutConfirm) {
                Button("退出登录", role: .destructive) {
                    Task { await appState.signOut() }
                }
            }
        }
        .task { await loadData() }
        .alert("加载失败", isPresented: $showError) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("修改昵称", isPresented: $showNicknameSheet) {
            TextField("输入新昵称", text: $editingNickname)
            Button("取消", role: .cancel) {}
            Button("保存") {
                Task { await saveNickname() }
            }
        } message: {
            Text("请输入新的昵称")
        }
    }

    private var avatarView: some View {
        Group {
            if let localImage = localAvatarImage {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
            } else if let avatarUrl = appState.currentUser?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            if isUploadingAvatar {
                ProgressView()
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
                    .offset(x: 4, y: 4)
            } else {
                Image(systemName: "camera.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .padding(7)
                    .background(Color.dlLavender.opacity(0.95), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 1))
                    .offset(x: 4, y: 4)
            }
        }
        .shadow(color: Color.dlLavender.opacity(0.14), radius: 18, x: 0, y: 8)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.dlLavenderSoft.opacity(0.95), Color.dlRoseMist.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.dlPlum)
        }
    }

    private var profileHeader: some View {
        DLGlassCard(tint: Color.dlLavender) {
            HStack(spacing: Spacing.md) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    avatarView
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    Task { await handlePhotoSelection(newValue) }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Button {
                        editingNickname = appState.currentUser?.nickname ?? ""
                        showNicknameSheet = true
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(appState.currentUser?.nickname ?? "加载中")
                                .font(.title2.bold())
                                .foregroundStyle(Color.dlTextPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color.dlTextSecondary.opacity(0.65))
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(Color.dlCoin)
                        Text("\(appState.currentUser?.coins ?? 0) 金币")
                            .font(.headline)
                            .foregroundStyle(Color.dlTextPrimary)
                    }

                    Text("上传头像、查看金币记录和推送设置")
                        .font(.footnote)
                        .foregroundStyle(Color.dlTextSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var statsSection: some View {
        HStack(spacing: Spacing.md) {
            statTile(
                icon: "checkmark.circle.fill",
                iconTint: Color.dlSuccess,
                value: "\(appState.currentUser?.totalCompleted ?? 0)",
                unit: "次",
                label: "完成任务"
            )
            statTile(
                icon: "flame.fill",
                iconTint: Color.dlWarning,
                value: "\(streak)",
                unit: "天",
                label: "连续打卡"
            )
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func statTile(icon: String, iconTint: Color, value: String, unit: String, label: String) -> some View {
        DLGlassCard(tint: iconTint, padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(iconTint)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.bold())
                        .foregroundStyle(Color.dlTextPrimary)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            DLSectionHeader("最近金币记录", icon: "clock")
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)

            if isLoading && transactions.isEmpty {
                VStack(spacing: Spacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        DLSkeletonRow()
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            } else if transactions.isEmpty {
                DLEmptyState(
                    icon: "list.bullet.rectangle",
                    title: "还没有金币记录",
                    subtitle: "完成任务或兑换奖励后，记录会显示在这里"
                )
                .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                        transactionRow(tx)
                        if index < transactions.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.42))
                                .padding(.leading, 72)
                        }
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.card))
                .dlGlassChrome(cornerRadius: CornerRadius.card)
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }

    private func transactionRow(_ tx: CoinTransaction) -> some View {
        let isPositive = tx.amount > 0
        let symbol: String = isPositive ? "checkmark.circle.fill" : "gift.fill"
        let tint: Color = isPositive ? Color.dlSuccess : Color.dlError
        return HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(tx.reasonDisplay)
                    .font(.body)
                    .foregroundStyle(Color.dlTextPrimary)
                    .lineLimit(1)
                Text(tx.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Color.dlTextSecondary)
            }
            Spacer(minLength: 10)
            HStack(spacing: 4) {
                Text(isPositive ? "+\(tx.amount)" : "\(tx.amount)")
                    .font(.body.bold())
                    .foregroundStyle(isPositive ? Color.dlSuccess : Color.dlError)
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(Color.dlCoin)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var settingsSection: some View {
        VStack(spacing: Spacing.lg) {
            DLGlassCard(tint: Color.dlLavender) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.dlLavender.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "bell.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.dlLavender)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("消息推送")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.dlTextPrimary)
                        Text(pushEnabled ? "已开启提醒" : "关闭后不会收到通知")
                            .font(.caption)
                            .foregroundStyle(Color.dlTextSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $pushEnabled)
                        .labelsHidden()
                        .tint(Color.dlLavender)
                }
                .onChange(of: pushEnabled) { _, newValue in
                    guard !isInitializing else { return }
                    Task { await togglePush(newValue) }
                }
            }

            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("退出登录")
                        .font(.body.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Color.dlError)
            }
            .buttonStyle(.glass)
            .tint(.dlError)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func loadData() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        isInitializing = true
        // Bug #14：保留旧数据直到新数据回来，避免清空再填导致的闪烁
        defer { isLoading = false }

        // 性能优化：三个请求并行发送，耗时从串行 ~300-500ms 降为最慢那个 ~150ms
        async let _ = appState.refreshProfile()
        async let txs = profileService.fetchRecentTransactions(userId: userId)
        async let s = profileService.fetchStreak(userId: userId)

        do {
            transactions = try await txs
            streak = try await s
        } catch is CancellationError {
            // 切 tab / 视图重组导致的 Task 取消是良性的，不弹错误
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        pushEnabled = appState.currentUser?.pushEnabled ?? false
        // Bug #15: 赋值完成后才允许 onChange 触发 DB 写
        isInitializing = false
    }

    @MainActor
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
        do {
            try await AppSupabase.client.from("users")
                .update(["push_enabled": enabled])
                .eq("id", value: userId.uuidString)
                .execute()
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "推送开关更新失败：\(error.localizedDescription)"
            showError = true
        }
        await appState.refreshProfile()
        isInitializing = true
        pushEnabled = appState.currentUser?.pushEnabled ?? false
        isInitializing = false
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
            // Bug #4 后续：成功后立刻用本地 UIImage 占位，避免 AsyncImage 走 CDN 冷启动等几秒
            if let img = UIImage(data: data) {
                localAvatarImage = img
            }
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        await appState.refreshProfile()
    }

    private func saveNickname() async {
        let trimmed = editingNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let userId = appState.currentUser?.id else { return }
        do {
            try await AppSupabase.client.from("users")
                .update(["nickname": trimmed])
                .eq("id", value: userId.uuidString)
                .execute()
            await appState.refreshProfile()
        } catch is CancellationError {
        } catch {
            errorMessage = "修改昵称失败：\(error.localizedDescription)"
            showError = true
        }
    }
}
