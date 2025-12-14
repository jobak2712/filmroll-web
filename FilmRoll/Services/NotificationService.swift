import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    func scheduleRevealNotification(eventId: String, eventTitle: String, revealTime: Date) async {
        // M06: Don't schedule if reveal time is in the past
        guard revealTime > Date() else {
            print("⚠️ Reveal time is in the past, skipping notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📸 Photos Revealed!"
        content.body = "The photos from \(eventTitle) are now available to view!"
        content.sound = .default
        content.userInfo = ["event_id": eventId]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: revealTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reveal_\(eventId)", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled reveal notification for \(eventTitle)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func scheduleReminderNotification(eventId: String, eventTitle: String, reminderTime: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "📷 Don't forget to capture!"
        content.body = "The \(eventTitle) event is happening now. Open FilmRoll to take photos!"
        content.sound = .default
        content.userInfo = ["event_id": eventId]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reminder_\(eventId)", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule reminder: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications(for eventId: String) {
        let identifiers = ["reveal_\(eventId)", "reminder_\(eventId)"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
