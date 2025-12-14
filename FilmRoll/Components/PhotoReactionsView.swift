import SwiftUI

// MARK: - Reaction Types
enum PhotoReaction: String, CaseIterable, Identifiable {
    case love = "❤️"
    case fire = "🔥"
    case laugh = "😂"
    case wow = "😮"
    case sad = "😢"
    case clap = "👏"
    
    var id: String { rawValue }
}

// MARK: - Reaction Model
struct ReactionCount: Identifiable {
    let id = UUID()
    let reaction: PhotoReaction
    var count: Int
    var hasReacted: Bool
}

// MARK: - Photo Reactions View
struct PhotoReactionsView: View {
    let photoId: String
    @State private var reactions: [ReactionCount] = []
    @State private var showAllReactions = false
    let onReact: (PhotoReaction) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Show top reactions
            ForEach(topReactions) { reaction in
                ReactionBubble(
                    reaction: reaction,
                    onTap: { onReact(reaction.reaction) }
                )
            }
            
            // Add reaction button
            Button(action: { showAllReactions = true }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .sheet(isPresented: $showAllReactions) {
            ReactionPickerSheet(onSelect: { reaction in
                onReact(reaction)
                showAllReactions = false
            })
            .presentationDetents([.height(200)])
        }
    }
    
    private var topReactions: [ReactionCount] {
        reactions.filter { $0.count > 0 }.prefix(3).map { $0 }
    }
}

// MARK: - Reaction Bubble
struct ReactionBubble: View {
    let reaction: ReactionCount
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(reaction.reaction.rawValue)
                    .font(.system(size: 16))
                
                if reaction.count > 1 {
                    Text("\(reaction.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(reaction.hasReacted ? FilmRollTheme.accent.opacity(0.8) : Color.white.opacity(0.2))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Reaction Picker Sheet
struct ReactionPickerSheet: View {
    let onSelect: (PhotoReaction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Reaction")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FilmRollTheme.primaryText)
                .padding(.top, 20)
            
            HStack(spacing: 16) {
                ForEach(PhotoReaction.allCases) { reaction in
                    Button(action: { onSelect(reaction) }) {
                        Text(reaction.rawValue)
                            .font(.system(size: 36))
                            .frame(width: 50, height: 50)
                            .background(FilmRollTheme.cardBackground)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(FilmRollTheme.background)
    }
}

// MARK: - Inline Reaction Bar (for gallery)
struct InlineReactionBar: View {
    let photoId: String
    @State private var selectedReaction: PhotoReaction?
    @State private var showPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Quick reactions
            ForEach([PhotoReaction.love, .fire, .laugh], id: \.self) { reaction in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedReaction = reaction
                    }
                    HapticFeedback.light()
                }) {
                    Text(reaction.rawValue)
                        .font(.system(size: 20))
                        .scaleEffect(selectedReaction == reaction ? 1.3 : 1.0)
                }
            }
            
            // More reactions
            Button(action: { showPicker = true }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FilmRollTheme.cardBackground.opacity(0.9))
        .cornerRadius(20)
        .sheet(isPresented: $showPicker) {
            ReactionPickerSheet(onSelect: { reaction in
                selectedReaction = reaction
                showPicker = false
            })
            .presentationDetents([.height(200)])
        }
    }
}

#Preview {
    VStack {
        PhotoReactionsView(photoId: "test") { _ in }
        InlineReactionBar(photoId: "test")
    }
    .padding()
    .background(Color.black)
}
