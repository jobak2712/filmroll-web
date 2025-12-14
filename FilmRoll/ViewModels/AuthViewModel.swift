import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Form fields
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    
    // Mock mode for testing - uses SupabaseConfig
    @Published var useMockData = SupabaseConfig.useMockData
    
    // Apple Sign In
    private var currentNonce: String?
    
    nonisolated init() {
        Task { @MainActor in
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        if useMockData {
            // In mock mode, check if we have a stored mock session
            isAuthenticated = false
            return
        }
        
        do {
            currentUser = try await SupabaseService.shared.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            isAuthenticated = false
        }
    }
    
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Mock authentication
        if useMockData {
            try? await Task.sleep(nanoseconds: 800_000_000) // Simulate network delay
            
            if email == MockDataService.testEmail && password == MockDataService.testPassword {
                currentUser = MockDataService.shared.mockUser
                isAuthenticated = true
                clearForm()
            } else {
                errorMessage = "Invalid credentials. Use test@filmroll.app / Test1234!"
            }
            isLoading = false
            return
        }
        
        do {
            currentUser = try await SupabaseService.shared.signIn(email: email, password: password)
            isAuthenticated = true
            clearForm()
        } catch {
            errorMessage = "Sign in failed. Please check your credentials."
        }
        
        isLoading = false
    }
    
    // Returns true if signup succeeded (user should then sign in)
    func signUp() async -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Mock sign up
        if useMockData {
            try? await Task.sleep(nanoseconds: 800_000_000)
            // In mock mode, just simulate success - don't auto sign in
            clearForm()
            isLoading = false
            return true
        }
        
        do {
            // Create account but don't auto-sign in
            _ = try await SupabaseService.shared.signUp(email: email, password: password)
            // Clear form but keep email for convenience when signing in
            let savedEmail = email
            clearForm()
            email = savedEmail
            isLoading = false
            return true
        } catch {
            errorMessage = "Sign up failed. Please try again."
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        if useMockData {
            currentUser = nil
            isAuthenticated = false
            return
        }
        
        do {
            try await SupabaseService.shared.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Sign out failed"
        }
    }
    
    // Quick login with test credentials
    func signInWithTestAccount() async {
        email = MockDataService.testEmail
        password = MockDataService.testPassword
        await signIn()
    }
    
    // MARK: - Password Reset
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        
        if useMockData {
            try? await Task.sleep(nanoseconds: 800_000_000)
            isLoading = false
            // In mock mode, just simulate success
            return
        }
        
        do {
            try await SupabaseService.shared.sendPasswordReset(email: email)
        } catch {
            errorMessage = "Failed to send reset email. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Sign in with Google
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        if useMockData {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // Simulate Google sign in with mock user
            currentUser = User(
                id: UUID().uuidString,
                email: "google.user@gmail.com",
                displayName: "Google User",
                avatarUrl: nil,
                createdAt: Date()
            )
            isAuthenticated = true
            isLoading = false
            return
        }
        
        // In production, implement Google Sign-In SDK
        // For now, show placeholder
        do {
            currentUser = try await SupabaseService.shared.signInWithGoogle()
            isAuthenticated = true
        } catch {
            errorMessage = "Google sign in failed. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        if useMockData {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // Simulate Apple sign in with mock user
            currentUser = User(
                id: UUID().uuidString,
                email: "apple.user@privaterelay.appleid.com",
                displayName: "Apple User",
                avatarUrl: nil,
                createdAt: Date()
            )
            isAuthenticated = true
            isLoading = false
            return
        }
        
        // Generate nonce for Apple Sign In
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // In production, this would trigger the Apple Sign In flow
        // The actual implementation requires ASAuthorizationController
        do {
            currentUser = try await SupabaseService.shared.signInWithApple(idToken: "", nonce: nonce)
            isAuthenticated = true
        } catch {
            errorMessage = "Apple sign in failed. Please try again."
        }
        
        isLoading = false
    }
    
    // Handle Apple Sign In credential
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce,
              let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Unable to process Apple sign in"
            return
        }
        
        isLoading = true
        
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let email = credential.email ?? "apple.user@privaterelay.appleid.com"
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            currentUser = User(
                id: credential.user,
                email: email,
                displayName: fullName.isEmpty ? nil : fullName,
                avatarUrl: nil,
                createdAt: Date()
            )
            isAuthenticated = true
            isLoading = false
            return
        }
        
        do {
            currentUser = try await SupabaseService.shared.signInWithApple(idToken: idTokenString, nonce: nonce)
            isAuthenticated = true
        } catch {
            errorMessage = "Apple sign in failed. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Functions
    private func clearForm() {
        email = ""
        password = ""
        displayName = ""
    }
    
    // Generate random nonce for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    // SHA256 hash for Apple Sign In
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
