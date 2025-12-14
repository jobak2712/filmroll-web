import SwiftUI

struct HostPhotoViewerView: View {
    let photos: [Photo]
    let initialIndex: Int
    let onDelete: (String) -> Void
    let onDownload: (Photo) -> Void
    let onShare: (Photo) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showDeleteConfirmation = false
    @State private var showMoreMenu = false
    @State private var isDownloading = false
    
    init(photos: [Photo], initialIndex: Int, onDelete: @escaping (String) -> Void, onDownload: @escaping (Photo) -> Void, onShare: @escaping (Photo) -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onDelete = onDelete
        self.onDownload = onDownload
        self.onShare = onShare
        _currentIndex = State(initialValue: initialIndex)
    }
    
    private var currentPhoto: Photo? {
        guard currentIndex >= 0 && currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Photo")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(currentIndex + 1) of \(photos.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { showMoreMenu = true }) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Photo
                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        ZStack(alignment: .topTrailing) {
                            // Photo image (using AsyncImage for URL loading)
                            AsyncImage(url: URL(string: photo.storagePath)) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        )
                                case .success(let image):
                                    ZStack(alignment: .bottom) {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                                        
                                        // Caption overlay
                                        if let caption = photo.caption, !caption.isEmpty {
                                            Text(caption)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(12)
                                                .background(
                                                    LinearGradient(
                                                        colors: [Color.black.opacity(0.7), Color.clear],
                                                        startPoint: .bottom,
                                                        endPoint: .top
                                                    )
                                                )
                                                .cornerRadius(FilmRollTheme.cornerRadiusMedium, corners: [.bottomLeft, .bottomRight])
                                        }
                                    }
                                case .failure:
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 48))
                                                .foregroundColor(.white.opacity(0.3))
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            // Top badges (file size + filter)
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(formatFileSize(photo.fileSize))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                
                                if let filter = photo.filterApplied {
                                    HStack(spacing: 4) {
                                        Image(systemName: "camera.filters")
                                            .font(.system(size: 10))
                                        Text(filter)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(FilmRollTheme.accent.opacity(0.9))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 24)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
                
                // Reactions display
                if let photo = currentPhoto, let reactions = photo.reactions, !reactions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(reactions.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { emoji, count in
                            HStack(spacing: 4) {
                                Text(emoji)
                                    .font(.system(size: 16))
                                Text("\(count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.top, 12)
                }
                
                // Swipe hint
                Text("Swipe to navigate between photos")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 12)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Download Button
                        Button(action: {
                            guard let photo = currentPhoto else { return }
                            isDownloading = true
                            onDownload(photo)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isDownloading = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isDownloading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: FilmRollTheme.primaryText))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down")
                                }
                                Text("Download")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(FilmRollTheme.cornerRadiusPill)
                        }
                        .disabled(isDownloading)
                        
                        // Share Button
                        Button(action: {
                            guard let photo = currentPhoto else { return }
                            onShare(photo)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .frame(width: 52, height: 52)
                                .background(Color.white)
                                .cornerRadius(FilmRollTheme.cornerRadiusPill)
                        }
                    }
                    
                    // Delete Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Photo")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(FilmRollTheme.destructive)
                        .cornerRadius(FilmRollTheme.cornerRadiusPill)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let photo = currentPhoto {
                    onDelete(photo.id)
                    if photos.count <= 1 {
                        dismiss()
                    } else if currentIndex >= photos.count - 1 {
                        currentIndex = max(0, currentIndex - 1)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
        .confirmationDialog("Options", isPresented: $showMoreMenu) {
            Button("Download") {
                guard let photo = currentPhoto else { return }
                onDownload(photo)
            }
            Button("Share") {
                guard let photo = currentPhoto else { return }
                onShare(photo)
            }
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
    }
}
