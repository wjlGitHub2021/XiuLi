import Foundation

struct Reward: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let icon: String
    let cost: Int?
    let type: String
    let probability: Double?
    let sortOrder: Int?
    let isActive: Bool?
    let tier: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, cost, type, probability, tier
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }

    var tierDisplay: String {
        switch tier {
        case "basic": return "基础"
        case "rare": return "稀有"
        case "legendary": return "传说"
        case "sacred": return "神圣"
        default: return ""
        }
    }

    var tierColor: String {
        switch tier {
        case "basic": return "basic"
        case "rare": return "rare"
        case "legendary": return "legendary"
        case "sacred": return "sacred"
        default: return "basic"
        }
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
