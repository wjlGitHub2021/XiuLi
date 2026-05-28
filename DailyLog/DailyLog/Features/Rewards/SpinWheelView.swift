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

    // 3x3 grid: indices 0-8, center (index 4) is the Start button
    // Spin animation cycles through the 8 outer cells
    private let outerIndices = [0, 1, 2, 5, 8, 7, 6, 3]

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    // Pad or trim spinRewards to exactly 8 items for the outer cells
    var displayRewards: [Reward] {
        let base = spinRewards.prefix(8)
        if base.count < 8 {
            return Array(base) + Array(repeating: Reward(
                id: UUID(), name: "?", description: nil,
                icon: "🎁", cost: nil, type: "spin",
                probability: nil, sortOrder: nil, isActive: true
            ), count: 8 - base.count)
        }
        return Array(base)
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16.0) {
                VStack(spacing: Spacing.md) {
                    coinCostHeader
                    wheelGrid
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
        }
        .navigationTitle("转盘抽奖")
        .navigationBarTitleDisplayMode(.inline)
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
        HStack(spacing: Spacing.sm) {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundStyle(Color.dlCoin)
            Text("余额：\(appState.currentUser?.coins ?? 0) 金币")
                .font(.subheadline)
            Spacer()
            Text("每次消耗 \(spinCost) 金币")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(.yellow), in: .rect(cornerRadius: 16))
    }

    private var wheelGrid: some View {
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
        .padding(Spacing.sm)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var startButton: some View {
        Button {
            guard !isSpinning else { return }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(Spacing.sm)
        }
        .buttonStyle(.glass)
        .disabled(isSpinning)
    }

    private func rewardCell(reward: Reward, isHighlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(reward.icon)
                .font(.title2)
            Text(reward.name)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(Spacing.xs)
        .glassEffect(
            isHighlighted ? .regular.tint(.yellow) : .regular,
            in: .rect(cornerRadius: 12)
        )
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHighlighted)
    }

    // Maps grid index (0-8, skipping 4) to reward array index (0-7)
    private func outerCellRewardIndex(gridIndex: Int) -> Int {
        guard let pos = outerIndices.firstIndex(of: gridIndex) else { return 0 }
        return pos
    }

    private func loadSpinRewards() async {
        isLoading = true
        defer { isLoading = false }
        let all = (try? await rewardService.fetchRewards()) ?? []
        spinRewards = all.filter { $0.type == "spin" }
    }

    private func startSpin() async {
        isSpinning = true
        highlightedIndex = 0

        // Start animation timer
        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { t in
            step += 1
            highlightedIndex = step % 8
        }
        RunLoop.main.add(timer, forMode: .common)
        spinTimer = timer

        do {
            let result = try await rewardService.spinWheel(cost: spinCost)
            // Stop animation after a short delay
            try? await Task.sleep(nanoseconds: 600_000_000)
            timer.invalidate()
            spinTimer = nil

            // Find winning cell and highlight it
            if let winIndex = displayRewards.firstIndex(where: { $0.name == result.rewardName }) {
                highlightedIndex = winIndex
            }

            isSpinning = false
            spinResult = result
            showResultAlert = true
            await appState.refreshProfile()
        } catch {
            timer.invalidate()
            spinTimer = nil
            isSpinning = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
