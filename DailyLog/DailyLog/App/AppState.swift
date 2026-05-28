import Foundation
import Observation

@Observable
final class AppState {
    var isAuthenticated = false
    var isLoading = true
    var currentUser: User?

    private let authService = AuthService()
    private let profileService = ProfileService()

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let hasSession = try await authService.restoreSession()
            if hasSession, let userId = await authService.currentUserId {
                currentUser = try await profileService.fetchProfile(userId: userId)
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func onLoginSuccess() async {
        guard let userId = await authService.currentUserId else { return }
        do {
            currentUser = try await profileService.fetchProfile(userId: userId)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signOut() async {
        try? await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }

    func refreshProfile() async {
        guard let userId = await authService.currentUserId else { return }
        currentUser = try? await profileService.fetchProfile(userId: userId)
    }
}
