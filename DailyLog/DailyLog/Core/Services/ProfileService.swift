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
        // Bug #3: 先降采样到 1024×1024 再压缩，避免大图 OOM
        guard let sourceImage = UIImage(data: imageData) else {
            throw URLError(.badServerResponse)
        }
        let maxDimension: CGFloat = 1024
        let size = sourceImage.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let compressedData = resized.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }

        let path = "\(userId.uuidString).jpg"
        try await client.storage
            .from("avatars")
            .upload(path, data: compressedData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: path)

        // Bug #24: 加时间戳缓存破坏参数，防止 CDN 返回旧头像
        let timestampedURL = publicURL.absoluteString + "?t=\(Int(Date().timeIntervalSince1970))"

        try await client.from("users")
            .update(["avatar_url": timestampedURL])
            .eq("id", value: userId.uuidString)
            .execute()

        return timestampedURL
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

        // Bug #12: 基准点改为 today。
        // 最新打卡日必须是今天或昨天，否则已断卡
        let latestDate = uniqueDates[0]
        guard latestDate == today || latestDate == yesterday else { return 0 }

        // 从 today 起往前逐天检查
        var streak = 0
        for i in 0..<uniqueDates.count {
            let expected = calendar.date(byAdding: .day, value: -i, to: today)!
            if calendar.isDate(uniqueDates[i], inSameDayAs: expected) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
