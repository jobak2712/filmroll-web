import SwiftUI
import UserNotifications
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            // Force UI update by triggering objectWillChange
            objectWillChange.send()
        }
    }
    
    @Published var pushNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(pushNotificationsEnabled, forKey: "pushNotificationsEnabled")
            if pushNotificationsEnabled {
                requestNotificationPermission()
            }
        }
    }
    
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // User profile data
    @Published var userDisplayName: String {
        didSet {
            UserDefaults.standard.set(userDisplayName, forKey: "userDisplayName")
        }
    }
    
    @Published var userPhoneNumber: String {
        didSet {
            UserDefaults.standard.set(userPhoneNumber, forKey: "userPhoneNumber")
        }
    }
    
    @Published var userAvatarData: Data? {
        didSet {
            UserDefaults.standard.set(userAvatarData, forKey: "userAvatarData")
        }
    }
    
    // Stats (would normally come from backend)
    @Published var totalFilms: Int = 0
    @Published var guestsServed: Int = 0
    @Published var avgRating: Double = 0.0
    
    // MARK: - Initialization
    init() {
        // Load saved preferences
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.pushNotificationsEnabled = UserDefaults.standard.bool(forKey: "pushNotificationsEnabled")
        self.userDisplayName = UserDefaults.standard.string(forKey: "userDisplayName") ?? ""
        self.userPhoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
        self.userAvatarData = UserDefaults.standard.data(forKey: "userAvatarData")
        
        Task {
            await self.checkNotificationStatus()
        }
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                self.notificationPermissionStatus = granted ? .authorized : .denied
                if !granted {
                    self.pushNotificationsEnabled = false
                }
            }
        }
    }
    
    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
        
        if settings.authorizationStatus == .denied {
            pushNotificationsEnabled = false
        }
    }
    
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Stats Loading
    func loadUserStats(userId: String) async {
        // Use mock data if configured
        if SupabaseConfig.useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000)
            totalFilms = 28
            guestsServed = 142
            avgRating = 4.9
            return
        }
        
        // Fetch real stats from Supabase
        do {
            let events = try await SupabaseService.shared.getEvents(forHost: userId)
            totalFilms = events.count
            guestsServed = events.reduce(0) { $0 + $1.participantCount }
            // Rating would come from a reviews table - for now show 0 if no events
            avgRating = events.isEmpty ? 0.0 : 4.8
        } catch {
            // On error, show zeros
            totalFilms = 0
            guestsServed = 0
            avgRating = 0.0
        }
    }
    
    // MARK: - Profile Image
    func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            userAvatarData = data
        }
    }
    
    func getProfileImage() -> UIImage? {
        guard let data = userAvatarData else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Reset
    func resetAllSettings() {
        isDarkMode = false
        pushNotificationsEnabled = false
        userDisplayName = ""
        userPhoneNumber = ""
        userAvatarData = nil
    }
}
