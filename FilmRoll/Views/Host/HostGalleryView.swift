import SwiftUI

struct HostGalleryView: View {
    let eventId: String
    let isRevealed: Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventViewModel = EventViewModel()
    @State private var selectedPhotoIndex: Int = 0
    @State private var showPhotoViewer = false
    @State private var showMoreMenu = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showReelGenerator = false
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRevealed ? "EVENT PHOTOS" : "HOST PREVIEW")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isRevealed ? FilmRollTheme.primaryText : FilmRollTheme.accent)
                        
                        if !isRevealed {
                            Text("Only visible to you until reveal")
                                .font(.system(size: 13))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(eventViewModel.photos.count) photos")
                        .font(.system(size: 14))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // Photo Grid
                if eventViewModel.isLoading && eventViewModel.photos.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if eventViewModel.photos.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No photos yet",
                        message: "Photos will appear here as guests capture them"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        PhotoGrid(
                            photos: eventViewModel.photos,
                            columns: 3
                        ) { photo, index in
                            selectedPhotoIndex = index
                            showPhotoViewer = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Banner (Before Reveal)
                if !isRevealed && !eventViewModel.photos.isEmpty {
                    InfoBanner(
                        icon: "lock.fill",
                        title: "Host Privacy",
                        message: "These photos remain private until you choose to reveal them. Participants cannot see photos until the event reveal time.",
                        iconColor: FilmRollTheme.accent
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                
                // Action Buttons
                if !eventViewModel.photos.isEmpty {
                    VStack(spacing: 12) {
                        // Create Reel Button
                        Button(action: { showReelGenerator = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "film")
                                    .font(.system(size: 16))
                                Text("Create Event Reel")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                        
                        // Download Button
                        PrimaryButton(
                            "Download All Photos",
                            icon: "arrow.down",
                            isLoading: eventViewModel.isDownloading
                        ) {
                            Task {
                                await eventViewModel.downloadAllPhotos()
                                showToastMessage()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            
            // Download Progress Overlay
            if eventViewModel.isDownloading, let progress = eventViewModel.downloadProgress {
                LoadingOverlay(message: "Downloading \(progress.current) of \(progress.total)...")
            }
        }
        .navigationTitle(isRevealed ? "Gallery" : "Host Photos")
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showMoreMenu = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            HostPhotoViewerView(
                photos: eventViewModel.photos,
                initialIndex: selectedPhotoIndex,
                onDelete: { photoId in
                    Task {
                        await eventViewModel.deletePhoto(id: photoId)
                    }
                },
                onDownload: { photo in
                    Task {
                        await eventViewModel.downloadPhoto(photo)
                        showToastMessage()
                    }
                },
                onShare: { photo in
                    Task {
                        await eventViewModel.sharePhoto(photo)
                    }
                }
            )
        }
        .confirmationDialog("Options", isPresented: $showMoreMenu) {
            Button("Download All") {
                Task {
                    await eventViewModel.downloadAllPhotos()
                    showToastMessage()
                }
            }
            Button("Share Gallery") {
                eventViewModel.shareEventLink()
            }
            Button("Refresh") {
                Task {
                    await eventViewModel.refreshPhotos()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .sheet(isPresented: $showReelGenerator) {
            if let event = eventViewModel.currentEvent {
                ReelPreviewView(
                    photos: eventViewModel.photos,
                    eventTitle: event.title,
                    eventDate: event.eventDate,
                    loadImage: loadImageForPhoto
                )
            }
        }
        .task {
            await eventViewModel.loadEvent(id: eventId)
        }
        .refreshable {
            await eventViewModel.refreshPhotos()
        }
    }
    
    private func loadImageForPhoto(_ photo: Photo) async -> UIImage? {
        // Use the signed URL from edge function, or fetch one if not available
        let urlString = photo.url ?? photo.storagePath
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
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
