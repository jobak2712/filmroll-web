import SwiftUI
import AVKit

struct ReelPreviewView: View {
    let photos: [Photo]
    let eventTitle: String
    let eventDate: Date
    let loadImage: (Photo) async -> UIImage?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reelService = ReelGeneratorService()
    @State private var player: AVPlayer?
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Event Reel")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if reelService.generatedVideoURL != nil {
                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if reelService.isGenerating {
                    // Generating View
                    generatingView
                } else if let videoURL = reelService.generatedVideoURL {
                    // Video Player
                    videoPlayerView(url: videoURL)
                } else {
                    // Initial View
                    initialView
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = reelService.generatedVideoURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(FilmRollTheme.accent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "film")
                    .font(.system(size: 48))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            VStack(spacing: 12) {
                Text("Create Event Reel")
                    .font(.custom("PlayfairDisplay-Bold", size: 28))
                    .foregroundColor(.white)
                
                Text("Generate a \(min(photos.count, 15) * 2)-second highlight video with film grain effects, timestamps, and smooth transitions.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Preview thumbnails
            HStack(spacing: -20) {
                ForEach(Array(photos.prefix(5).enumerated()), id: \.element.id) { index, photo in
                    AsyncImage(url: URL(string: photo.thumbnailPath ?? photo.storagePath)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .zIndex(Double(5 - index))
                }
                
                if photos.count > 5 {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Text("+\(photos.count - 5)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
            
            // Generate Button
            Button(action: generateReel) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16))
                    Text("Generate Reel")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FilmRollTheme.accent)
                .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private var generatingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .stroke(FilmRollTheme.accent.opacity(0.3), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(reelService.progress))
                    .stroke(FilmRollTheme.accent, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: reelService.progress)
                
                Image(systemName: "film")
                    .font(.system(size: 36))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            VStack(spacing: 12) {
                Text("Creating Your Reel...")
                    .font(.custom("PlayfairDisplay-Bold", size: 24))
                    .foregroundColor(.white)
                
                Text(progressMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("\(Int(reelService.progress * 100))%")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(FilmRollTheme.accent)
            
            Spacer()
        }
    }
    
    private func videoPlayerView(url: URL) -> some View {
        VStack(spacing: 24) {
            // Video Player
            VideoPlayer(player: player)
                .aspectRatio(9/16, contentMode: .fit)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .onAppear {
                    player = AVPlayer(url: url)
                    player?.play()
                    
                    // Loop video
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: player?.currentItem,
                        queue: .main
                    ) { _ in
                        player?.seek(to: .zero)
                        player?.play()
                    }
                }
            
            // Action Buttons
            HStack(spacing: 16) {
                // Save to Camera Roll
                Button(action: saveToPhotos) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                        Text("Save")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(24)
                }
                
                // Share
                Button(action: { showShareSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FilmRollTheme.accent)
                    .cornerRadius(24)
                }
            }
            .padding(.horizontal, 24)
            
            // Regenerate
            Button(action: {
                reelService.reset()
                player = nil
            }) {
                Text("Create New Reel")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 24)
        }
    }
    
    private var progressMessage: String {
        if reelService.progress < 0.3 {
            return "Loading photos..."
        } else if reelService.progress < 0.7 {
            return "Applying film effects..."
        } else {
            return "Finalizing video..."
        }
    }
    
    private func generateReel() {
        Task {
            _ = await reelService.generateReel(
                from: photos,
                eventTitle: eventTitle,
                eventDate: eventDate,
                loadImage: loadImage
            )
        }
    }
    
    private func saveToPhotos() {
        guard let url = reelService.generatedVideoURL else { return }
        
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
        HapticFeedback.success()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
