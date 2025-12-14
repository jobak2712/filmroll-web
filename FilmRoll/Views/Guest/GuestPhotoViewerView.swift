import SwiftUI

struct GuestPhotoViewerView: View {
    let photos: [Photo]
    let initialIndex: Int
    @ObservedObject var viewModel: GuestViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showInfo = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var isDownloading = false
    
    init(photos: [Photo], initialIndex: Int, viewModel: GuestViewModel) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.viewModel = viewModel
        _currentIndex = State(initialValue: initialIndex)
    }
    
    private var currentPhoto: Photo? {
        guard currentIndex >= 0 && currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }
    
    private var isFavorite: Bool {
        guard let photo = currentPhoto else { return false }
        return viewModel.isFavorite(photoId: photo.id)
    }
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(FilmRollTheme.inputBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Photo")
                            .font(.system(size: 14))
                            .foregroundColor(FilmRollTheme.secondaryText)
                        Text("\(currentIndex + 1) of \(photos.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: { showInfo = true }) {
                        Circle()
                            .fill(FilmRollTheme.inputBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
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
                            // Actual image with AsyncImage
                            AsyncImage(url: URL(string: photo.storagePath)) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusLarge)
                                        .fill(FilmRollTheme.inputBackground)
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: FilmRollTheme.secondaryText))
                                        )
                                case .success(let image):
                                    ZStack(alignment: .bottom) {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                                        
                                        // Caption overlay
                                        if let caption = photo.caption, !caption.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(caption)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.black.opacity(0.7), Color.clear],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            .cornerRadius(FilmRollTheme.cornerRadiusLarge, corners: [.bottomLeft, .bottomRight])
                                        }
                                    }
                                case .failure:
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusLarge)
                                        .fill(FilmRollTheme.inputBackground)
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 48))
                                                .foregroundColor(FilmRollTheme.secondaryText.opacity(0.3))
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            // Top badges (file size + filter)
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(formatFileSize(photo.fileSize))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(16)
                                
                                if let filter = photo.filterApplied {
                                    HStack(spacing: 4) {
                                        Image(systemName: "camera.filters")
                                            .font(.system(size: 10))
                                        Text(filter)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(FilmRollTheme.accent.opacity(0.9))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 24)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 350)
                
                // Reactions Bar
                if let photo = currentPhoto {
                    PhotoReactionBar(photo: photo, onReactionChanged: { reactions in
                        // Get the latest emoji added
                        if let latestEmoji = reactions.max(by: { $0.value < $1.value })?.key {
                            viewModel.addReaction(to: photo.id, emoji: latestEmoji)
                        }
                    })
                    .padding(.top, 12)
                }
                
                // Navigation Controls
                HStack(spacing: 16) {
                    Button(action: {
                        if currentIndex > 0 {
                            withAnimation {
                                currentIndex -= 1
                            }
                        }
                    }) {
                        Circle()
                            .fill(FilmRollTheme.inputBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                            )
                    }
                    .opacity(currentIndex > 0 ? 1 : 0.3)
                    .disabled(currentIndex == 0)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 14))
                        Text("Swipe to navigate")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(FilmRollTheme.secondaryText)
                    
                    Button(action: {
                        if currentIndex < photos.count - 1 {
                            withAnimation {
                                currentIndex += 1
                            }
                        }
                    }) {
                        Circle()
                            .fill(FilmRollTheme.inputBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                            )
                    }
                    .opacity(currentIndex < photos.count - 1 ? 1 : 0.3)
                    .disabled(currentIndex == photos.count - 1)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    // Download Button
                    Button(action: {
                        guard let photo = currentPhoto else { return }
                        isDownloading = true
                        Task {
                            await viewModel.downloadPhoto(photo)
                            isDownloading = false
                            showToastMessage()
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
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(FilmRollTheme.cornerRadiusPill)
                        .overlay(
                            RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                                .stroke(FilmRollTheme.divider, lineWidth: 1)
                        )
                    }
                    .disabled(isDownloading)
                    
                    // Share Button
                    Button(action: {
                        guard let photo = currentPhoto else { return }
                        Task {
                            await viewModel.sharePhoto(photo)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(width: 52, height: 52)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusPill)
                            .overlay(
                                RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                                    .stroke(FilmRollTheme.divider, lineWidth: 1)
                            )
                    }
                    
                    // Favorite Button
                    Button(action: {
                        guard let photo = currentPhoto else { return }
                        viewModel.toggleFavorite(photoId: photo.id)
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isFavorite ? .white : FilmRollTheme.primaryText)
                            .frame(width: 52, height: 52)
                            .background(isFavorite ? FilmRollTheme.primaryText : FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusPill)
                            .overlay(
                                RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                                    .stroke(isFavorite ? Color.clear : FilmRollTheme.divider, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showInfo) {
            PhotoInfoSheet(photo: currentPhoto)
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
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

// MARK: - Photo Info Sheet
struct PhotoInfoSheet: View {
    let photo: Photo?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let photo = photo {
                    InfoRow(label: "Captured", value: formatDate(photo.capturedAt))
                    InfoRow(label: "File Size", value: formatFileSize(photo.fileSize))
                    InfoRow(label: "Photo ID", value: String(photo.id.prefix(8)))
                    
                    if let filter = photo.filterApplied {
                        InfoRow(label: "Filter", value: filter)
                    }
                    
                    if let caption = photo.caption, !caption.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Caption")
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                            Text(caption)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                        }
                    }
                    
                    if let reactions = photo.reactions, !reactions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reactions")
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                            HStack(spacing: 8) {
                                ForEach(reactions.sorted(by: { $0.value > $1.value }), id: \.key) { emoji, count in
                                    HStack(spacing: 4) {
                                        Text(emoji)
                                        Text("\(count)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(FilmRollTheme.primaryText)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(FilmRollTheme.inputBackground)
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Photo Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.2f MB", mb)
    }
}

// MARK: - Photo Reaction Bar
struct PhotoReactionBar: View {
    let photo: Photo
    let onReactionChanged: ([String: Int]) -> Void
    @State private var localReactions: [String: Int]
    @State private var showPicker = false
    
    init(photo: Photo, onReactionChanged: @escaping ([String: Int]) -> Void) {
        self.photo = photo
        self.onReactionChanged = onReactionChanged
        _localReactions = State(initialValue: photo.reactions ?? [:])
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Show existing reactions
            ForEach(sortedReactions.prefix(4), id: \.key) { emoji, count in
                Button(action: { addReaction(emoji) }) {
                    HStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 16))
                        Text("\(count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FilmRollTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                }
            }
            
            // Add reaction button
            Button(action: { showPicker = true }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(FilmRollTheme.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
        .sheet(isPresented: $showPicker) {
            ReactionPickerSheet(onSelect: { reaction in
                addReaction(reaction.rawValue)
                showPicker = false
            })
            .presentationDetents([.height(200)])
        }
    }
    
    private var sortedReactions: [(key: String, value: Int)] {
        localReactions.sorted { $0.value > $1.value }
    }
    
    private func addReaction(_ emoji: String) {
        localReactions[emoji, default: 0] += 1
        onReactionChanged(localReactions)
        HapticFeedback.light()
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(FilmRollTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
        }
    }
}
