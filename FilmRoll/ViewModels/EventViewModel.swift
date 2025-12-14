import Foundation
import SwiftUI
import Photos
import Combine

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [EventWithStats] = []
    @Published var currentEvent: Event?
    @Published var participants: [Participant] = []
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Stats
    @Published var activeRollsCount = 0
    @Published var totalShotsCount = 0
    
    // Create Event Form
    @Published var title = ""
    @Published var description = ""
    @Published var eventDate = Date() {
        didSet {
            // Update reveal time to be 2 hours after event date when event date changes
            if revealTime < eventDate {
                revealTime = eventDate.addingTimeInterval(7200) // +2 hours after event
            }
        }
    }
    @Published var shotLimitPerGuest = 12
    @Published var participantCap = 25
    @Published var revealModeIndex = 0 // 0 = instant, 1 = delayed
    @Published var revealTime = Date().addingTimeInterval(7200) // +2 hours from now (will update with eventDate)
    
    // Settings Form
    @Published var settingsRevealTime = Date()
    @Published var settingsShotLimit = 12
    @Published var settingsParticipantCap = 25
    @Published var settingsIsLocked = false
    @Published var settingsAllowNewPhotos = true
    
    // Download progress
    @Published var isDownloading = false
    @Published var downloadProgress: (current: Int, total: Int)?
    
    // Mock mode for testing - uses SupabaseConfig
    var useMockData: Bool { SupabaseConfig.useMockData }
    
    nonisolated init() {}
    
    var revealMode: RevealMode {
        revealModeIndex == 0 ? .instant : .delayed
    }
    
    // MARK: - Load Events
    func loadEvents(hostId: String) async {
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network
            events = MockDataService.shared.getEventsForHost(hostId)
            calculateStats()
            isLoading = false
            return
        }
        
        do {
            events = try await SupabaseService.shared.getEvents(forHost: hostId)
            calculateStats()
        } catch {
            errorMessage = "Failed to load events"
        }
        
        isLoading = false
    }
    
    private func calculateStats() {
        activeRollsCount = events.filter { !$0.event.isRevealed }.count
        totalShotsCount = events.reduce(0) { $0 + $1.photoCount }
    }
    
    // MARK: - Create Event
    func createEvent(hostId: String) async -> Event? {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter an event title"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 800_000_000)
            let newEvent = Event(
                id: UUID().uuidString,
                hostId: hostId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                eventDate: eventDate,
                shotLimitPerGuest: shotLimitPerGuest,
                participantCap: participantCap,
                revealMode: revealMode,
                revealTime: revealMode == .delayed ? revealTime : nil,
                coverImageUrl: "https://picsum.photos/seed/\(UUID().uuidString)/400/300",
                joinCode: String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! }),
                isLocked: false,
                allowNewPhotos: true,
                isRevealed: false,
                createdAt: Date()
            )
            let newEventWithStats = EventWithStats(event: newEvent, participantCount: 0, photoCount: 0, totalShots: 0)
            events.insert(newEventWithStats, at: 0)
            clearForm()
            isLoading = false
            HapticFeedback.success()
            return newEvent
        }
        
        let request = CreateEventRequest(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            eventDate: eventDate,
            shotLimitPerGuest: shotLimitPerGuest,
            participantCap: participantCap,
            revealMode: revealMode,
            revealTime: revealMode == .delayed ? revealTime : nil
        )
        
        do {
            let event = try await SupabaseService.shared.createEvent(request)
            clearForm()
            isLoading = false
            HapticFeedback.success()
            return event
        } catch {
            errorMessage = "Failed to create event. Please try again."
            isLoading = false
            HapticFeedback.error()
            return nil
        }
    }
    
    // MARK: - Load Event Details
    func loadEvent(id: String) async {
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 400_000_000)
            currentEvent = MockDataService.shared.getEvent(byId: id)
            participants = MockDataService.shared.getParticipants(forEvent: id)
            photos = MockDataService.shared.getPhotos(forEvent: id)
            
            if let event = currentEvent {
                settingsRevealTime = event.revealTime ?? Date()
                settingsShotLimit = event.shotLimitPerGuest
                settingsParticipantCap = event.participantCap
                settingsIsLocked = event.isLocked
                settingsAllowNewPhotos = event.allowNewPhotos
            }
            isLoading = false
            return
        }
        
        do {
            currentEvent = try await SupabaseService.shared.getEvent(id: id)
            participants = try await SupabaseService.shared.getParticipants(eventId: id)
            photos = try await SupabaseService.shared.getPhotos(eventId: id, isHost: true)
            
            // Initialize settings form with current values
            if let event = currentEvent {
                settingsRevealTime = event.revealTime ?? Date()
                settingsShotLimit = event.shotLimitPerGuest
                settingsParticipantCap = event.participantCap
                settingsIsLocked = event.isLocked
                settingsAllowNewPhotos = event.allowNewPhotos
            }
        } catch {
            errorMessage = "Failed to load event"
        }
        
        isLoading = false
    }
    
    func loadEventByCode(_ code: String) async {
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 400_000_000)
            currentEvent = MockDataService.shared.getEvent(byCode: code)
            if currentEvent == nil {
                errorMessage = "Event not found. Try: SARAH30, BEACH24, EMMAJAMES, or HOLIDAY24"
            }
            isLoading = false
            return
        }
        
        do {
            currentEvent = try await SupabaseService.shared.getEvent(joinCode: code)
        } catch {
            errorMessage = "Event not found"
        }
        
        isLoading = false
    }
    
    func refreshPhotos(isHost: Bool = true) async {
        guard let event = currentEvent else { return }
        
        do {
            photos = try await SupabaseService.shared.getPhotos(eventId: event.id, isHost: isHost)
        } catch {
            // Silent fail for refresh
        }
    }
    
    // MARK: - Event Actions
    func revealEvent() async {
        guard let event = currentEvent else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 800_000_000) // Simulate network
            
            // Create revealed version of the event
            let revealedEvent = Event(
                id: event.id,
                hostId: event.hostId,
                title: event.title,
                description: event.description,
                eventDate: event.eventDate,
                shotLimitPerGuest: event.shotLimitPerGuest,
                participantCap: event.participantCap,
                revealMode: event.revealMode,
                revealTime: Date(), // Set to now
                coverImageUrl: event.coverImageUrl,
                joinCode: event.joinCode,
                isLocked: event.isLocked,
                allowNewPhotos: false, // Disable new photos after reveal
                isRevealed: true, // Mark as revealed
                createdAt: event.createdAt
            )
            
            currentEvent = revealedEvent
            
            // Update in events list too
            if let index = events.firstIndex(where: { $0.event.id == event.id }) {
                events[index] = EventWithStats(
                    event: revealedEvent,
                    participantCount: events[index].participantCount,
                    photoCount: events[index].photoCount,
                    totalShots: events[index].totalShots
                )
            }
            
            successMessage = "Photos revealed! All participants can now view the gallery."
            isLoading = false
            HapticFeedback.success()
            return
        }
        
        do {
            try await SupabaseService.shared.revealEvent(id: event.id)
            currentEvent = try await SupabaseService.shared.getEvent(id: event.id)
            successMessage = "Photos revealed! All participants can now view the gallery."
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to reveal event"
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    func saveSettings() async -> Bool {
        guard let event = currentEvent else { return false }
        
        isLoading = true
        errorMessage = nil
        
        // Create updated event
        let updatedEvent = Event(
            id: event.id,
            hostId: event.hostId,
            title: event.title,
            description: event.description,
            eventDate: event.eventDate,
            shotLimitPerGuest: settingsShotLimit,
            participantCap: settingsParticipantCap,
            revealMode: event.revealMode,
            revealTime: event.revealMode == .delayed ? settingsRevealTime : nil,
            coverImageUrl: event.coverImageUrl,
            joinCode: event.joinCode,
            isLocked: settingsIsLocked,
            allowNewPhotos: settingsAllowNewPhotos,
            isRevealed: event.isRevealed,
            createdAt: event.createdAt
        )
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            currentEvent = updatedEvent
            
            // Update in events list
            if let index = events.firstIndex(where: { $0.event.id == event.id }) {
                events[index] = EventWithStats(
                    event: updatedEvent,
                    participantCount: events[index].participantCount,
                    photoCount: events[index].photoCount,
                    totalShots: events[index].totalShots
                )
            }
            
            successMessage = "Settings saved"
            isLoading = false
            HapticFeedback.success()
            return true
        }
        
        do {
            currentEvent = try await SupabaseService.shared.updateEvent(updatedEvent)
            successMessage = "Settings saved"
            isLoading = false
            HapticFeedback.success()
            return true
        } catch {
            errorMessage = "Failed to save settings"
            isLoading = false
            HapticFeedback.error()
            return false
        }
    }
    
    func endEvent() async {
        guard currentEvent != nil else { return }
        
        // Lock the event and disable new photos
        settingsIsLocked = true
        settingsAllowNewPhotos = false
        
        _ = await saveSettings()
    }
    
    func deleteEvent() async -> Bool {
        guard let event = currentEvent else { return false }
        
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            events.removeAll { $0.event.id == event.id }
            currentEvent = nil
            isLoading = false
            HapticFeedback.success()
            return true
        }
        
        do {
            try await SupabaseService.shared.deleteEvent(id: event.id)
            isLoading = false
            HapticFeedback.success()
            return true
        } catch {
            errorMessage = "Failed to delete event"
            isLoading = false
            HapticFeedback.error()
            return false
        }
    }
    
    func deletePhoto(id: String) async {
        // Mock data mode
        if useMockData {
            photos.removeAll { $0.id == id }
            HapticFeedback.success()
            return
        }
        
        do {
            try await SupabaseService.shared.deletePhoto(id: id)
            photos.removeAll { $0.id == id }
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to delete photo"
            HapticFeedback.error()
        }
    }
    
    // MARK: - Download Photos
    func downloadAllPhotos() async {
        guard !photos.isEmpty else {
            errorMessage = "No photos to download"
            return
        }
        
        isDownloading = true
        downloadProgress = (0, photos.count)
        
        var savedCount = 0
        
        for (index, photo) in photos.enumerated() {
            do {
                let signedUrl = try await SupabaseService.shared.getSignedPhotoUrl(path: photo.storagePath)
                guard let url = URL(string: signedUrl) else { continue }
                
                let image = try await ShareService.shared.downloadPhoto(from: url)
                try await ShareService.shared.saveToPhotoLibrary(image: image)
                
                savedCount += 1
                downloadProgress = (index + 1, photos.count)
                
            } catch {
                print("Failed to download photo \(photo.id): \(error)")
            }
        }
        
        isDownloading = false
        downloadProgress = nil
        
        if savedCount > 0 {
            successMessage = "Downloaded \(savedCount) photos to your camera roll"
            HapticFeedback.success()
        } else {
            errorMessage = "Failed to download photos"
        }
    }
    
    func downloadPhoto(_ photo: Photo) async {
        do {
            let signedUrl = try await SupabaseService.shared.getSignedPhotoUrl(path: photo.storagePath)
            guard let url = URL(string: signedUrl) else {
                errorMessage = "Invalid photo URL"
                return
            }
            
            let image = try await ShareService.shared.downloadPhoto(from: url)
            try await ShareService.shared.saveToPhotoLibrary(image: image)
            
            successMessage = "Photo saved to camera roll"
            HapticFeedback.success()
            
        } catch {
            errorMessage = "Failed to download photo"
            HapticFeedback.error()
        }
    }
    
    // MARK: - Share
    func sharePhoto(_ photo: Photo) async {
        do {
            let signedUrl = try await SupabaseService.shared.getSignedPhotoUrl(path: photo.storagePath)
            guard let url = URL(string: signedUrl) else { return }
            
            let image = try await ShareService.shared.downloadPhoto(from: url)
            ShareService.shared.sharePhoto(image: image)
            
        } catch {
            errorMessage = "Failed to share photo"
        }
    }
    
    func shareEventLink() {
        guard let event = currentEvent else { return }
        ShareService.shared.shareEventLink(event: event)
    }
    
    // MARK: - Helpers
    func clearForm() {
        title = ""
        description = ""
        eventDate = Date()
        shotLimitPerGuest = 12
        participantCap = 25
        revealModeIndex = 0
        revealTime = Date().addingTimeInterval(86400)
    }
    
    func getJoinUrl(for event: Event) -> String {
        // Use Supabase function URL for landing page
        // When you have a custom domain, change this to: "https://filmroll.app/join/\(event.joinCode)"
        "\(SupabaseConfig.functionsURL)/joinPage/\(event.joinCode)"
    }
    
    func copyJoinLink() {
        guard let event = currentEvent else { return }
        UIPasteboard.general.string = getJoinUrl(for: event)
        HapticFeedback.success()
    }
    
    func timeUntilReveal(for event: Event) -> String {
        guard let revealTime = event.revealTime else { return "—" }
        
        let interval = revealTime.timeIntervalSinceNow
        if interval <= 0 { return "Now" }
        
        let hours = Int(interval) / 3600
        if hours > 0 { return "\(hours)h" }
        
        let minutes = (Int(interval) % 3600) / 60
        return "\(minutes)m"
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

