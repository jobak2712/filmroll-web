import SwiftUI

struct EventDashboardView: View {
    let eventId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventViewModel = EventViewModel()
    @State private var showSettings = false
    @State private var showGallery = false
    @State private var showRevealConfirmation = false
    @State private var showEndEventConfirmation = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            if let event = eventViewModel.currentEvent {
                ScrollView {
                    VStack(spacing: 24) {
                        // Event Title
                        VStack(spacing: 4) {
                            Text(event.title)
                                .font(.custom("PlayfairDisplay-Bold", size: 28))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text(formatEventDateTime(event))
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        .padding(.top, 8)
                        
                        // QR Code Card
                        QRCard(
                            joinCode: event.joinCode,
                            joinUrl: eventViewModel.getJoinUrl(for: event)
                        ) {
                            eventViewModel.copyJoinLink()
                            toastMessage = "Link copied to clipboard!"
                            toastType = .success
                            showToast = true
                        }
                        .padding(.horizontal, 24)
                        
                        // Stats Row
                        HStack(spacing: 12) {
                            StatsCard(
                                icon: "person.2.fill",
                                value: "\(eventViewModel.participants.count)",
                                label: "PARTICIPANTS"
                            )
                            
                            StatsCard(
                                icon: "camera.fill",
                                value: "\(eventViewModel.photos.count)/\(totalShots(event))",
                                label: "SHOTS TAKEN"
                            )
                            
                            StatsCard(
                                icon: event.isRevealed ? "eye.fill" : "clock.fill",
                                value: event.isRevealed ? "Live" : eventViewModel.timeUntilReveal(for: event),
                                label: event.isRevealed ? "REVEALED" : "UNTIL REVEAL"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Participants Section
                        if !eventViewModel.participants.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Participants")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(eventViewModel.participants.count) joined")
                                        .font(.system(size: 13))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(eventViewModel.participants, id: \.id) { participant in
                                        ParticipantRow(participant: participant)
                                    }
                                }
                            }
                            .padding(16)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            PrimaryButton("Edit Settings", icon: "gearshape") {
                                showSettings = true
                            }
                            
                            if !event.isRevealed {
                                AccentButton("Reveal Early", icon: "eye") {
                                    showRevealConfirmation = true
                                }
                            }
                            
                            DestructiveButton("End Event", icon: "xmark.circle") {
                                showEndEventConfirmation = true
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Share Button
                        Button(action: {
                            eventViewModel.shareEventLink()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Event")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FilmRollTheme.accent)
                        }
                        
                        // Photos Preview
                        if !eventViewModel.photos.isEmpty {
                            VStack(spacing: 12) {
                                // Host preview banner (before reveal)
                                if !event.isRevealed {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eye.fill")
                                            .font(.system(size: 12))
                                        Text("Host Preview - Only you can see these photos")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(FilmRollTheme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(FilmRollTheme.accent.opacity(0.15))
                                    .cornerRadius(8)
                                }
                                
                                PhotoPreviewGrid(
                                    photos: eventViewModel.photos,
                                    totalCount: eventViewModel.photos.count
                                ) {
                                    showGallery = true
                                }
                                
                                // View All Photos button
                                Button(action: { showGallery = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.stack")
                                            .font(.system(size: 14))
                                        Text("View All \(eventViewModel.photos.count) Photos")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(FilmRollTheme.accent)
                                    .cornerRadius(25)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // Empty state for photos
                            VStack(spacing: 12) {
                                Text("Photos Captured")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 32))
                                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.5))
                                    
                                    Text("No photos yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                    
                                    Text("Share the QR code to invite guests")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.7))
                                }
                                .padding(.vertical, 24)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 16)
                }
            } else if eventViewModel.isLoading {
                ProgressView()
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Event not found",
                    message: "This event may have been deleted",
                    actionTitle: "Go Back"
                ) {
                    dismiss()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            if let event = eventViewModel.currentEvent {
                EventSettingsView(event: event)
            }
        }
        .navigationDestination(isPresented: $showGallery) {
            if let event = eventViewModel.currentEvent {
                HostGalleryView(
                    eventId: event.id,
                    isRevealed: event.isRevealed
                )
            }
        }
        .alert("Reveal Photos", isPresented: $showRevealConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reveal Now") {
                Task {
                    await eventViewModel.revealEvent()
                    showToastMessage()
                }
            }
        } message: {
            Text("Are you sure you want to reveal all photos now? All participants will be able to see the gallery immediately.")
        }
        .alert("End Event", isPresented: $showEndEventConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End Event", role: .destructive) {
                Task {
                    await eventViewModel.endEvent()
                    toastMessage = "Event ended. No new participants or photos allowed."
                    toastType = .info
                    showToast = true
                }
            }
        } message: {
            Text("This will lock the event and prevent new participants from joining or taking photos. You can still reveal photos later.")
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .task {
            await eventViewModel.loadEvent(id: eventId)
        }
        .refreshable {
            await eventViewModel.loadEvent(id: eventId)
        }
    }
    
    private func formatEventDateTime(_ event: Event) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d • h:mm a"
        return formatter.string(from: event.eventDate)
    }
    
    private func totalShots(_ event: Event) -> Int {
        max(1, event.shotLimitPerGuest * max(1, eventViewModel.participants.count))
    }
    
    private func showToastMessage() {
        if let success = eventViewModel.successMessage {
            toastMessage = success
            toastType = .success
            showToast = true
            eventViewModel.clearMessages()
        } else if let error = eventViewModel.errorMessage {
            toastMessage = error
            toastType = .error
            showToast = true
            eventViewModel.clearMessages()
        }
    }
}

// MARK: - Participant Row
struct ParticipantRow: View {
    let participant: Participant
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(FilmRollTheme.accent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FilmRollTheme.accent)
                )
            
            // Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.guestName ?? "Anonymous Guest")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text("Joined \(timeAgo)")
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            Spacer()
            
            // Photos taken
            HStack(spacing: 4) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 11))
                Text("\(participant.shotsTaken)")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(FilmRollTheme.secondaryText)
        }
        .padding(.vertical, 8)
    }
    
    private var initials: String {
        guard let name = participant.guestName, !name.isEmpty else {
            return "?"
        }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: participant.joinedAt, relativeTo: Date())
    }
}
