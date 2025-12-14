import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showEmailAuth = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .error

    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo & Branding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(FilmRollTheme.buttonBackground)
                                .frame(width: 88, height: 88)

                            Image(systemName: "camera")
                                .font(.system(size: 36))
                                .foregroundColor(.white)

                            // Orange dot accent
                            Circle()
                                .fill(FilmRollTheme.accent)
                                .frame(width: 18, height: 18)
                                .offset(x: 28, y: -28)
                        }

                        Text("FilmRoll")
                            .font(.custom("PlayfairDisplay-Bold", size: 36))
                            .foregroundColor(FilmRollTheme.primaryText)

                        Text("Shared moments, revealed together")
                            .font(.system(size: 15))
                            .foregroundColor(FilmRollTheme.secondaryText)
                    }

                    Spacer()

                    // Auth Buttons
                    VStack(spacing: 12) {
                        // Continue with Apple (Primary - required for App Store)
                        ContinueWithButton(
                            provider: .apple,
                            isLoading: authViewModel.isLoading
                        ) {
                            Task {
                                await authViewModel.signInWithApple()
                                handleAuthResult()
                            }
                        }

                        // Continue with Google
                        ContinueWithButton(
                            provider: .google,
                            isLoading: authViewModel.isLoading
                        ) {
                            Task {
                                await authViewModel.signInWithGoogle()
                                handleAuthResult()
                            }
                        }

                        // Continue with Email
                        ContinueWithButton(
                            provider: .email,
                            isLoading: false
                        ) {
                            showEmailAuth = true
                        }

                        // Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(FilmRollTheme.divider)
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 13))
                                .foregroundColor(FilmRollTheme.secondaryText)
                            Rectangle()
                                .fill(FilmRollTheme.divider)
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)

                        // Join as Guest
                        Button(action: {
                            appState.isGuestMode = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 18))
                                Text("Join Event as Guest")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(FilmRollTheme.divider, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Test Account (Mock mode only)
                    if authViewModel.useMockData {
                        Button {
                            Task {
                                await authViewModel.signInWithTestAccount()
                            }
                        } label: {
                            Text("Use Test Account")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FilmRollTheme.accent)
                        }
                        .padding(.top, 16)
                    }

                    Spacer()
                        .frame(height: 24)

                    // Terms & Privacy
                    VStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .foregroundColor(FilmRollTheme.secondaryText)

                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                if let url = URL(string: "https://filmroll.app/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(FilmRollTheme.primaryText)

                            Text("and")
                                .foregroundColor(FilmRollTheme.secondaryText)

                            Button("Privacy Policy") {
                                if let url = URL(string: "https://filmroll.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(FilmRollTheme.primaryText)
                        }
                    }
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .toast(isPresented: $showToast, message: toastMessage, type: toastType)
            .sheet(isPresented: $showEmailAuth) {
                EmailAuthView()
                    .environmentObject(authViewModel)
            }
        }
    }

    private func handleAuthResult() {
        if let error = authViewModel.errorMessage {
            toastMessage = error
            toastType = .error
            showToast = true
            authViewModel.errorMessage = nil
        } else if authViewModel.isAuthenticated {
            toastMessage = "Welcome to FilmRoll! 🎉"
            toastType = .success
            showToast = true
        }
    }
}

// MARK: - Continue With Button
enum AuthProvider {
    case apple
    case google
    case email

    var title: String {
        switch self {
        case .apple: return "Continue with Apple"
        case .google: return "Continue with Google"
        case .email: return "Continue with Email"
        }
    }

    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .white
        case .email: return FilmRollTheme.cardBackground
        }
    }

    var foregroundColor: Color {
        switch self {
        case .apple: return .white
        case .google: return .black
        case .email: return FilmRollTheme.primaryText
        }
    }

    var hasBorder: Bool {
        switch self {
        case .apple: return false
        case .google, .email: return true
        }
    }
}

struct ContinueWithButton: View {
    let provider: AuthProvider
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    // Icon
                    if provider == .google {
                        GoogleLogo()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: provider.icon)
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text(provider.title)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .foregroundColor(provider.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(provider.backgroundColor)
            .cornerRadius(26)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(provider.hasBorder ? FilmRollTheme.divider : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Google Logo
struct GoogleLogo: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Blue
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255), lineWidth: size * 0.18)
                    .rotationEffect(.degrees(-45))

                // Green
                Circle()
                    .trim(from: 0.25, to: 0.5)
                    .stroke(Color(red: 52 / 255, green: 168 / 255, blue: 83 / 255), lineWidth: size * 0.18)
                    .rotationEffect(.degrees(-45))

                // Yellow
                Circle()
                    .trim(from: 0.5, to: 0.75)
                    .stroke(Color(red: 251 / 255, green: 188 / 255, blue: 5 / 255), lineWidth: size * 0.18)
                    .rotationEffect(.degrees(-45))

                // Red
                Circle()
                    .trim(from: 0.75, to: 0.95)
                    .stroke(Color(red: 234 / 255, green: 67 / 255, blue: 53 / 255), lineWidth: size * 0.18)
                    .rotationEffect(.degrees(-45))

                // Blue bar
                Rectangle()
                    .fill(Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255))
                    .frame(width: size * 0.45, height: size * 0.18)
                    .offset(x: size * 0.12)
            }
            .frame(width: size * 0.75, height: size * 0.75)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
