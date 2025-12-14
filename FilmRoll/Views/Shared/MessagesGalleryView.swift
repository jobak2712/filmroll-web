import SwiftUI
import AVFoundation

struct MessagesGalleryView: View {
    let messages: [EventMessage]
    let isRevealed: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var playingVoiceNoteId: String?
    @StateObject private var voicePlayer = VoiceRecorderService()
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Messages")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Spacer()
                    
                    Text("\(messages.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FilmRollTheme.secondaryText)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if !isRevealed {
                    // Locked state
                    lockedView
                } else if messages.isEmpty {
                    // Empty state
                    emptyView
                } else {
                    // Messages grid
                    messagesGrid
                }
            }
        }
    }
    
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(FilmRollTheme.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            VStack(spacing: 8) {
                Text("Messages Locked")
                    .font(.custom("PlayfairDisplay-Bold", size: 24))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text("Messages will be revealed along with the photos")
                    .font(.system(size: 14))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(FilmRollTheme.secondaryText)
            
            VStack(spacing: 8) {
                Text("No Messages Yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text("Guests can leave voice notes, written messages, and stickers")
                    .font(.system(size: 14))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var messagesGrid: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(messages) { message in
                    messageCard(message)
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private func messageCard(_ message: EventMessage) -> some View {
        switch message.messageType {
        case .polaroidNote:
            polaroidCard(message)
        case .voiceNote:
            voiceNoteCard(message)
        case .sticker:
            stickerCard(message)
        case .doodle:
            doodleCard(message)
        }
    }
    
    private func polaroidCard(_ message: EventMessage) -> some View {
        let bgColor = PolaroidColor.allColors.first { $0.id == message.backgroundColor }?.color ?? .white
        let rotation = message.rotation ?? 0
        
        return VStack(spacing: 0) {
            // Note content
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(bgColor)
                
                Text(message.content)
                    .font(.custom("Noteworthy-Bold", size: 16))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(16)
            }
            .frame(minHeight: 120)
            
            // Bottom strip
            HStack {
                if let name = message.participantName {
                    Text("— \(name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                }
                Spacer()
                Text(formatDate(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .rotationEffect(.degrees(rotation))
        .padding(.horizontal, 20)
    }
    
    private func voiceNoteCard(_ message: EventMessage) -> some View {
        HStack(spacing: 16) {
            // Play button
            Button(action: {
                togglePlayback(message)
            }) {
                ZStack {
                    Circle()
                        .fill(FilmRollTheme.accent)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: playingVoiceNoteId == message.id ? "stop.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Waveform placeholder
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(FilmRollTheme.accent.opacity(0.5))
                            .frame(width: 3, height: CGFloat.random(in: 8...24))
                    }
                }
                
                HStack {
                    if let name = message.participantName {
                        Text(name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                    Spacer()
                    Text(formatDate(message.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
        }
        .padding(16)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private func stickerCard(_ message: EventMessage) -> some View {
        let sticker = StickerOption.allStickers.first { $0.id == message.content }
        
        return VStack(spacing: 8) {
            Text(sticker?.emoji ?? "❓")
                .font(.system(size: 64))
            
            HStack {
                if let name = message.participantName {
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                }
                Text("•")
                    .foregroundColor(FilmRollTheme.secondaryText)
                Text(formatDate(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private func doodleCard(_ message: EventMessage) -> some View {
        VStack(spacing: 8) {
            // Doodle image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(FilmRollTheme.inputBackground)
                .frame(height: 200)
                .overlay(
                    Image(systemName: "scribble")
                        .font(.system(size: 48))
                        .foregroundColor(FilmRollTheme.secondaryText)
                )
            
            HStack {
                if let name = message.participantName {
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                }
                Spacer()
                Text(formatDate(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
        .padding(16)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private func togglePlayback(_ message: EventMessage) {
        if playingVoiceNoteId == message.id {
            voicePlayer.stopPlayback()
            playingVoiceNoteId = nil
        } else {
            if let url = URL(string: message.content) {
                voicePlayer.play(url: url)
                playingVoiceNoteId = message.id
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
