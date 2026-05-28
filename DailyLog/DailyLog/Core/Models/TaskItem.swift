import Foundation

enum TaskType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "日任务"
        case .weekly: return "周任务"
        case .monthly: return "月任务"
        }
    }
}

enum TaskStatus: String, Codable {
    case pending
    case completed
}

struct TaskItem: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var notes: String?
    var taskType: TaskType
    var status: TaskStatus
    var orderInDay: Int
    var coinsEarned: Int
    var taskDate: String
    var expireDate: String?
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, notes, status
        case userId = "user_id"
        case taskType = "task_type"
        case orderInDay = "order_in_day"
        case coinsEarned = "coins_earned"
        case taskDate = "task_date"
        case expireDate = "expire_date"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isCompleted: Bool { status == .completed }
}
