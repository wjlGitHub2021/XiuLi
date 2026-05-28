import Foundation

struct CoinTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Int
    let balanceAfter: Int
    let reason: String
    let referenceType: String?
    let referenceId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, reason
        case userId = "user_id"
        case balanceAfter = "balance_after"
        case referenceType = "reference_type"
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }

    var reasonDisplay: String {
        switch reason {
        case "task_complete": return "完成任务"
        case "reward_redeem": return "兑换奖励"
        case "spin_cost": return "转盘消耗"
        case "spin_win": return "转盘中奖"
        case "adjustment": return "调整"
        default: return reason
        }
    }
}
