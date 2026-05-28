import Foundation
import Supabase
import UIKit

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

    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString).jpg"
        try await client.storage
            .from("avatars")
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: path)

        try await client.from("users")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId.uuidString)
            .execute()

        return publicURL.absoluteString
    }

    func fetchStreak(userId: UUID) async throws -> Int {
        struct TaskDate: Decodable {
            let task_date: String
        }

        let tasks: [TaskDate] = try await client.from("tasks")
            .select("task_date")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "completed")
            .order("task_date", ascending: false)
            .execute()
            .value

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current

        let uniqueDates: [Date] = Array(
            Set(tasks.compactMap { formatter.date(from: $0.task_date) })
        ).sorted(by: >)

        guard !uniqueDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Streak must start from today or yesterday
        guard uniqueDates[0] >= yesterday else { return 0 }

        var streak = 1
        for i in 1..<uniqueDates.count {
            let expected = calendar.date(byAdding: .day, value: -i, to: uniqueDates[0])!
            if calendar.isDate(uniqueDates[i], inSameDayAs: expected) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
