import SwiftUI
import AVFoundation

struct GuestJoinView: View {
    @ObservedObject var viewModel: GuestViewModel
    @EnvironmentObject var appState: AppState
    @State private var joinCode = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .error
    @State private var showPreviewGallery = false
    @State private var showEventHistory = false
    @State private var showQRScanner = false
    @State private var scannedNewCode = false
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button, history, and logo
                HStack {
                    Button(action: {
                        appState.isGuestMode = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // My Events button
                    Button(action: {
                        showEventHistory = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text("My Events")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(FilmRollTheme.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(20)
                    }
                    
                    // Camera badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FilmRollTheme.accent)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "camera")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Event Card (if loaded)
                        if let event = viewModel.event {
                            ZStack(alignment: .bottomLeading) {
                                // Cover Image
                                if let coverUrl = event.coverImageUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusLarge)
                                                .fill(FilmRollTheme.buttonBackground)
                                                .frame(height: 200)
                                                .overlay(ProgressView().tint(.white))
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 200)
                                                .clipped()
                                                .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                                        case .failure:
                                            RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusLarge)
                                                .fill(FilmRollTheme.buttonBackground)
                                                .frame(height: 200)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 48))
                                                        .foregroundColor(.white.opacity(0.3))
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusLarge)
                                        .fill(FilmRollTheme.buttonBackground)
                                        .frame(height: 200)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 48))
                                                .foregroundColor(.white.opacity(0.3))
                                        )
                                }
                                
                                // Event Info Overlay
                                VStack(alignment: .leading, spacing: 4) {
                                    // Date Badge
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 10))
                                        Text(viewModel.formatEventDate().uppercased())
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(event.title)
                                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.formatRevealInfo())
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(20)
                            }
                            .padding(.horizontal, 24)
                            
                            // Event Info
                            HStack(spacing: 16) {
                                VStack {
                                    Text("\(event.shotLimitPerGuest)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    // L03: Singular/plural - using "photos" for clarity
                                    Text(event.shotLimitPerGuest == 1 ? "photo per guest" : "photos per guest")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: event.revealMode == .instant ? "eye" : "clock")
                                            .font(.system(size: 14))
                                        Text(event.revealMode == .instant ? "Instant" : "Delayed")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    Text(event.revealMode == .instant ? "see photos now" : "photos hidden until reveal")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // Join Code Input
                            VStack(spacing: 16) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 64))
                                    .foregroundColor(FilmRollTheme.accent)
                                    .padding(.top, 40)
                                
                                Text("Join an Event")
                                    .font(.custom("PlayfairDisplay-Bold", size: 28))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                
                                Text("Enter the event code to join and start capturing moments")
                                    .font(.system(size: 14))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                // Scan QR Button
                                Button(action: {
                                    showQRScanner = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 20))
                                        Text("Scan QR Code")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(FilmRollTheme.accent)
                                    .cornerRadius(28)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                
                                // OR divider
                                HStack {
                                    Rectangle()
                                        .fill(FilmRollTheme.divider)
                                        .frame(height: 1)
                                    Text("or enter code")
                                        .font(.system(size: 13))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                    Rectangle()
                                        .fill(FilmRollTheme.divider)
                                        .frame(height: 1)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                
                                FilmTextField(
                                    label: "Event Code",
                                    placeholder: "Enter 6-character code",
                                    text: $joinCode
                                )
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 24)
                                
                                // Test codes hint (only in mock mode)
                                if viewModel.useMockData {
                                    VStack(spacing: 4) {
                                        Text("Test Event Codes:")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(FilmRollTheme.secondaryText)
                                        Text("SARAH30 • BEACH24 • EMMAJAMES • HOLIDAY24")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(FilmRollTheme.accent)
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                PrimaryButton(
                                    "Find Event",
                                    icon: "magnifyingglass",
                                    isLoading: viewModel.isLoading
                                ) {
                                    guard !joinCode.trimmingCharacters(in: .whitespaces).isEmpty else {
                                        toastMessage = "Please enter an event code"
                                        toastType = .error
                                        showToast = true
                                        return
                                    }
                                    
                                    Task {
                                        await viewModel.loadEvent(joinCode: joinCode.trimmingCharacters(in: .whitespaces))
                                        if viewModel.errorMessage != nil {
                                            toastMessage = viewModel.errorMessage!
                                            toastType = .error
                                            showToast = true
                                            viewModel.clearMessages()
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Join Form (if event loaded)
                        if viewModel.event != nil {
                            VStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("Join the Event")
                                        .font(.custom("PlayfairDisplay-SemiBold", size: 24))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Text("Enter your name to capture and share moments")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                
                                FilmTextField(
                                    label: "Your Name (Optional)",
                                    placeholder: "Enter your name",
                                    text: $viewModel.guestName,
                                    icon: "person",
                                    helperText: "Your photos will be tagged with this name"
                                )
                                
                                VStack(spacing: 12) {
                                    PrimaryButton(
                                        "Join Event",
                                        icon: "camera",
                                        isLoading: viewModel.isLoading
                                    ) {
                                        Task {
                                            let success = await viewModel.joinEvent()
                                            if !success, let error = viewModel.errorMessage {
                                                toastMessage = error
                                                toastType = .error
                                                showToast = true
                                                viewModel.clearMessages()
                                            } else if success,
                                                      let event = viewModel.event,
                                                      let participant = viewModel.participant {
                                                // C04: Safe unwrap instead of force unwrap
                                                appState.currentGuestSession = GuestSession(
                                                    eventId: event.id,
                                                    participantId: participant.id,
                                                    guestName: viewModel.guestName.isEmpty ? nil : viewModel.guestName,
                                                    shotLimit: viewModel.shotLimit,
                                                    shotsTaken: 0
                                                )
                                                // Save to event history for easy access later
                                                saveEventToHistory()
                                                // Show success feedback with explanation
                                                if viewModel.isRevealed {
                                                    toastMessage = "Welcome! View the gallery 📸"
                                                } else {
                                                    toastMessage = "You're in! Photos will be revealed later 🎬"
                                                }
                                                toastType = .success
                                                showToast = true
                                            }
                                        }
                                    }
                                    
                                    SecondaryButton("Preview Gallery", icon: "eye") {
                                        // View only mode - just preview if revealed (no joining)
                                        if viewModel.isRevealed {
                                            Task {
                                                await viewModel.loadPhotos()
                                                showPreviewGallery = true
                                            }
                                        } else {
                                            toastMessage = "Photos will be available after the reveal"
                                            toastType = .info
                                            showToast = true
                                        }
                                    }
                                    
                                    // Different event button
                                    Button(action: {
                                        viewModel.event = nil
                                        joinCode = ""
                                    }) {
                                        Text("Join a different event")
                                            .font(.system(size: 14))
                                            .foregroundColor(FilmRollTheme.secondaryText)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .sheet(isPresented: $showPreviewGallery) {
            NavigationStack {
                GuestGalleryPreviewView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showEventHistory) {
            GuestEventHistoryView { history in
                // Load event from history
                joinCode = history.joinCode
                Task {
                    await viewModel.loadEvent(joinCode: history.joinCode)
                    if viewModel.event != nil {
                        // Restore participant info
                        viewModel.guestName = history.guestName ?? ""
                    }
                }
            }
        }
        .sheet(isPresented: $showQRScanner, onDismiss: {
            // Load event after scanner is dismissed only if we scanned a new code
            if scannedNewCode && !joinCode.isEmpty {
                scannedNewCode = false
                Task {
                    await viewModel.loadEvent(joinCode: joinCode)
                    if viewModel.errorMessage != nil {
                        toastMessage = viewModel.errorMessage!
                        toastType = .error
                        showToast = true
                        viewModel.clearMessages()
                    }
                }
            }
        }) {
            QRScannerView { scannedCode in
                // Extract join code from URL or use directly
                let code = extractJoinCode(from: scannedCode)
                joinCode = code
                scannedNewCode = true
                // Dismiss the scanner - event will load in onDismiss
                showQRScanner = false
            }
        }
    }
    
    // Extract join code from URL like:
    // - "https://filmroll.app/join/ABC123"
    // - "https://xxx.supabase.co/functions/v1/joinPage/ABC123"
    // - or just "ABC123"
    private func extractJoinCode(from string: String) -> String {
        // Handle /joinPage/ URLs (Supabase functions)
        if string.contains("/joinPage/") {
            return String(string.split(separator: "/").last ?? "")
        }
        // Handle /join/ URLs (custom domain)
        if string.contains("/join/") {
            return String(string.split(separator: "/").last ?? "")
        }
        // If it's just the code, return as-is
        return string
    }
    
    // Helper to save event to history
    private func saveEventToHistory() {
        guard let event = viewModel.event, let participant = viewModel.participant else { return }
        
        let history = GuestEventHistory(
            id: UUID().uuidString,
            eventId: event.id,
            eventTitle: event.title,
            eventDate: event.eventDate,
            joinCode: event.joinCode,
            participantId: participant.id,
            guestName: viewModel.guestName.isEmpty ? nil : viewModel.guestName,
            shotsTaken: viewModel.shotsTaken,
            isRevealed: event.isRevealed,
            revealTime: event.revealTime,
            joinedAt: Date(),
            coverImageUrl: event.coverImageUrl
        )
        GuestEventHistory.save(history)
    }
}

// MARK: - Preview Gallery (View Only)
struct GuestGalleryPreviewView: View {
    @ObservedObject var viewModel: GuestViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Info Banner
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                        .font(.system(size: 14))
                    Text("Preview Mode - Join to save photos")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(FilmRollTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(FilmRollTheme.accentLight)
                
                // Photo Grid
                if viewModel.photos.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No photos yet",
                        message: "Photos will appear here once they're captured"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        PhotoGrid(
                            photos: viewModel.photos,
                            columns: 3
                        ) { _, _ in
                            // No action in preview mode
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("Gallery Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(FilmRollTheme.primaryText)
            }
        }
    }
}
