import SwiftUI

// MARK: - Card Container
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(FilmRollTheme.paddingMedium)
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = FilmRollTheme.accent
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FilmRollTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(FilmRollTheme.secondaryText)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusMedium)
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: EventWithStats
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                        .fill(FilmRollTheme.inputBackground)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        )
                    
                    // Status Badge
                    StatusBadge(status: event.status)
                        .padding(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(event.event.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(FilmRollTheme.primaryText)
                        
                        Spacer()
                        
                        if event.status == .new {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FilmRollTheme.accent)
                        } else if event.status == .developed {
                            Text("DEVELOPED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FilmRollTheme.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FilmRollTheme.inputBackground)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Label(formatDate(event.event.eventDate), systemImage: "calendar")
                        if let _ = event.event.description {
                            Label("Event", systemImage: "mappin")
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(FilmRollTheme.accent)
                            Text("\(event.photoCount)/\(event.totalShots)")
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                            Text("\(event.participantCount) Guests")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(FilmRollTheme.inputBackground)
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(FilmRollTheme.accent)
                                .frame(width: geometry.size.width * progressValue, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(12)
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
    
    private var progressValue: CGFloat {
        guard event.totalShots > 0 else { return 0 }
        return CGFloat(event.photoCount) / CGFloat(event.totalShots)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: EventStatus
    
    var body: some View {
        HStack(spacing: 4) {
            if status == .live {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
            }
            Text(status.rawValue)
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .live: return FilmRollTheme.accent
        case .developed: return FilmRollTheme.secondaryText
        case .new: return FilmRollTheme.buttonBackground
        }
    }
}

// MARK: - Info Banner
struct InfoBanner: View {
    let icon: String
    let title: String
    let message: String
    var iconColor: Color = FilmRollTheme.accent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FilmRollTheme.primaryText)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(12)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusMedium)
    }
}
