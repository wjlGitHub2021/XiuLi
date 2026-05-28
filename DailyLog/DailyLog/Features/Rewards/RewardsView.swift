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

    private let rewardService = RewardService()

    var directRewards: [Reward] {
        rewards.filter { $0.type == "direct" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 16.0) {
                    VStack(spacing: Spacing.md) {
                        coinBalanceHeader
                        spinWheelCard
                        directRewardsSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .navigationTitle("奖励")
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
        HStack(spacing: Spacing.sm) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.dlCoin)
            Text("\(appState.currentUser?.coins ?? 0) 金币")
                .font(.title2.bold())
            Spacer()
            Text("我的余额")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(.yellow), in: .rect(cornerRadius: 20))
    }

    private var spinWheelCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("转盘抽奖")
                    .font(.headline)
                Spacer()
                Text("每次 10 金币")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button {
                showSpinWheel = true
            } label: {
                Label("开始转盘", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.glass)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(.purple), in: .rect(cornerRadius: 20))
    }

    private var directRewardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("直接兑换")
                .font(.headline)
                .padding(.horizontal, Spacing.sm)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            } else if directRewards.isEmpty {
                Text("暂无可兑换奖励")
                    .foregroundStyle(.secondary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(directRewards) { reward in
                        rewardRow(reward)
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }
        }
    }

    private func rewardRow(_ reward: Reward) -> some View {
        HStack(spacing: Spacing.md) {
            Text(reward.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.body.bold())
                if let desc = reward.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                selectedReward = reward
                showRedeemConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundStyle(Color.dlCoin)
                    Text("\(reward.cost ?? 0)")
                    Text("兑换")
                }
                .font(.subheadline.bold())
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func loadRewards() async {
        isLoading = true
        defer { isLoading = false }
        rewards = (try? await rewardService.fetchRewards()) ?? []
    }

    private func redeem(reward: Reward) async {
        do {
            let result = try await rewardService.redeemReward(rewardId: reward.id)
            redeemResult = result
            showResultAlert = true
            await appState.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
