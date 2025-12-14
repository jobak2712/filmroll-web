import Foundation

// MARK: - Mock Data Service
/// Provides mock data for testing and previews without Supabase connection
final class MockDataService {
    static let shared = MockDataService()
    
    // MARK: - Test Credentials
    static let testEmail = "test@filmroll.app"
    static let testPassword = "Test1234!"
    
    // MARK: - Mock User
    let mockUser = User(
        id: "user-001",
        email: "test@filmroll.app",
        displayName: "Alex Johnson",
        avatarUrl: nil,
        createdAt: Date().addingTimeInterval(-86400 * 30) // 30 days ago
    )
    
    // MARK: - Mock Events
    lazy var mockEvents: [Event] = [
        Event(
            id: "event-001",
            hostId: "user-001",
            title: "Sarah's Birthday Bash",
            description: "Celebrating Sarah's 30th birthday! 🎂",
            eventDate: Date().addingTimeInterval(86400 * 2), // 2 days from now
            shotLimitPerGuest: 36,
            participantCap: 50,
            revealMode: .delayed,
            revealTime: Date().addingTimeInterval(86400 * 3), // 3 days from now
            coverImageUrl: "https://picsum.photos/seed/birthday/400/300",
            joinCode: "SARAH30",
            isLocked: false,
            allowNewPhotos: true,
            isRevealed: false,
            createdAt: Date().addingTimeInterval(-86400 * 5)
        ),
        Event(
            id: "event-002",
            hostId: "user-001",
            title: "Beach Weekend Trip",
            description: "Summer vibes at Malibu! 🏖️",
            eventDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            shotLimitPerGuest: 24,
            participantCap: 20,
            revealMode: .delayed,
            revealTime: Date().addingTimeInterval(-86400 * 5),
            coverImageUrl: "https://picsum.photos/seed/beach/400/300",
            joinCode: "BEACH24",
            isLocked: false,
            allowNewPhotos: false,
            isRevealed: true,
            createdAt: Date().addingTimeInterval(-86400 * 14)
        ),
        Event(
            id: "event-003",
            hostId: "user-001",
            title: "Wedding Reception",
            description: "Emma & James tie the knot! 💒",
            eventDate: Date(),
            shotLimitPerGuest: 48,
            participantCap: 100,
            revealMode: .instant,
            revealTime: nil,
            coverImageUrl: "https://picsum.photos/seed/wedding/400/300",
            joinCode: "EMMAJAMES",
            isLocked: false,
            allowNewPhotos: true,
            isRevealed: false,
            createdAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Event(
            id: "event-004",
            hostId: "user-001",
            title: "Company Holiday Party",
            description: "Annual team celebration 🎄",
            eventDate: Date().addingTimeInterval(86400 * 14),
            shotLimitPerGuest: 36,
            participantCap: 75,
            revealMode: .delayed,
            revealTime: Date().addingTimeInterval(86400 * 15),
            coverImageUrl: "https://picsum.photos/seed/holiday/400/300",
            joinCode: "HOLIDAY24",
            isLocked: false,
            allowNewPhotos: true,
            isRevealed: false,
            createdAt: Date()
        )
    ]

    
    // MARK: - Mock Events with Stats
    lazy var mockEventsWithStats: [EventWithStats] = [
        EventWithStats(event: mockEvents[0], participantCount: 12, photoCount: 24, totalShots: 432),
        EventWithStats(event: mockEvents[1], participantCount: 8, photoCount: 48, totalShots: 192),
        EventWithStats(event: mockEvents[2], participantCount: 35, photoCount: 156, totalShots: 1680),
        EventWithStats(event: mockEvents[3], participantCount: 0, photoCount: 0, totalShots: 0)
    ]
    
    // MARK: - Mock Participants
    lazy var mockParticipants: [Participant] = [
        Participant(id: "part-001", eventId: "event-001", userId: nil, guestName: "Mike Chen", shotsTaken: 12, joinedAt: Date().addingTimeInterval(-3600)),
        Participant(id: "part-002", eventId: "event-001", userId: nil, guestName: "Emma Wilson", shotsTaken: 8, joinedAt: Date().addingTimeInterval(-7200)),
        Participant(id: "part-003", eventId: "event-001", userId: nil, guestName: "David Kim", shotsTaken: 4, joinedAt: Date().addingTimeInterval(-10800)),
        Participant(id: "part-004", eventId: "event-001", userId: nil, guestName: nil, shotsTaken: 0, joinedAt: Date().addingTimeInterval(-1800)),
        Participant(id: "part-005", eventId: "event-002", userId: nil, guestName: "Sophie Taylor", shotsTaken: 24, joinedAt: Date().addingTimeInterval(-86400 * 8)),
        Participant(id: "part-006", eventId: "event-002", userId: nil, guestName: "James Brown", shotsTaken: 18, joinedAt: Date().addingTimeInterval(-86400 * 8)),
        Participant(id: "part-007", eventId: "event-003", userId: nil, guestName: "Wedding Guest 1", shotsTaken: 6, joinedAt: Date().addingTimeInterval(-3600)),
        Participant(id: "part-008", eventId: "event-003", userId: nil, guestName: "Wedding Guest 2", shotsTaken: 10, joinedAt: Date().addingTimeInterval(-5400))
    ]
    
    // MARK: - Mock Photos
    lazy var mockPhotos: [Photo] = {
        var photos: [Photo] = []
        let photoSeeds = ["party1", "party2", "beach1", "beach2", "wedding1", "wedding2", "friends1", "friends2", "cake", "dance", "sunset", "group"]
        let captions = ["Best night ever! 🎉", nil, "Beach vibes ☀️", "Squad goals", nil, "Forever and always 💕", "Friends forever", nil, "Yummy! 🎂", "Dance floor moments", "Golden hour magic 🌅", "The whole crew!"]
        let filters = [nil, "Vintage", nil, "Warm", "B&W", nil, "Disposable", nil, "Vivid", nil, "Warm", nil]
        let reactionSets: [[String: Int]?] = [
            ["❤️": 5, "🔥": 3], nil, ["😍": 2], ["🎉": 4, "❤️": 2], nil, ["💕": 8, "😭": 3], nil, ["😂": 2], ["🎂": 6], ["🔥": 4], ["😍": 5, "❤️": 3], ["🎉": 7]
        ]
        
        for (index, seed) in photoSeeds.enumerated() {
            photos.append(Photo(
                id: "photo-\(String(format: "%03d", index + 1))",
                eventId: index < 4 ? "event-001" : (index < 8 ? "event-002" : "event-003"),
                participantId: "part-00\((index % 4) + 1)",
                storagePath: "https://picsum.photos/seed/\(seed)/800/600",
                thumbnailPath: "https://picsum.photos/seed/\(seed)/200/150",
                fileSize: Int64.random(in: 1_500_000...4_000_000),
                capturedAt: Date().addingTimeInterval(Double(-3600 * (index + 1))),
                uploadedAt: Date().addingTimeInterval(Double(-3600 * index)),
                isUploaded: true,
                caption: captions[index],
                filterApplied: filters[index],
                reactions: reactionSets[index]
            ))
        }
        return photos
    }()
    
    // MARK: - Mock Messages
    lazy var mockMessages: [EventMessage] = [
        EventMessage(
            id: "msg-001",
            eventId: "event-001",
            participantId: "part-001",
            participantName: "Mike Chen",
            messageType: .polaroidNote,
            content: "Happy Birthday Sarah! 🎂 Hope this year brings you all the joy and success you deserve!",
            backgroundColor: "pink",
            rotation: -3.5,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        EventMessage(
            id: "msg-002",
            eventId: "event-001",
            participantId: "part-002",
            participantName: "Emma Wilson",
            messageType: .sticker,
            content: "party",
            backgroundColor: nil,
            rotation: nil,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        EventMessage(
            id: "msg-003",
            eventId: "event-001",
            participantId: "part-003",
            participantName: "David Kim",
            messageType: .polaroidNote,
            content: "Best party ever! Thanks for inviting us 🎉",
            backgroundColor: "cream",
            rotation: 2.0,
            createdAt: Date().addingTimeInterval(-5400)
        ),
        EventMessage(
            id: "msg-004",
            eventId: "event-002",
            participantId: "part-005",
            participantName: "Sophie Taylor",
            messageType: .sticker,
            content: "sun",
            backgroundColor: nil,
            rotation: nil,
            createdAt: Date().addingTimeInterval(-86400 * 7)
        ),
        EventMessage(
            id: "msg-005",
            eventId: "event-002",
            participantId: "part-006",
            participantName: "James Brown",
            messageType: .polaroidNote,
            content: "What an amazing weekend! The sunset was incredible 🌅",
            backgroundColor: "blue",
            rotation: -1.5,
            createdAt: Date().addingTimeInterval(-86400 * 7)
        )
    ]
    
    // MARK: - Helper Methods
    func getEventsForHost(_ hostId: String) -> [EventWithStats] {
        return mockEventsWithStats.filter { $0.event.hostId == hostId }
    }
    
    func getEvent(byId id: String) -> Event? {
        return mockEvents.first { $0.id == id }
    }
    
    func getEvent(byCode code: String) -> Event? {
        return mockEvents.first { $0.joinCode.lowercased() == code.lowercased() }
    }
    
    func getPhotos(forEvent eventId: String) -> [Photo] {
        return mockPhotos.filter { $0.eventId == eventId }
    }
    
    func getParticipants(forEvent eventId: String) -> [Participant] {
        return mockParticipants.filter { $0.eventId == eventId }
    }
    
    func getMessages(forEvent eventId: String) -> [EventMessage] {
        return mockMessages.filter { $0.eventId == eventId }
    }
}

// MARK: - Preview Helpers
extension MockDataService {
    static var previewEvent: Event { shared.mockEvents[0] }
    static var previewEventWithStats: EventWithStats { shared.mockEventsWithStats[0] }
    static var previewPhoto: Photo { shared.mockPhotos[0] }
    static var previewParticipant: Participant { shared.mockParticipants[0] }
    static var previewUser: User { shared.mockUser }
}
