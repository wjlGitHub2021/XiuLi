import Foundation
import Supabase

struct SpinWheelParams: Encodable {
    let pCost: Int

    enum CodingKeys: String, CodingKey {
        case pCost = "p_cost"
    }
}

final class RewardService {
    private let client = AppSupabase.client

    func fetchRewards() async throws -> [Reward] {
        try await client.from("rewards")
            .select()
            .eq("is_active", value: true)
            .order("sort_order")
            .execute()
            .value
    }

    func redeemReward(rewardId: UUID) async throws -> RedeemResponse {
        try await client.rpc(
            "redeem_reward",
            params: ["p_reward_id": rewardId.uuidString]
        )
        .execute()
        .value
    }

    func spinWheel(cost: Int = 10) async throws -> SpinResponse {
        try await client.rpc(
            "spin_wheel",
            params: SpinWheelParams(pCost: cost)
        )
        .execute()
        .value
    }
}
