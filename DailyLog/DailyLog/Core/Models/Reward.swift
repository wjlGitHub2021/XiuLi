import Foundation

struct Reward: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let icon: String
    // cost 保留 Optional 以兼容 DB schema（部分 spin 奖励无固定金币成本）
    // 展示层使用前需过滤 cost == nil 的 direct 奖励
    let cost: Int?
    let type: String  // "direct" or "spin"
    let probability: Double?
    let sortOrder: Int?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, cost, type, probability
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

struct RedeemResponse: Codable, Sendable {
    let success: Bool
    let rewardName: String
    let coinsSpent: Int
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case success
        case rewardName = "reward_name"
        case coinsSpent = "coins_spent"
        case balance
    }
}

struct SpinResponse: Codable, Sendable {
    let success: Bool
    let rewardName: String
    let rewardIcon: String
    let coinsWon: Int
    let balance: Int
    let cost: Int

    enum CodingKeys: String, CodingKey {
        case success, balance, cost
        case rewardName = "reward_name"
        case rewardIcon = "reward_icon"
        case coinsWon = "coins_won"
    }
}
