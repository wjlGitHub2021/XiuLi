import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var isAuthenticated = false
    var isLoading = true
    var currentUser: User?
    /// 登录后加载用户信息失败时的错误提示，由 LoginView 监听展示
    var loginError: String?

    private let authService = AuthService()
    private let profileService = ProfileService()
    private var isRestoringSession = false

    func restoreSession() async {
        // 防止 ContentView.task 多次触发导致重入
        guard !isRestoringSession else { return }
        isRestoringSession = true
        isLoading = true
        defer {
            isLoading = false
            isRestoringSession = false
        }

        let hasSession = await authService.restoreSession()
        if hasSession, let userId = await authService.currentUserId() {
            do {
                currentUser = try await profileService.fetchProfile(userId: userId)
                isAuthenticated = true
            } catch {
                isAuthenticated = false
                currentUser = nil
            }
        }
    }

    func onLoginSuccess() async {
        guard let userId = await authService.currentUserId() else { return }
        do {
            currentUser = try await profileService.fetchProfile(userId: userId)
            isAuthenticated = true
        } catch {
            // fetchProfile 失败：清理已建立的 session，避免 UI 卡在登录页无反应
            do {
                try await authService.signOut()
            } catch {
                print("signOut failed: \(error)")
            }
            isAuthenticated = false
            currentUser = nil
            loginError = "登录成功但加载用户信息失败，请重试"
        }
    }

    func signOut() async {
        try? await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }

    func refreshProfile() async {
        guard let userId = await authService.currentUserId() else { return }
        do {
            currentUser = try await profileService.fetchProfile(userId: userId)
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            // 刷新失败时保留旧用户，避免下拉刷新或临时网络错误让 UI 看起来像退出登录。
            print("refreshProfile failed: \(error)")
        }
    }
}
