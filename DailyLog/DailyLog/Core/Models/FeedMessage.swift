import Foundation

struct FeedMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let body: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, body
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
