import Foundation
import Supabase

final class ProfileService {
    private let client = AppSupabase.client

    func fetchProfile(userId: UUID) async throws -> User {
        return try await client.from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchRecentTransactions(userId: UUID, limit: Int = 10) async throws -> [CoinTransaction] {
        return try await client.from("coin_transactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}
