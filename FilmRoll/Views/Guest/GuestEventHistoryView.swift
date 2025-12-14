import SwiftUI

// MARK: - Guest Event History Model
struct GuestEventHistory: Codable, Identifiable {
    let id: String
    let eventId: String
    let eventTitle: String
    let eventDate: Date
    let joinCode: String
    let participantId: String
    let guestName: String?
    let shotsTaken: Int
    let isRevealed: Bool
    let revealTime: Date?
    let joinedAt: Date
    let coverImageUrl: String?
    
    static func save(_ history: GuestEventHistory) {
        var histories = loadAll()
        // Remove existing entry for same event
        histories.removeAll { $0.eventId == history.eventId }
        histories.insert(history, at: 0)
        // Keep only last 20 events
        if histories.count > 20 {
            histories = Array(histories.prefix(20))
        }
        if let data = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(data, forKey: "guest_event_history")
        }
    }
    
    static func loadAll() -> [GuestEventHistory] {
        guard let data = UserDefaults.standard.data(forKey: "guest_event_history"),
              let histories = try? JSONDecoder().decode([GuestEventHistory].self, from: data) else {
            return []
        }
        return histories
    }
    
    static func remove(eventId: String) {
        var histories = loadAll()
        histories.removeAll { $0.eventId == eventId }
        if let data = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(data, forKey: "guest_event_history")
        }
    }
    
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: "guest_event_history")
    }
}

// MARK: - Guest Event History View
struct GuestEventHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventHistories: [GuestEventHistory] = []
    @State private var selectedEvent: GuestEventHistory?
    let onSelectEvent: (GuestEventHistory) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                if eventHistories.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Event History",
                        message: "Events you join will appear here for easy access"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(eventHistories) { history in
                                GuestEventHistoryCard(history: history) {
                                    onSelectEvent(history)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("My Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.primaryText)
                }
                
                if !eventHistories.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                GuestEventHistory.clearAll()
                                eventHistories = []
                            } label: {
                                Label("Clear History", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(FilmRollTheme.primaryText)
                        }
                    }
                }
            }
            .onAppear {
                eventHistories = GuestEventHistory.loadAll()
            }
        }
    }
}

// MARK: - Guest Event History Card
struct GuestEventHistoryCard: View {
    let history: GuestEventHistory
    let onTap: () -> Void
    
    private var statusText: String {
        if history.isRevealed {
            return "Photos Revealed"
        } else if let revealTime = history.revealTime {
            if revealTime > Date() {
                return "Reveals \(formatRevealTime(revealTime))"
            } else {
                return "Ready to View"
            }
        }
        return "Instant Reveal"
    }
    
    private var statusColor: Color {
        if history.isRevealed {
            return .green
        } else if let revealTime = history.revealTime, revealTime <= Date() {
            return FilmRollTheme.accent
        }
        return FilmRollTheme.secondaryText
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Cover image or placeholder
                ZStack {
                    if let coverUrl = history.coverImageUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                FilmRollTheme.buttonBackground
                            }
                        }
                    } else {
                        FilmRollTheme.buttonBackground
                    }
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                
                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    Text(history.eventTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FilmRollTheme.primaryText)
                        .lineLimit(1)
                    
                    Text(formatEventDate(history.eventDate))
                        .font(.system(size: 13))
                        .foregroundColor(FilmRollTheme.secondaryText)
                    
                    HStack(spacing: 8) {
                        // Status badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(statusColor)
                        }
                        
                        Text("•")
                            .foregroundColor(FilmRollTheme.secondaryText)
                        
                        Text("\(history.shotsTaken) photos taken")
                            .font(.system(size: 11))
                            .foregroundColor(FilmRollTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(16)
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatRevealTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    GuestEventHistoryView { _ in }
}
