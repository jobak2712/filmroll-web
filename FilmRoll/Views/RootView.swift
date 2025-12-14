import SwiftUI
import AVFoundation

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var isInitializing = true
    
    var body: some View {
        ZStack {
            Group {
                if isInitializing {
                    SplashView()
                } else if !hasSeenOnboarding {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                } else if appState.isGuestMode {
                    GuestFlowView()
                } else if authViewModel.isAuthenticated {
                    HostHomeView()
                } else {
                    WelcomeView()
                }
            }
            
            // Offline Banner
            if !networkMonitor.isConnected && !isInitializing {
                VStack {
                    OfflineBanner()
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: networkMonitor.isConnected)
        .task {
            // Give auth check a moment, then proceed regardless
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds max
            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo
                ZStack {
                    Circle()
                        .fill(FilmRollTheme.primaryText)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundColor(FilmRollTheme.background)
                    
                    // Orange dot accent
                    Circle()
                        .fill(FilmRollTheme.accent)
                        .frame(width: 16, height: 16)
                        .offset(x: 30, y: 25)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                Text("FilmRoll")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(FilmRollTheme.primaryText)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14))
            Text("You're offline. Photos will upload when connected.")
                .font(.system(size: 13))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(FilmRollTheme.primaryText)
    }
}

struct GuestFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var guestViewModel = GuestViewModel()
    @State private var hasCameraPermission: Bool? = nil
    @State private var showPermissionScreen = false
    
    var body: some View {
        NavigationStack {
            // Show join view if no participant (not joined yet or left event)
            if guestViewModel.participant != nil && guestViewModel.event != nil {
                if guestViewModel.isRevealed {
                    GuestGalleryView(viewModel: guestViewModel)
                } else {
                    // Check if we need to show permission screen
                    if showPermissionScreen {
                        CameraPermissionView(
                            onPermissionGranted: {
                                showPermissionScreen = false
                                hasCameraPermission = true
                            },
                            onCancel: {
                                appState.isGuestMode = false
                            }
                        )
                    } else {
                        GuestCameraView(viewModel: guestViewModel)
                    }
                }
            } else {
                GuestJoinView(viewModel: guestViewModel)
            }
        }
        .task {
            // Check camera permission status
            await checkCameraPermission()
            
            // Load pending join code from deep link
            if let joinCode = appState.pendingJoinCode {
                await guestViewModel.loadEvent(joinCode: joinCode)
                appState.pendingJoinCode = nil
            }
            
            // Restore previous session
            if let session = GuestSession.load() {
                appState.currentGuestSession = session
                guestViewModel.shotsTaken = session.shotsTaken
                
                // Restore event and participant from session
                await guestViewModel.restoreSession(session)
            }
        }
        .onChange(of: guestViewModel.participant?.id) { _, newValue in
            // When participant is set (user joined), check if we need permission screen
            if newValue != nil && !guestViewModel.isRevealed {
                Task {
                    await checkCameraPermission()
                }
            }
        }
    }
    
    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        await MainActor.run {
            switch status {
            case .notDetermined:
                // Show pre-permission screen
                showPermissionScreen = true
                hasCameraPermission = nil
            case .authorized:
                showPermissionScreen = false
                hasCameraPermission = true
            case .denied, .restricted:
                // Permission denied - go directly to camera view which will show error
                showPermissionScreen = false
                hasCameraPermission = false
            @unknown default:
                showPermissionScreen = true
                hasCameraPermission = nil
            }
        }
    }
}
