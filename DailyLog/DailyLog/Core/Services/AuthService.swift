import Foundation
import Supabase

final class AuthService {
    private let client = AppSupabase.client

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func restoreSession() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    func currentUserId() async -> UUID? {
        try? await client.auth.session.user.id
    }
}
