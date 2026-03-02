import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false

    // Rate limiting: lock out after 5 consecutive failures
    @State private var failureCount = 0
    @State private var lockoutUntil: Date?
    private let maxFailures = 5
    private let lockoutDuration: TimeInterval = 60 // seconds

    private var isLockedOut: Bool {
        guard let until = lockoutUntil else { return false }
        return Date.now < until
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        VStack(spacing: 12) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(Color.appGreen)
                            Text("CalTracker")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text("Track your Indian diet, effortlessly")
                                .font(.subheadline)
                                .foregroundStyle(Color.appGreenLight)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)

                        // Form
                        VStack(spacing: 16) {
                            AuthTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )

                            AuthSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )

                            if let error = errorMessage {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(isLockedOut ? .orange : .red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Login Button
                        VStack(spacing: 16) {
                            Button {
                                Task { await login() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(canSubmit ? Color.appGreen : Color.appGreen.opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!canSubmit || isLoading)
                            .padding(.horizontal, 24)

                            // Sign Up link
                            Button {
                                showSignUp = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .foregroundStyle(Color(white: 0.6))
                                    Text("Sign Up")
                                        .foregroundStyle(Color.appGreen)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private var canSubmit: Bool {
        !isLockedOut &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8
    }

    private func login() async {
        guard !isLockedOut else {
            let remaining = Int((lockoutUntil ?? .now).timeIntervalSinceNow.rounded(.up))
            errorMessage = "Too many failed attempts. Try again in \(remaining)s."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            failureCount = 0
            lockoutUntil = nil
        } catch {
            failureCount += 1
            if failureCount >= maxFailures {
                lockoutUntil = Date.now.addingTimeInterval(lockoutDuration)
                errorMessage = "Too many failed attempts. Please wait 60 seconds."
            } else {
                errorMessage = authErrorMessage(for: error)
            }
        }
        isLoading = false
    }

    private func authErrorMessage(for error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") || msg.contains("invalid credentials") || msg.contains("wrong password") {
            return "Incorrect email or password. Please try again."
        } else if msg.contains("email not confirmed") || msg.contains("not confirmed") {
            return "Please verify your email before signing in."
        } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "No internet connection. Please check your network and try again."
        } else if msg.contains("too many") || msg.contains("rate limit") {
            return "Too many attempts. Please wait a moment and try again."
        }
        return "Sign in failed. Please try again."
    }
}

// MARK: - Reusable Auth Components

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.appGreen)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.appGreen)
                .frame(width: 20)
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(Color(white: 0.5))
                    .font(.system(size: 14))
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
