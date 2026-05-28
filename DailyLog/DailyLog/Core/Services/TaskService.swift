import Foundation
import Supabase

struct CreateTaskParams: Encodable {
    let userId: UUID
    let title: String
    let notes: String?
    let taskType: String
    let taskDate: String
    let expireDate: String?
    let coinsEarned: Int
    let orderInDay: Int

    enum CodingKeys: String, CodingKey {
        case title, notes
        case userId = "user_id"
        case taskType = "task_type"
        case taskDate = "task_date"
        case expireDate = "expire_date"
        case coinsEarned = "coins_earned"
        case orderInDay = "order_in_day"
    }
}

final class TaskService {
    private let client = AppSupabase.client

    func fetchTasks(userId: UUID, taskType: TaskType, date: Date) async throws -> [TaskItem] {
        let dateString = Self.dateFormatter.string(from: date)
        return try await client.from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("task_type", value: taskType.rawValue)
            .eq("task_date", value: dateString)
            .order("order_in_day")
            .execute()
            .value
    }

    func createTask(_ params: CreateTaskParams) async throws -> TaskItem {
        return try await client.from("tasks")
            .insert(params)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchAllTasks(userId: UUID, date: Date) async throws -> (daily: [TaskItem], weekly: [TaskItem], monthly: [TaskItem]) {
        async let d = fetchTasks(userId: userId, taskType: .daily, date: date)
        async let w = fetchTasks(userId: userId, taskType: .weekly, date: date)
        async let m = fetchTasks(userId: userId, taskType: .monthly, date: date)
        return try await (daily: d, weekly: w, monthly: m)
    }

    func completeTask(taskId: UUID) async throws -> CompleteTaskResponse {
        return try await client.rpc(
            "complete_task",
            params: ["p_task_id": taskId.uuidString]
        )
        .execute()
        .value
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
