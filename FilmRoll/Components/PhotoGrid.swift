import SwiftUI
import Combine

// MARK: - Photo Grid
struct PhotoGrid: View {
    let photos: [Photo]
    let columns: Int
    let onPhotoTap: (Photo, Int) -> Void
    var showLockOverlay: Bool = false
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                PhotoGridItem(
                    photo: photo,
                    showLock: showLockOverlay
                ) {
                    onPhotoTap(photo, index)
                }
            }
        }
    }
}

// MARK: - Photo Grid Item
struct PhotoGridItem: View {
    let photo: Photo
    var showLock: Bool = false
    let onTap: () -> Void
    
    private var hasCaption: Bool {
        photo.caption != nil && !photo.caption!.isEmpty
    }
    
    private var hasReactions: Bool {
        photo.reactions != nil && !photo.reactions!.isEmpty
    }
    
    private var totalReactions: Int {
        photo.reactions?.values.reduce(0, +) ?? 0
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Actual image with AsyncImage - use url from edge function, fallback to storagePath
                AsyncImage(url: URL(string: photo.url ?? photo.storagePath)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                            .fill(FilmRollTheme.inputBackground)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: FilmRollTheme.secondaryText))
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                    case .failure:
                        RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                            .fill(FilmRollTheme.inputBackground)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(FilmRollTheme.secondaryText.opacity(0.5))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                // Indicators overlay
                if hasCaption || hasReactions {
                    HStack(spacing: 4) {
                        if hasCaption {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        
                        if hasReactions {
                            HStack(spacing: 2) {
                                Text("❤️")
                                    .font(.system(size: 10))
                                Text("\(totalReactions)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(6)
                }
                
                if showLock {
                    // Blur overlay
                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                        .fill(Color.black.opacity(0.5))
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Photo Preview Grid (Dashboard)
struct PhotoPreviewGrid: View {
    let photos: [Photo]
    let totalCount: Int
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos Captured")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Spacer()
                
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("\(totalCount) shots")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
            
            let displayPhotos = Array(photos.prefix(4))
            let remaining = totalCount - displayPhotos.count
            
            HStack(spacing: 8) {
                ForEach(displayPhotos) { photo in
                    AsyncImage(url: URL(string: photo.url ?? photo.storagePath)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusSmall)
                                .fill(FilmRollTheme.inputBackground)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .cornerRadius(FilmRollTheme.cornerRadiusSmall)
                        case .failure:
                            RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusSmall)
                                .fill(FilmRollTheme.inputBackground)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 16))
                                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                
                if remaining > 0 {
                    Button(action: onViewAll) {
                        RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusSmall)
                            .fill(FilmRollTheme.primaryText)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 2) {
                                    Text("+\(remaining)")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("more")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.white)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Countdown Timer View
struct CountdownView: View {
    let targetDate: Date
    @State private var timeRemaining: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            TimeBox(value: hours, label: "HOURS")
            Text(":")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(FilmRollTheme.secondaryText)
            TimeBox(value: minutes, label: "MINUTES")
            Text(":")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(FilmRollTheme.secondaryText)
            TimeBox(value: seconds, label: "SECONDS")
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .onAppear {
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, targetDate.timeIntervalSinceNow)
    }
    
    private var hours: Int {
        Int(timeRemaining) / 3600
    }
    
    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }
    
    private var seconds: Int {
        Int(timeRemaining) % 60
    }
}

struct TimeBox: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(FilmRollTheme.primaryText)
                .frame(width: 60, height: 50)
                .background(FilmRollTheme.inputBackground)
                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(FilmRollTheme.secondaryText)
        }
    }
}
