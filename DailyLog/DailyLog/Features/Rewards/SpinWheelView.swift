import SwiftUI

struct SpinWheelView: View {
    @Environment(AppState.self) private var appState
    @State private var spinRewards: [Reward] = []
    @State private var isLoading = false
    @State private var isSpinning = false
    @State private var highlightedIndex: Int = -1
    @State private var spinResult: SpinResponse?
    @State private var showResultAlert = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var spinTimer: Timer?

    private let rewardService = RewardService()
    private let spinCost = 10
    private let outerIndices = [0, 1, 2, 5, 8, 7, 6, 3]

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    var displayRewards: [Reward] {
        let base = spinRewards.prefix(8)
        if base.count < 8 {
            return Array(base) + Array(repeating: Reward(
                id: UUID(), name: "?", description: nil,
                icon: "🎁", cost: nil, type: "spin",
                probability: nil, sortOrder: nil, isActive: true, tier: nil
            ), count: 8 - base.count)
        }
        return Array(base)
    }

    var body: some View {
        ZStack {
            DLBackground()
            ScrollView {
                VStack(spacing: Spacing.section) {
                    DLGlassPageHeader(title: "转盘抽奖", subtitle: "每次消耗 \(spinCost) 金币") {
                        DLGlassBadge(icon: "bitcoinsign.circle.fill",
                                     text: "\(appState.currentUser?.coins ?? 0)",
                                     tint: .dlCoin)
                    }

                    coinCostHeader

                    if isLoading {
                        DLLoadingState()
                            .padding(.horizontal, Spacing.screenHorizontal)
                    } else {
                        wheelGrid
                    }
                }
                .padding(.vertical, Spacing.screenVertical)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("转盘抽奖")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await loadSpinRewards() }
        .alert("抽奖结果", isPresented: $showResultAlert, presenting: spinResult) { _ in
            Button("好的") {}
        } message: { result in
            Text("\(result.rewardIcon) 恭喜获得「\(result.rewardName)」\n获得 \(result.coinsWon) 金币\n剩余金币：\(result.balance)")
        }
        .alert("抽奖失败", isPresented: $showError) {
            Button("好的") {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private var coinCostHeader: some View {
        DLGlassCard(tint: Color.dlCoin) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(Color.dlCoin)
                Text("余额：\(appState.currentUser?.coins ?? 0) 金币")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dlTextPrimary)
                Spacer()
                Text("每次消耗 \(spinCost)")
                    .font(.caption)
                    .foregroundStyle(Color.dlTextSecondary)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var wheelGrid: some View {
        DLGlassCard(tint: Color.dlLavender, cornerRadius: CornerRadius.panel) {
            LazyVGrid(columns: gridItems, spacing: 8) {
                ForEach(0..<9, id: \.self) { index in
                    if index == 4 {
                        startButton
                    } else {
                        let rewardIndex = outerCellRewardIndex(gridIndex: index)
                        let reward = displayRewards[rewardIndex]
                        let isHighlighted = outerIndices.firstIndex(of: index) == highlightedIndex % 8
                        rewardCell(reward: reward, isHighlighted: isHighlighted)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var startButton: some View {
        Button {
            Task { await startSpin() }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSpinning ? "arrow.trianglehead.2.clockwise.rotate.90" : "sparkles")
                    .font(.title2)
                    .rotationEffect(isSpinning ? .degrees(360) : .zero)
                    .animation(isSpinning ? .linear(duration: 0.5).repeatForever(autoreverses: false) : .default, value: isSpinning)
                Text(isSpinning ? "抽奖中" : "开始")
                    .font(.headline.bold())
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(Spacing.sm)
            .glassEffect(.regular.tint(Color.dlLavender.opacity(0.68)).interactive(),
                         in: .rect(cornerRadius: CornerRadius.control))
        }
        .buttonStyle(.plain)
        .disabled(isSpinning || (appState.currentUser?.coins ?? 0) < spinCost)
    }

    private func rewardCell(reward: Reward, isHighlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(reward.icon)
                .font(.title2)
            Text(reward.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.dlTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(Spacing.xs)
        .glassEffect(
            isHighlighted ? .regular.tint(Color.dlCoin.opacity(0.55)).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: CornerRadius.control)
        )
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHighlighted)
    }

    private func outerCellRewardIndex(gridIndex: Int) -> Int {
        guard let pos = outerIndices.firstIndex(of: gridIndex) else { return 0 }
        return pos
    }

    private func loadSpinRewards() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await rewardService.fetchRewards()
            spinRewards = all.filter { $0.type == "spin" }
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    @MainActor
    private func startSpin() async {
        guard !isSpinning else { return }
        isSpinning = true
        defer { isSpinning = false }
        highlightedIndex = 0

        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { t in
            step += 1
            highlightedIndex = step % 8
        }
        RunLoop.main.add(timer, forMode: .common)
        spinTimer = timer

        do {
            let result = try await rewardService.spinWheel(cost: spinCost)
            try? await Task.sleep(nanoseconds: 600_000_000)
            timer.invalidate()
            spinTimer = nil

            if let winIndex = displayRewards.firstIndex(where: {
                $0.name == result.rewardName && $0.cost == result.cost
            }) {
                highlightedIndex = winIndex
            } else if let winIndex = displayRewards.firstIndex(where: { $0.name == result.rewardName }) {
                highlightedIndex = winIndex
            }

            spinResult = result
            showResultAlert = true
            await appState.refreshProfile()
        } catch is CancellationError {
            timer.invalidate()
            spinTimer = nil
            await appState.refreshProfile()
        } catch let urlError as URLError where urlError.code == .cancelled {
            timer.invalidate()
            spinTimer = nil
            await appState.refreshProfile()
        } catch {
            timer.invalidate()
            spinTimer = nil
            await appState.refreshProfile()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
