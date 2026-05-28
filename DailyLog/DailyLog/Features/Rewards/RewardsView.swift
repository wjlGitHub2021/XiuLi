import SwiftUI

struct RewardsView: View {
    @Environment(AppState.self) private var appState
    @State private var rewards: [Reward] = []
    @State private var isLoading = false
    @State private var selectedReward: Reward?
    @State private var showRedeemConfirm = false
    @State private var redeemResult: RedeemResponse?
    @State private var showResultAlert = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSpinWheel = false
    @State private var isRedeeming = false

    private let rewardService = RewardService()

    var directRewards: [Reward] {
        rewards.filter { $0.type == "direct" && $0.cost != nil }
    }

    private var tierOrder: [String] { ["basic", "rare", "legendary", "sacred", "_other"] }

    private func rewardsForTier(_ tier: String) -> [Reward] {
        if tier == "_other" {
            return directRewards.filter { $0.tier == nil || !["basic", "rare", "legendary", "sacred"].contains($0.tier!) }
                .sorted { ($0.cost ?? 0) < ($1.cost ?? 0) }
        }
        return directRewards.filter { $0.tier == tier }.sorted { ($0.cost ?? 0) < ($1.cost ?? 0) }
    }

    private func tierDisplayName(_ tier: String) -> String {
        switch tier {
        case "basic": return "基础"
        case "rare": return "稀有"
        case "legendary": return "传说"
        case "sacred": return "神圣"
        default: return "其他"
        }
    }

    private func tierIcon(_ tier: String) -> String {
        switch tier {
        case "basic": return "circle"
        case "rare": return "diamond"
        case "legendary": return "star"
        case "sacred": return "crown"
        default: return "gift"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        DLGlassPageHeader(title: "奖励", subtitle: "用金币兑换一点开心") {
                            DLGlassBadge(icon: "bitcoinsign.circle.fill",
                                         text: "\(appState.currentUser?.coins ?? 0)",
                                         tint: .dlCoin)
                        }
                        coinBalanceHeader
                        spinWheelCard
                        directRewardsSection
                    }
                    .padding(.vertical, Spacing.screenVertical)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable { await loadRewards() }
            .navigationDestination(isPresented: $showSpinWheel) {
                SpinWheelView()
            }
        }
        .task { await loadRewards() }
        .alert("确认兑换", isPresented: $showRedeemConfirm, presenting: selectedReward) { reward in
            Button("取消", role: .cancel) {}
            Button("兑换") {
                Task { await redeem(reward: reward) }
            }
            .disabled(isRedeeming)
        } message: { reward in
            Text("消耗 \(reward.cost ?? 0) 金币兑换「\(reward.name)」？")
        }
        .alert("兑换成功", isPresented: $showResultAlert, presenting: redeemResult) { _ in
            Button("好的") {}
        } message: { result in
            Text("已兑换「\(result.rewardName)」\n剩余金币：\(result.balance)")
        }
        .alert("兑换失败", isPresented: $showError) {
            Button("好的") {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private var coinBalanceHeader: some View {
        DLGlassCard(tint: Color.dlCoin, cornerRadius: CornerRadius.panel) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.dlCoin.opacity(0.18))
                        .frame(width: 58, height: 58)
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.dlCoin)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appState.currentUser?.coins ?? 0) 金币")
                        .font(.title.bold())
                        .foregroundStyle(Color.dlTextPrimary)
                    Text("我的余额")
                        .font(.subheadline)
                        .foregroundStyle(Color.dlTextSecondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var spinWheelCard: some View {
        DLGlassCard(tint: Color.dlLavender, cornerRadius: CornerRadius.panel) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Label("转盘抽奖", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(Color.dlTextPrimary)
                    Spacer()
                    Text("每次 10 金币")
                        .font(.subheadline)
                        .foregroundStyle(Color.dlTextSecondary)
                }
                Button {
                    showSpinWheel = true
                } label: {
                    Label("开始转盘", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.dlLavender)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var directRewardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            if isLoading {
                VStack(spacing: Spacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in DLSkeletonRow() }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            } else if directRewards.isEmpty {
                DLEmptyState(icon: "gift", title: "暂无可兑换奖励")
                    .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                ForEach(tierOrder, id: \.self) { tier in
                    let tierRewards = rewardsForTier(tier)
                    if !tierRewards.isEmpty {
                        tierSection(tier: tier, rewards: tierRewards)
                    }
                }
            }
        }
    }

    private func tierSection(tier: String, rewards: [Reward]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            DLSectionHeader(tierDisplayName(tier), icon: tierIcon(tier))
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)
            VStack(spacing: Spacing.xs) {
                ForEach(rewards) { reward in
                    rewardRow(reward)
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.card))
            .dlGlassChrome(cornerRadius: CornerRadius.card)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private func rewardRow(_ reward: Reward) -> some View {
        HStack(spacing: Spacing.md) {
            Text(reward.icon)
                .font(.title2)
                .frame(width: 42, height: 42)
                .glassEffect(.regular.tint(Color.dlLavender.opacity(0.14)), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.body.bold())
                    .foregroundStyle(Color.dlTextPrimary)
                    .lineLimit(2)
                if let desc = reward.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Spacing.sm)
            Button {
                selectedReward = reward
                showRedeemConfirm = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundStyle(Color.dlCoin)
                    Text("\(reward.cost ?? 0)")
                        .foregroundStyle(Color.dlTextPrimary)
                    Text("兑换")
                        .foregroundStyle(Color.dlLavender)
                }
                .font(.caption.bold())
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 7)
            }
            .buttonStyle(.glass)
            .tint(.dlLavender)
            .disabled(isRedeeming || (reward.cost ?? 0) > (appState.currentUser?.coins ?? 0))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func loadRewards() async {
        isLoading = true
        defer { isLoading = false }
        do {
            rewards = try await rewardService.fetchRewards()
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    @MainActor
    private func redeem(reward: Reward) async {
        guard !isRedeeming else { return }
        isRedeeming = true
        defer { isRedeeming = false }

        do {
            let result = try await rewardService.redeemReward(rewardId: reward.id)
            redeemResult = result
            showResultAlert = true
            await appState.refreshProfile()
        } catch is CancellationError {
            await appState.refreshProfile()
        } catch let urlError as URLError where urlError.code == .cancelled {
            await appState.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            await appState.refreshProfile()
        }
    }
}
