import Foundation
import Supabase

final class FeedService {
    private let client = AppSupabase.client

    func fetchFeed(limit: Int = 30) async throws -> [FeedMessage] {
        return try await client.from("feed_messages")
            .select("id, user_id, type, title, body, created_at")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}
