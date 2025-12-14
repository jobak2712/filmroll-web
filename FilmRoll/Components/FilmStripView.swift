import SwiftUI

/// Film strip style gallery view with reveal animation
struct FilmStripView: View {
    let photos: [Photo]
    let isRevealing: Bool
    let onPhotoTap: (Photo, Int) -> Void
    
    @State private var revealedCount = 0
    @State private var scrollOffset: CGFloat = 0
    
    private let filmHoleSize: CGFloat = 12
    private let frameWidth: CGFloat = 280
    private let frameHeight: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 0) {
            // Film strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Leading film holes
                    filmHolesColumn
                    
                    // Photos
                    HStack(spacing: 16) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            filmFrame(photo: photo, index: index)
                                .opacity(isRevealing ? (index < revealedCount ? 1 : 0.3) : 1)
                                .scaleEffect(isRevealing ? (index < revealedCount ? 1 : 0.95) : 1)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.15),
                                    value: revealedCount
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Trailing film holes
                    filmHolesColumn
                }
                .padding(.vertical, 20)
            }
            .background(filmStripBackground)
        }
        .onAppear {
            if isRevealing {
                startRevealAnimation()
            } else {
                revealedCount = photos.count
            }
        }
    }
    
    private var filmStripBackground: some View {
        Rectangle()
            .fill(Color.black)
            .overlay(
                // Film grain texture
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.02),
                                Color.clear,
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
    
    private var filmHolesColumn: some View {
        VStack(spacing: 8) {
            ForEach(0..<8, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: filmHoleSize, height: filmHoleSize * 1.5)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func filmFrame(photo: Photo, index: Int) -> some View {
        Button(action: {
            onPhotoTap(photo, index)
        }) {
            ZStack {
                // Frame border
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: frameWidth + 16, height: frameHeight + 16)
                
                // Photo
                AsyncImage(url: URL(string: photo.storagePath)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: frameWidth, height: frameHeight)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: frameWidth, height: frameHeight)
                            .clipped()
                            .overlay(filmGrainOverlay)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: frameWidth, height: frameHeight)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(2)
                
                // Frame number
                VStack {
                    Spacer()
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        Spacer()
                    }
                    .padding(8)
                }
                .frame(width: frameWidth, height: frameHeight)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var filmGrainOverlay: some View {
        Rectangle()
            .fill(
                Color.clear
            )
            .overlay(
                // Subtle vignette
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.2)],
                    center: .center,
                    startRadius: 50,
                    endRadius: 200
                )
            )
    }
    
    private func startRevealAnimation() {
        revealedCount = 0
        
        // Reveal photos one by one
        for i in 0..<photos.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                withAnimation {
                    revealedCount = i + 1
                }
                HapticFeedback.selection()
            }
        }
    }
}

// MARK: - Film Strip Reveal Animation View
struct FilmStripRevealView: View {
    let photos: [Photo]
    let eventTitle: String
    let onComplete: () -> Void
    
    @State private var isRevealing = false
    @State private var showTitle = false
    @State private var currentPhotoIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Title
                if showTitle {
                    VStack(spacing: 8) {
                        Text("🎬")
                            .font(.system(size: 48))
                        
                        Text(eventTitle)
                            .font(.custom("PlayfairDisplay-Bold", size: 28))
                            .foregroundColor(.white)
                        
                        Text("\(photos.count) moments revealed")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Film Strip
                FilmStripView(
                    photos: photos,
                    isRevealing: isRevealing
                ) { _, _ in }
                
                // Skip Button
                Button(action: onComplete) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                }
            }
        }
        .onAppear {
            startReveal()
        }
    }
    
    private func startReveal() {
        // Show title first
        withAnimation(.easeOut(duration: 0.5)) {
            showTitle = true
        }
        
        // Start film strip reveal after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRevealing = true
        }
        
        // Complete after all photos revealed
        let totalDuration = Double(photos.count) * 0.3 + 2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            onComplete()
        }
    }
}
