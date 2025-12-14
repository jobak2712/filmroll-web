import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSignUp = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .error
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.custom("PlayfairDisplay-Bold", size: 28))
                                .foregroundColor(FilmRollTheme.primaryText)

                            Text(isSignUp ? "Sign up to start hosting events" : "Sign in to your account")
                                .font(.system(size: 15))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        .padding(.top, 24)

                        // Toggle
                        SegmentedControl(
                            options: ["Sign In", "Sign Up"],
                            selectedIndex: Binding(
                                get: { isSignUp ? 1 : 0 },
                                set: { isSignUp = $0 == 1 }
                            )
                        )

                        // Form
                        VStack(spacing: 16) {
                            if isSignUp {
                                FilmTextField(
                                    label: "Your Name",
                                    placeholder: "Enter your name",
                                    text: $authViewModel.displayName,
                                    icon: "person"
                                )
                                .textInputAutocapitalization(.words)
                            }

                            FilmTextField(
                                label: "Email Address",
                                placeholder: "Enter your email",
                                text: $authViewModel.email,
                                icon: "envelope"
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()

                            FilmTextField(
                                label: "Password",
                                placeholder: isSignUp ? "Create a password" : "Enter your password",
                                text: $authViewModel.password,
                                icon: "lock",
                                isSecure: true
                            )

                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {
                                        showForgotPassword = true
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                }
                            }

                            if isSignUp {
                                // Password requirements
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirement(
                                        text: "At least 6 characters",
                                        isMet: authViewModel.password.count >= 6
                                    )
                                    PasswordRequirement(
                                        text: "Contains a number",
                                        isMet: authViewModel.password.contains(where: { $0.isNumber })
                                    )
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Submit Button
                        PrimaryButton(
                            isSignUp ? "Create Account" : "Sign In",
                            icon: "arrow.right",
                            isLoading: authViewModel.isLoading
                        ) {
                            performAuth()
                        }

                        // Switch mode
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(FilmRollTheme.secondaryText)
                            Button(isSignUp ? "Sign In" : "Sign Up") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSignUp.toggle()
                                }
                            }
                            .foregroundColor(FilmRollTheme.accent)
                            .fontWeight(.medium)
                        }
                        .font(.system(size: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                }
            }
            .toast(isPresented: $showToast, message: toastMessage, type: toastType)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authViewModel)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }

    private func performAuth() {
        // Validate email
        guard !authViewModel.email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Please enter your email")
            return
        }

        guard authViewModel.email.isValidEmail else {
            showError("Please enter a valid email")
            return
        }

        // Validate password
        guard !authViewModel.password.isEmpty else {
            showError("Please enter your password")
            return
        }

        if isSignUp && authViewModel.password.count < 6 {
            showError("Password must be at least 6 characters")
            return
        }

        hideKeyboard()

        Task {
            if isSignUp {
                let success = await authViewModel.signUp()
                if success {
                    // Show success and switch to sign in
                    toastMessage = "Account created! Please sign in."
                    toastType = .success
                    showToast = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignUp = false
                    }
                } else if let error = authViewModel.errorMessage {
                    showError(error)
                    authViewModel.errorMessage = nil
                }
            } else {
                await authViewModel.signIn()
                if let error = authViewModel.errorMessage {
                    showError(error)
                    authViewModel.errorMessage = nil
                }
            }
        }
    }

    private func showError(_ message: String) {
        toastMessage = message
        toastType = .error
        showToast = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Password Requirement
struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .green : FilmRollTheme.secondaryText)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(isMet ? FilmRollTheme.primaryText : FilmRollTheme.secondaryText)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(FilmRollTheme.accentLight)
                            .frame(width: 80, height: 80)

                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 32))
                            .foregroundColor(FilmRollTheme.accent)
                    }
                    .padding(.top, 32)

                    // Header
                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(.custom("PlayfairDisplay-Bold", size: 24))
                            .foregroundColor(FilmRollTheme.primaryText)

                        Text("Enter your email and we'll send you a link to reset your password")
                            .font(.system(size: 14))
                            .foregroundColor(FilmRollTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    // Email Field
                    FilmTextField(
                        label: "Email Address",
                        placeholder: "Enter your email",
                        text: $email,
                        icon: "envelope"
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 24)

                    // Submit Button
                    PrimaryButton(
                        "Send Reset Link",
                        icon: "paperplane.fill",
                        isLoading: isLoading
                    ) {
                        sendResetLink()
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                }
            }
            .toast(isPresented: $showToast, message: toastMessage, type: .error)
            .alert("Check Your Email", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent a password reset link to \(email)")
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .presentationDetents([.medium])
    }

    private func sendResetLink() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            toastMessage = "Please enter your email"
            showToast = true
            return
        }

        guard email.isValidEmail else {
            toastMessage = "Please enter a valid email"
            showToast = true
            return
        }

        isLoading = true

        Task {
            authViewModel.email = email
            await authViewModel.sendPasswordReset()

            isLoading = false

            if let error = authViewModel.errorMessage {
                toastMessage = error
                showToast = true
                authViewModel.errorMessage = nil
            } else {
                showSuccess = true
            }
        }
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthViewModel())
}
