import Foundation
import UserNotifications
import UIKit
import Supabase

final class NotificationService {
    private let client = AppSupabase.client

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    func registerDeviceToken(_ tokenData: Data, userId: UUID) async throws {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

        try await client.from("user_devices")
            .upsert([
                "user_id": userId.uuidString,
                "device_token": token,
                "platform": "ios",
                "is_active": "true"
            ], onConflict: "user_id,device_token")
            .execute()
    }

    func unregisterDevice(userId: UUID) async throws {
        try await client.from("user_devices")
            .update(["is_active": "false"])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
