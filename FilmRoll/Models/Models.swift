import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let avatarUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - Event Model
struct Event: Codable, Identifiable {
    let id: String
    let hostId: String
    let title: String
    let description: String?
    let eventDate: Date
    let shotLimitPerGuest: Int
    let participantCap: Int
    let revealMode: RevealMode
    let revealTime: Date?
    let coverImageUrl: String?
    let joinCode: String
    let isLocked: Bool
    let allowNewPhotos: Bool
    let isRevealed: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title, description
        case eventDate = "event_date"
        case shotLimitPerGuest = "shot_limit_per_guest"
        case participantCap = "participant_cap"
        case revealMode = "reveal_mode"
        case revealTime = "reveal_time"
        case coverImageUrl = "cover_image_url"
        case joinCode = "join_code"
        case isLocked = "is_locked"
        case allowNewPhotos = "allow_new_photos"
        case isRevealed = "is_revealed"
        case createdAt = "created_at"
    }
}

enum RevealMode: String, Codable {
    case instant
    case delayed
}

enum EventStatus: String {
    case live = "LIVE"
    case developed = "DEVELOPED"
    case new = "NEW"
}

// MARK: - Participant Model
struct Participant: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String?
    let guestName: String?
    let shotsTaken: Int
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case guestName = "guest_name"
        case shotsTaken = "shots_taken"
        case joinedAt = "joined_at"
    }
}

// MARK: - Photo Model
struct Photo: Codable, Identifiable {
    let id: String
    let eventId: String
    let participantId: String
    let storagePath: String
    let thumbnailPath: String?
    let fileSize: Int64
    let capturedAt: Date
    let uploadedAt: Date?
    let isUploaded: Bool
    let caption: String?
    let filterApplied: String?
    var reactions: [String: Int]?
    
    // Additional fields from getEventPhotos edge function
    var url: String?
    var thumbnailUrl: String?
    var participants: PhotoParticipant?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case participantId = "participant_id"
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case fileSize = "file_size"
        case capturedAt = "captured_at"
        case uploadedAt = "uploaded_at"
        case isUploaded = "is_uploaded"
        case caption
        case filterApplied = "filter_applied"
        case reactions
        case url
        case thumbnailUrl = "thumbnail_url"
        case participants
    }
}

// Nested participant info from getEventPhotos
struct PhotoParticipant: Codable {
    let guestName: String?
    
    enum CodingKeys: String, CodingKey {
        case guestName = "guest_name"
    }
}

// MARK: - Event with Stats
struct EventWithStats: Identifiable, Hashable {
    let event: Event
    let participantCount: Int
    let photoCount: Int
    let totalShots: Int
    
    var id: String { event.id }
    
    var status: EventStatus {
        if event.isRevealed {
            return .developed
        } else if photoCount > 0 {
            return .live
        } else {
            return .new
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(event.id)
    }
    
    static func == (lhs: EventWithStats, rhs: EventWithStats) -> Bool {
        lhs.event.id == rhs.event.id
    }
}

