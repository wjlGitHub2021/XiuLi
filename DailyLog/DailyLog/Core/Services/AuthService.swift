import Foundation
import Supabase
import Auth

final class AuthService {
    private let client = AppSupabase.client

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func restoreSession() async throws -> Bool {
        _ = try await client.auth.session
        return true
    }

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
}
