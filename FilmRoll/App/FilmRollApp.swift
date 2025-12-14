import SwiftUI
import Combine

@main
struct FilmRollApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    setupAppearance()
                }
                .id(settingsManager.isDarkMode) // Force view refresh on theme change
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle filmroll://join/CODE or https://filmroll.app/join/CODE
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        
        let pathComponents = components.path.split(separator: "/")
        
        if pathComponents.count >= 2 && pathComponents[0] == "join" {
            let joinCode = String(pathComponents[1])
            appState.pendingJoinCode = joinCode
            appState.isGuestMode = true
        }
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FilmRollTheme.background)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(FilmRollTheme.primaryText),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(FilmRollTheme.cardBackground)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure page control
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(FilmRollTheme.accent)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(FilmRollTheme.divider)
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var currentGuestSession: GuestSession?
    @Published var isGuestMode: Bool = false
    @Published var pendingJoinCode: String?
    @Published var showOfflineBanner: Bool = false
    
    nonisolated init() {}
}

struct GuestSession: Codable {
    let eventId: String
    let participantId: String
    let guestName: String?
    let shotLimit: Int
    var shotsTaken: Int
    let joinedAt: Date
    
    init(eventId: String, participantId: String, guestName: String?, shotLimit: Int, shotsTaken: Int) {
        self.eventId = eventId
        self.participantId = participantId
        self.guestName = guestName
        self.shotLimit = shotLimit
        self.shotsTaken = shotsTaken
        self.joinedAt = Date()
    }
    
    // Persist current active session
    static func save(_ session: GuestSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "guest_session")
            // Also save to session history for persistence
            saveToHistory(session)
        }
    }
    
    static func load() -> GuestSession? {
        guard let data = UserDefaults.standard.data(forKey: "guest_session"),
              let session = try? JSONDecoder().decode(GuestSession.self, from: data) else {
            return nil
        }
        return session
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: "guest_session")
    }
    
    // Session history for multiple events
    private static func saveToHistory(_ session: GuestSession) {
        var history = loadHistory()
        // Remove existing entry for same event
        history.removeAll { $0.eventId == session.eventId }
        history.insert(session, at: 0)
        // Keep last 10 sessions
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "guest_session_history")
        }
    }
    
    static func loadHistory() -> [GuestSession] {
        guard let data = UserDefaults.standard.data(forKey: "guest_session_history"),
              let history = try? JSONDecoder().decode([GuestSession].self, from: data) else {
            return []
        }
        return history
    }
    
    static func loadSession(forEventId eventId: String) -> GuestSession? {
        return loadHistory().first { $0.eventId == eventId }
    }
}
