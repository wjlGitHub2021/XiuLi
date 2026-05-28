import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var nickname: String
    var avatarUrl: String?
    var coins: Int
    var totalCompleted: Int
    var pushEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, nickname, coins
        case avatarUrl = "avatar_url"
        case totalCompleted = "total_completed"
        case pushEnabled = "push_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
