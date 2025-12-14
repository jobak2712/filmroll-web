import Foundation
import SwiftUI

// MARK: - Message Types
enum MessageType: String, Codable {
    case voiceNote = "voice"
    case polaroidNote = "polaroid"
    case sticker = "sticker"
    case doodle = "doodle"
}

// MARK: - Event Message Model
struct EventMessage: Codable, Identifiable {
    let id: String
    let eventId: String
    let participantId: String
    let participantName: String?
    let messageType: MessageType
    let content: String // Text for polaroid, URL for voice/doodle, sticker ID for stickers
    let backgroundColor: String? // For polaroid notes
    let rotation: Double? // Slight rotation for polaroid effect
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case participantId = "participant_id"
        case participantName = "participant_name"
        case messageType = "message_type"
        case content
        case backgroundColor = "background_color"
        case rotation
        case createdAt = "created_at"
    }
}

// MARK: - Sticker Options
struct StickerOption: Identifiable {
    let id: String
    let emoji: String
    let name: String
    
    static let allStickers: [StickerOption] = [
        StickerOption(id: "heart", emoji: "❤️", name: "Heart"),
        StickerOption(id: "party", emoji: "🎉", name: "Party"),
        StickerOption(id: "camera", emoji: "📸", name: "Camera"),
        StickerOption(id: "star", emoji: "⭐", name: "Star"),
        StickerOption(id: "fire", emoji: "🔥", name: "Fire"),
        StickerOption(id: "laugh", emoji: "😂", name: "Laugh"),
        StickerOption(id: "love", emoji: "😍", name: "Love"),
        StickerOption(id: "cool", emoji: "😎", name: "Cool"),
        StickerOption(id: "clap", emoji: "👏", name: "Clap"),
        StickerOption(id: "thumbsup", emoji: "👍", name: "Thumbs Up"),
        StickerOption(id: "celebrate", emoji: "🥳", name: "Celebrate"),
        StickerOption(id: "sparkle", emoji: "✨", name: "Sparkle"),
        StickerOption(id: "cake", emoji: "🎂", name: "Cake"),
        StickerOption(id: "gift", emoji: "🎁", name: "Gift"),
        StickerOption(id: "balloon", emoji: "🎈", name: "Balloon"),
        StickerOption(id: "confetti", emoji: "🎊", name: "Confetti"),
        StickerOption(id: "champagne", emoji: "🍾", name: "Champagne"),
        StickerOption(id: "cheers", emoji: "🥂", name: "Cheers"),
        StickerOption(id: "rainbow", emoji: "🌈", name: "Rainbow"),
        StickerOption(id: "sun", emoji: "☀️", name: "Sun")
    ]
}

// MARK: - Polaroid Colors
struct PolaroidColor: Identifiable {
    let id: String
    let color: Color
    let name: String
    
    static let allColors: [PolaroidColor] = [
        PolaroidColor(id: "white", color: .white, name: "Classic"),
        PolaroidColor(id: "cream", color: Color(hex: "FFF8E7"), name: "Cream"),
        PolaroidColor(id: "pink", color: Color(hex: "FFE4EC"), name: "Pink"),
        PolaroidColor(id: "blue", color: Color(hex: "E4F0FF"), name: "Blue"),
        PolaroidColor(id: "mint", color: Color(hex: "E4FFF0"), name: "Mint"),
        PolaroidColor(id: "lavender", color: Color(hex: "F0E4FF"), name: "Lavender"),
        PolaroidColor(id: "peach", color: Color(hex: "FFE8D9"), name: "Peach"),
        PolaroidColor(id: "yellow", color: Color(hex: "FFFDE7"), name: "Yellow")
    ]
}
