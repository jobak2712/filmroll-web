import SwiftUI

struct GuestGalleryView: View {
    @ObservedObject var viewModel: GuestViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoIndex: Int = 0
    @State private var showPhotoViewer = false
    @State private var showMoreMenu = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showFindMyPhotos = false
    @State private var showReelGenerator = false
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("REVEALED PHOTOS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FilmRollTheme.primaryText)
                        
                        Text("All photos are now visible")
                            .font(.system(size: 13))
                            .foregroundColor(FilmRollTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.photos.count) photos")
                        .font(.system(size: 14))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // Premium Feature Buttons
                if !viewModel.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Find My Photos Button
                            Button(action: { showFindMyPhotos = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 14))
                                    Text("Find My Photos")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(FilmRollTheme.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(FilmRollTheme.accentLight)
                                .cornerRadius(20)
                            }
                            
                            // Create Reel Button
                            Button(action: { showReelGenerator = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "film")
                                        .font(.system(size: 14))
                                    Text("Create Reel")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(FilmRollTheme.cardBackground)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 12)
                }
                
                // Photo Grid
                if viewModel.isLoading && viewModel.photos.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.photos.isEmpty {
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
                        ) { photo, index in
                            selectedPhotoIndex = index
                            showPhotoViewer = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Actions
                if !viewModel.photos.isEmpty {
                    VStack(spacing: 12) {
                        if !viewModel.favoritePhotoIds.isEmpty {
                            Text("\(viewModel.favoritePhotoIds.count) favorites selected")
                                .font(.system(size: 12))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        
                        PrimaryButton(
                            viewModel.favoritePhotoIds.isEmpty ? "Save All Photos" : "Save Favorites (\(viewModel.favoritePhotoIds.count))",
                            icon: "heart",
                            isLoading: viewModel.isSavingFavorites
                        ) {
                            Task {
                                if viewModel.favoritePhotoIds.isEmpty {
                                    await viewModel.saveAllPhotosToCameraRoll()
                                } else {
                                    await viewModel.saveFavoritesToCameraRoll()
                                }
                                showToastMessage()
                            }
                        }
                        
                        // Back to Camera (if can still take photos)
                        if viewModel.canTakePhoto {
                            SecondaryButton("Back to Camera (\(viewModel.shotsRemaining) shots left)", icon: "camera") {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            
            // Download Progress Overlay
            if viewModel.isSavingFavorites, let progress = viewModel.saveProgress {
                LoadingOverlay(message: "Saving \(progress.current) of \(progress.total)...")
            }
        }
        .navigationTitle("Guest Gallery")
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
            GuestPhotoViewerView(
                photos: viewModel.photos,
                initialIndex: selectedPhotoIndex,
                viewModel: viewModel
            )
        }
        .confirmationDialog("Options", isPresented: $showMoreMenu) {
            Button("Save All to Camera Roll") {
                Task {
                    await viewModel.saveAllPhotosToCameraRoll()
                    showToastMessage()
                }
            }
            Button("Share Gallery") {
                if let event = viewModel.event {
                    let url = "https://filmroll.app/join/\(event.joinCode)"
                    UIPasteboard.general.string = url
                    toastMessage = "Gallery link copied!"
                    toastType = .success
                    showToast = true
                }
            }
            Button("Leave Event", role: .destructive) {
                viewModel.leaveEvent()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .sheet(isPresented: $showFindMyPhotos) {
            FindMyPhotosView(
                photos: viewModel.photos,
                loadImage: loadImageForPhoto
            )
        }
        .sheet(isPresented: $showReelGenerator) {
            if let event = viewModel.event {
                ReelPreviewView(
                    photos: viewModel.photos,
                    eventTitle: event.title,
                    eventDate: event.eventDate,
                    loadImage: loadImageForPhoto
                )
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
    }
    
    private func loadImageForPhoto(_ photo: Photo) async -> UIImage? {
        guard let url = URL(string: photo.storagePath) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    private func showToastMessage() {
        if let success = viewModel.successMessage {
            toastMessage = success
            toastType = .success
            showToast = true
            viewModel.clearMessages()
        } else if let error = viewModel.errorMessage {
            toastMessage = error
            toastType = .error
            showToast = true
            viewModel.clearMessages()
        }
    }
}
