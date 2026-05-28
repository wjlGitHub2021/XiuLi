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

        struct DeviceRegistration: Encodable {
            let user_id: String
            let device_token: String
            let platform: String
            let is_active: Bool
        }

        let registration = DeviceRegistration(
            user_id: userId.uuidString,
            device_token: token,
            platform: "ios",
            is_active: true
        )

        try await client.from("user_devices")
            .upsert(registration, onConflict: "user_id,device_token")
            .execute()
    }

    func unregisterDevice(userId: UUID) async throws {
        struct DeviceUpdate: Encodable {
            let is_active: Bool
        }

        try await client.from("user_devices")
            .update(DeviceUpdate(is_active: false))
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
