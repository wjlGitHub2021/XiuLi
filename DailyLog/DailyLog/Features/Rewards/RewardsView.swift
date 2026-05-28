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
    // Bug #5: 并发锁，防止双击 / 并发兑换
    @State private var isRedeeming = false

    private let rewardService = RewardService()

    // Bug #27: 过滤掉 cost == nil 的 direct 奖励（DB schema 兼容）
    var directRewards: [Reward] {
        rewards.filter { $0.type == "direct" && $0.cost != nil }
    }

    var body: some View {
        ZStack {
            DLBackground()
            NavigationStack {
                ScrollView {
                    GlassEffectContainer(spacing: 16.0) {
                        VStack(spacing: Spacing.md) {
                            coinBalanceHeader
                            spinWheelCard
                            directRewardsSection
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.vertical, Spacing.sm)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("奖励")
                .toolbarBackground(.hidden, for: .navigationBar)
                .refreshable { await loadRewards() }
                .navigationDestination(isPresented: $showSpinWheel) {
                    SpinWheelView()
                }
            }
        }
        .task { await loadRewards() }
        .alert("确认兑换", isPresented: $showRedeemConfirm, presenting: selectedReward) { reward in
            Button("取消", role: .cancel) {}
            // Bug #5: 禁用并发提交，guard isRedeeming 在 redeem 内原子完成
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
        HStack(spacing: Spacing.sm) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.dlCoin)
            Text("\(appState.currentUser?.coins ?? 0) 金币")
                .font(.title2.bold())
            Spacer()
            Text("我的余额")
                .font(.subheadline)
                .foregroundStyle(Color.dlTextSecondary)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(Color.dlCoin.opacity(0.32)), in: .rect(cornerRadius: CornerRadius.card))
    }

    private var spinWheelCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.dlLavender)
                Text("转盘抽奖")
                    .font(.headline)
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
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.glass)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(Color.dlLavender.opacity(0.32)), in: .rect(cornerRadius: CornerRadius.card))
    }

    private var directRewardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            DLSectionHeader("直接兑换", icon: "gift")
                .padding(.horizontal, Spacing.sm)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
            } else if directRewards.isEmpty {
                DLEmptyState(
                    icon: "gift",
                    title: "暂无可兑换奖励"
                )
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(directRewards) { reward in
                        rewardRow(reward)
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.smallCard))
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
                    .foregroundStyle(Color.dlTextPrimary)
                if let desc = reward.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Color.dlTextSecondary)
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
            // Bug #5: 余额不足时禁用兑换按钮
            .disabled(isRedeeming || (reward.cost ?? 0) > (appState.currentUser?.coins ?? 0))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // Bug #18: try? 改 do/catch，加载失败用 alert 展示错误
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

    // Bug #5: @MainActor 保证并发锁原子 check-and-set；Bug #16: catch 也刷新余额
    @MainActor
    private func redeem(reward: Reward) async {
        // 原子检查：第一个 await 之前同步设置锁
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
            // Bug #16: 即使请求失败（超时后服务端可能已扣），也刷新余额保证最终一致
            await appState.refreshProfile()
        }
    }
}
