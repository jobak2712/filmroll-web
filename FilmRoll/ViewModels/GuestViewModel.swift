import Foundation
import SwiftUI
import Photos
import Combine

@MainActor
class GuestViewModel: ObservableObject {
    @Published var event: Event?
    @Published var participant: Participant?
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var guestName = ""
    @Published var successMessage: String?
    
    // Camera state
    @Published var shotsTaken = 0
    @Published var isCapturing = false
    @Published var lastCapturedPhotoId: String?
    
    // Favorites
    @Published var favoritePhotoIds: Set<String> = []
    @Published var isSavingFavorites = false
    @Published var saveProgress: (current: Int, total: Int)?
    
    // Messages
    @Published var messages: [EventMessage] = []
    
    // Mock mode for testing - uses SupabaseConfig setting
    var useMockData = SupabaseConfig.useMockData
    
    nonisolated init() {}
    
    var shotLimit: Int {
        event?.shotLimitPerGuest ?? 0
    }
    
    var shotsRemaining: Int {
        max(0, shotLimit - shotsTaken)
    }
    
    var canTakePhoto: Bool {
        shotsRemaining > 0 && (event?.allowNewPhotos ?? false)
    }
    
    var isRevealed: Bool {
        guard let event = event else { return false }
        
        if event.isRevealed { return true }
        if event.revealMode == .instant { return true }
        
        if let revealTime = event.revealTime {
            return Date() >= revealTime
        }
        
        return false
    }
    
    // MARK: - Join Event
    func loadEvent(joinCode: String) async {
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 400_000_000)
            event = MockDataService.shared.getEvent(byCode: joinCode)
            if event == nil {
                errorMessage = "Event not found. Try: SARAH30, BEACH24, EMMAJAMES, or HOLIDAY24"
            }
            isLoading = false
            return
        }
        
        do {
            event = try await SupabaseService.shared.getEvent(joinCode: joinCode)
        } catch {
            errorMessage = "Event not found. Please check the code and try again."
        }
        
        isLoading = false
    }
    
    func joinEvent() async -> Bool {
        guard let event = event else { return false }
        
        // Check if event is locked
        if event.isLocked {
            errorMessage = "This event is no longer accepting new participants"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 600_000_000)
            let mockParticipant = Participant(
                id: UUID().uuidString,
                eventId: event.id,
                userId: nil,
                guestName: guestName.isEmpty ? nil : guestName,
                shotsTaken: 0,
                joinedAt: Date()
            )
            participant = mockParticipant
            shotsTaken = 0
            
            let session = GuestSession(
                eventId: event.id,
                participantId: mockParticipant.id,
                guestName: guestName.isEmpty ? nil : guestName,
                shotLimit: event.shotLimitPerGuest,
                shotsTaken: 0
            )
            GuestSession.save(session)
            
            isLoading = false
            return true
        }
        
        // Check participant cap
        do {
            let participants = try await SupabaseService.shared.getParticipants(eventId: event.id)
            if participants.count >= event.participantCap {
                errorMessage = "This event is full"
                isLoading = false
                return false
            }
        } catch {
            // Continue anyway, server will validate
        }
        
        do {
            participant = try await SupabaseService.shared.joinEvent(
                eventId: event.joinCode,
                guestName: guestName.isEmpty ? nil : guestName
            )
            shotsTaken = participant?.shotsTaken ?? 0
            
            // Save session for persistence
            if let participant = participant {
                let session = GuestSession(
                    eventId: event.id,
                    participantId: participant.id,
                    guestName: guestName.isEmpty ? nil : guestName,
                    shotLimit: event.shotLimitPerGuest,
                    shotsTaken: shotsTaken
                )
                GuestSession.save(session)
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to join event. Please try again."
            isLoading = false
            return false
        }
    }
    
    // MARK: - Photo Capture
    func capturePhoto(_ image: UIImage, caption: String? = nil, filter: String? = nil) async {
        guard let event = event, let participant = participant else { return }
        guard canTakePhoto else {
            errorMessage = "No shots remaining"
            return
        }
        
        isCapturing = true
        errorMessage = nil
        
        do {
            let photoId = try await PhotoService.shared.savePhoto(
                image,
                eventId: event.id,
                participantId: participant.id,
                caption: caption,
                filter: filter
            )
            
            shotsTaken += 1
            lastCapturedPhotoId = photoId
            
            // Update participant shot count on server
            try await SupabaseService.shared.updateParticipantShotCount(
                participantId: participant.id,
                count: shotsTaken
            )
            
            // Update saved session
            if var session = GuestSession.load() {
                session.shotsTaken = shotsTaken
                GuestSession.save(session)
            }
            
            // Haptic feedback
            HapticFeedback.success()
            
        } catch {
            errorMessage = "Failed to save photo. It will be uploaded when you're back online."
            HapticFeedback.error()
        }
        
        isCapturing = false
    }
    
    // MARK: - Load Photos
    func loadPhotos() async {
        guard let event = event else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Mock data mode
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000)
            photos = MockDataService.shared.getPhotos(forEvent: event.id)
            isLoading = false
            return
        }
        
        do {
            photos = try await SupabaseService.shared.getPhotos(eventId: event.id)
        } catch {
            errorMessage = "Failed to load photos"
        }
        
        isLoading = false
    }
    
    // MARK: - Favorites
    func toggleFavorite(photoId: String) {
        if favoritePhotoIds.contains(photoId) {
            favoritePhotoIds.remove(photoId)
        } else {
            favoritePhotoIds.insert(photoId)
        }
        HapticFeedback.selection()
    }
    
    func isFavorite(photoId: String) -> Bool {
        favoritePhotoIds.contains(photoId)
    }
    
    func saveFavoritesToCameraRoll() async {
        let favoritePhotos = photos.filter { favoritePhotoIds.contains($0.id) }
        
        guard !favoritePhotos.isEmpty else {
            errorMessage = "No favorites selected"
            return
        }
        
        isSavingFavorites = true
        saveProgress = (0, favoritePhotos.count)
        
        var savedCount = 0
        
        for (index, photo) in favoritePhotos.enumerated() {
            do {
                // Get signed URL for the photo
                let signedUrl = try await SupabaseService.shared.getSignedPhotoUrl(path: photo.storagePath)
                
                // Download the image
                guard let url = URL(string: signedUrl) else { continue }
                let image = try await ShareService.shared.downloadPhoto(from: url)
                
                // Save to camera roll
                try await ShareService.shared.saveToPhotoLibrary(image: image)
                
                savedCount += 1
                saveProgress = (index + 1, favoritePhotos.count)
                
            } catch {
                print("Failed to save photo \(photo.id): \(error)")
            }
        }
        
        isSavingFavorites = false
        saveProgress = nil
        
        if savedCount > 0 {
            successMessage = "Saved \(savedCount) photos to your camera roll"
            HapticFeedback.success()
        } else {
            errorMessage = "Failed to save photos. Please check your permissions."
        }
    }
    
    func saveAllPhotosToCameraRoll() async {
        guard !photos.isEmpty else {
            errorMessage = "No photos to save"
            return
        }
        
        isSavingFavorites = true
        saveProgress = (0, photos.count)
        
        var savedCount = 0
        
        for (index, photo) in photos.enumerated() {
            do {
                let signedUrl = try await SupabaseService.shared.getSignedPhotoUrl(path: photo.storagePath)
                guard let url = URL(string: signedUrl) else { continue }
                let image = try await ShareService.shared.downloadPhoto(from: url)
                try await ShareService.shared.saveToPhotoLibrary(image: image)
                
                savedCount += 1
                saveProgress = (index + 1, photos.count)
                
            } catch {
                print("Failed to save photo \(photo.id): \(error)")
            }
        }
        
        isSavingFavorites = false
        saveProgress = nil
        
        if savedCount > 0 {
            successMessage = "Saved \(savedCount) photos to your camera roll"
            HapticFeedback.success()
        } else {
            errorMessage = "Failed to save photos"
        }
    }
    
    // MARK: - Download Single Photo
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
    
    // MARK: - Share Photo
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
    
    // MARK: - Request Notification
    func requestRevealNotification() async {
        guard let event = event, let revealTime = event.revealTime else { return }
        
        let granted = await NotificationService.shared.requestPermission()
        
        if granted {
            await NotificationService.shared.scheduleRevealNotification(
                eventId: event.id,
                eventTitle: event.title,
                revealTime: revealTime
            )
            successMessage = "We'll notify you when photos are revealed!"
        } else {
            errorMessage = "Please enable notifications in Settings"
        }
    }
    
    // MARK: - Messages
    func loadMessages() async {
        guard let event = event else { return }
        
        if useMockData {
            messages = MockDataService.shared.getMessages(forEvent: event.id)
            return
        }
        
        // TODO: Load from Supabase
    }
    
    func sendMessage(_ message: EventMessage) {
        messages.append(message)
        successMessage = "Message sent! It will be revealed with the photos."
        HapticFeedback.success()
        
        // TODO: Save to Supabase
    }
    
    // MARK: - Restore Session
    func restoreSession(_ session: GuestSession) async {
        // Load the event from the session
        if useMockData {
            // Find event by ID in mock data
            event = MockDataService.shared.getEvent(byId: session.eventId)
        } else {
            do {
                event = try await SupabaseService.shared.getEvent(id: session.eventId)
            } catch {
                // Session invalid, clear it
                GuestSession.clear()
                return
            }
        }
        
        // Restore participant
        participant = Participant(
            id: session.participantId,
            eventId: session.eventId,
            userId: nil,
            guestName: session.guestName,
            shotsTaken: session.shotsTaken,
            joinedAt: Date() // We don't store this, so use now
        )
        
        shotsTaken = session.shotsTaken
        guestName = session.guestName ?? ""
    }
    
    // MARK: - Leave Event
    func leaveEvent() {
        GuestSession.clear()
        // Clear any stuck pending uploads when leaving event
        PhotoService.shared.clearAllPendingUploads()
        event = nil
        participant = nil
        photos = []
        shotsTaken = 0
        favoritePhotoIds = []
    }
    
    // MARK: - Helpers
    func formatEventDate() -> String {
        guard let event = event else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: event.eventDate)
    }
    
    func formatEventTime() -> String {
        guard let event = event else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.eventDate)
    }
    
    func formatRevealInfo() -> String {
        guard let event = event else { return "" }
        
        if event.revealMode == .instant {
            return "Photos visible instantly"
        } else if let revealTime = event.revealTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            // M03: Show different text for past vs future reveal
            if revealTime <= Date() {
                return "Revealed \(formatter.string(from: revealTime))"
            } else {
                return "Reveals \(formatter.string(from: revealTime))"
            }
        }
        return ""
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Reactions
    func addReaction(to photoId: String, emoji: String) {
        guard let index = photos.firstIndex(where: { $0.id == photoId }) else { return }
        
        let photo = photos[index]
        var reactions = photo.reactions ?? [:]
        reactions[emoji, default: 0] += 1
        
        // Create updated photo with new reactions
        let updatedPhoto = Photo(
            id: photo.id,
            eventId: photo.eventId,
            participantId: photo.participantId,
            storagePath: photo.storagePath,
            thumbnailPath: photo.thumbnailPath,
            fileSize: photo.fileSize,
            capturedAt: photo.capturedAt,
            uploadedAt: photo.uploadedAt,
            isUploaded: photo.isUploaded,
            caption: photo.caption,
            filterApplied: photo.filterApplied,
            reactions: reactions
        )
        
        photos[index] = updatedPhoto
        HapticFeedback.light()
        
        // TODO: Sync to Supabase
    }
}
