import Foundation

struct CompleteTaskResponse: Codable {
    let task: TaskItem
    let coins: Int
    let totalCompleted: Int
    let alreadyCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case task, coins
        case totalCompleted = "total_completed"
        case alreadyCompleted = "already_completed"
    }
}
