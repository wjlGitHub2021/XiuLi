import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let authService = AuthService()

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("DailyLog")
                .font(.largeTitle.bold())

            Text("每日打卡，积累金币")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.md) {
                TextField("邮箱", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("密码", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage {
                DLErrorBanner(message: errorMessage)
            }

            DLLoadingButton(title: "登录", isLoading: isLoading) {
                Task { await login() }
            }
            .disabled(email.isEmpty || password.isEmpty)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            await appState.onLoginSuccess()
        } catch {
            errorMessage = mapError(error)
        }
    }

    private func mapError(_ error: Error) -> String {
        let desc = error.localizedDescription.lowercased()
        if desc.contains("invalid") || desc.contains("credentials") {
            return "邮箱或密码不正确"
        }
        if desc.contains("network") || desc.contains("connection") {
            return "网络连接失败，请检查网络后重试"
        }
        return "登录失败，请稍后重试"
    }
}
