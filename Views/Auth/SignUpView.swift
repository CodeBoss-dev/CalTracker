import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Start your calorie tracking journey")
                            .font(.subheadline)
                            .foregroundStyle(Color.appGreenLight)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        AuthTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )

                        AuthSecureField(
                            placeholder: "Password (min 8 characters)",
                            text: $password,
                            icon: "lock.fill"
                        )

                        AuthSecureField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            icon: "lock.fill"
                        )

                        // Validation messages
                        if !password.isEmpty && password.count < 8 {
                            ValidationRow(
                                message: "Password must be at least 8 characters",
                                isValid: false
                            )
                        }

                        if !confirmPassword.isEmpty && password != confirmPassword {
                            ValidationRow(
                                message: "Passwords do not match",
                                isValid: false
                            )
                        }

                        if !confirmPassword.isEmpty && password == confirmPassword && password.count >= 8 {
                            ValidationRow(
                                message: "Passwords match",
                                isValid: true
                            )
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign Up Button
                    VStack(spacing: 16) {
                        Button {
                            Task { await signUp() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
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

                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundStyle(Color(white: 0.6))
                                Text("Sign In")
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
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appGreen)
                }
            }
        }
        .alert("Check Your Email", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("We've sent a confirmation link to \(email). Please verify your email before signing in.")
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            // If still not authenticated → email confirmation required
            if !authService.isAuthenticated {
                showConfirmation = true
            }
        } catch {
            errorMessage = signUpErrorMessage(for: error)
        }
        isLoading = false
    }

    private func signUpErrorMessage(for error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("already registered") || msg.contains("already in use") || msg.contains("user already exists") {
            return "An account with this email already exists. Try signing in."
        } else if msg.contains("invalid email") || msg.contains("valid email") {
            return "Please enter a valid email address."
        } else if msg.contains("password") && (msg.contains("weak") || msg.contains("short")) {
            return "Password is too weak. Please choose a stronger password."
        } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "No internet connection. Please check your network and try again."
        }
        return "Account creation failed. Please try again."
    }
}

// MARK: - Helper

private struct ValidationRow: View {
    let message: String
    let isValid: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isValid ? Color.appGreen : .red)
                .font(.system(size: 14))
            Text(message)
                .font(.footnote)
                .foregroundStyle(isValid ? Color.appGreenLight : .red)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
