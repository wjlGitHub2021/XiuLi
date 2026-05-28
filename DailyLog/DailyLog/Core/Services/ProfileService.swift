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
        // Nit #3: 改用 CGImageSourceCreateThumbnailAtIndex，ImageIO 直接读 thumbnail
        // 跳过完整解码，真正避免 48MP 原图 OOM
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw URLError(.badServerResponse)
        }
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            throw URLError(.badServerResponse)
        }
        let resized = UIImage(cgImage: cgImage)
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

        // Fix #12: 基准点改为最新打卡日（latest），而非 today
        // "昨天打卡今天未打" → latest=yesterday，streak 从 yesterday 起向前数 = 1（正确）
        // 若最新打卡日既非今天也非昨天，视为断卡
        let latest = uniqueDates[0]
        guard calendar.isDate(latest, inSameDayAs: today) ||
              calendar.isDate(latest, inSameDayAs: yesterday) else { return 0 }

        // 从 latest 起向前逐天连续计数
        var streak = 1
        var expected = calendar.date(byAdding: .day, value: -1, to: latest)!
        for i in 1..<uniqueDates.count {
            if calendar.isDate(uniqueDates[i], inSameDayAs: expected) {
                streak += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else {
                break
            }
        }
        return streak
    }
}
