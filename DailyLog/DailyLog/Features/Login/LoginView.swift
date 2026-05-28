import SwiftUI

private enum LoginField: Hashable {
    case email, password
}

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: LoginField?

    private let authService = AuthService()

    var body: some View {
        ZStack {
            DLBackground()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // Logo card
                RoundedRectangle(cornerRadius: 24)
                    .frame(width: 88, height: 88)
                    .glassEffect(.regular.tint(Color.dlLavender.opacity(0.25)), in: .rect(cornerRadius: 24))
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.dlLavender)
                    }

                Text("DailyLog")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.dlTextPrimary)

                Text("每日打卡，积累金币")
                    .font(.subheadline)
                    .foregroundStyle(Color.dlTextSecondary)

                GlassEffectContainer(spacing: 12.0) {
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "envelope")
                                .foregroundStyle(Color.dlTextSecondary)
                            TextField("邮箱", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .email)
                                .onSubmit { focusedField = .password }
                        }
                        .padding()
                        .glassEffect(.regular, in: .capsule)

                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "lock")
                                .foregroundStyle(Color.dlTextSecondary)
                            Group {
                                if isPasswordVisible {
                                    TextField("密码", text: $password)
                                        .textContentType(.password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("密码", text: $password)
                                        .textContentType(.password)
                                }
                            }
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit { Task { await login() } }

                            Button {
                                let wasFocused = focusedField == .password
                                isPasswordVisible.toggle()
                                if wasFocused {
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(50))
                                        focusedField = .password
                                    }
                                }
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .glassEffect(.regular, in: .capsule)
                    }
                }

                if let errorMessage {
                    DLErrorBanner(message: errorMessage)
                }

                DLPrimaryButton(
                    action: { Task { await login() } },
                    isLoading: isLoading,
                    isDisabled: email.isEmpty || password.isEmpty
                ) {
                    Text("登录")
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func login() async {
        errorMessage = nil
        appState.loginError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            await appState.onLoginSuccess()
            // onLoginSuccess 失败时会设置 appState.loginError，映射到本地 errorMessage
            if let appError = appState.loginError {
                errorMessage = appError
            }
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
