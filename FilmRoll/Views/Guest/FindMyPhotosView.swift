import SwiftUI
import AVFoundation

struct FindMyPhotosView: View {
    let photos: [Photo]
    let loadImage: (Photo) async -> UIImage?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var faceService = FaceDetectionService()
    @State private var showCamera = false
    @State private var selfieImage: UIImage?
    @State private var hasScanned = false
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Find My Photos")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if showResults {
                    // Results View
                    resultsView
                } else if faceService.isProcessing {
                    // Processing View
                    processingView
                } else {
                    // Initial View
                    initialView
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            SelfieCameraView { image in
                selfieImage = image
                showCamera = false
                startScanning()
            }
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(FilmRollTheme.accentLight)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "face.smiling")
                    .font(.system(size: 48))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            VStack(spacing: 12) {
                Text("Find Photos of You")
                    .font(.custom("PlayfairDisplay-Bold", size: 28))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text("Take a quick selfie and we'll find all the photos you appear in. Everything happens on your device — your face data is never shared.")
                    .font(.system(size: 15))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Privacy Badge
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("100% On-Device • Private")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
            
            Spacer()
            
            // Take Selfie Button
            Button(action: { showCamera = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                    Text("Take a Selfie")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FilmRollTheme.primaryText)
                .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Selfie Preview
            if let image = selfieImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(FilmRollTheme.accent, lineWidth: 3)
                    )
            }
            
            VStack(spacing: 12) {
                Text("Scanning Photos...")
                    .font(.custom("PlayfairDisplay-Bold", size: 24))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text("Looking for your face in \(photos.count) photos")
                    .font(.system(size: 15))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: faceService.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: FilmRollTheme.accent))
                    .frame(width: 200)
                
                Text("\(Int(faceService.progress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            // Found count
            if !faceService.matchedPhotos.isEmpty {
                Text("Found \(faceService.matchedPhotos.count) photos so far")
                    .font(.system(size: 14))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            Spacer()
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Results Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PHOTOS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FilmRollTheme.accent)
                    
                    Text("\(faceService.matchedPhotos.count) photos found")
                        .font(.system(size: 14))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    // Reset and scan again
                    faceService.reset()
                    selfieImage = nil
                    showResults = false
                }) {
                    Text("Scan Again")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FilmRollTheme.accent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            if faceService.matchedPhotos.isEmpty {
                // No results
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "photo.badge.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(FilmRollTheme.secondaryText)
                    
                    Text("No photos found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Text("We couldn't find any photos with your face. Try taking another selfie with better lighting.")
                        .font(.system(size: 14))
                        .foregroundColor(FilmRollTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else {
                // Photo Grid
                ScrollView {
                    PhotoGrid(
                        photos: faceService.matchedPhotos,
                        columns: 3
                    ) { _, _ in
                        // Handle photo tap
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private func startScanning() {
        guard let image = selfieImage else { return }
        
        Task {
            let success = await faceService.setReferenceFace(from: image)
            
            if success {
                _ = await faceService.findPhotosWithMyFace(in: photos, loadImage: loadImage)
                showResults = true
            } else {
                // No face detected in selfie
                faceService.reset()
                selfieImage = nil
            }
        }
    }
}

// MARK: - Selfie Camera View
struct SelfieCameraView: View {
    let onCapture: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Take a Selfie")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Camera Preview Placeholder
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 280, height: 280)
                    
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 270, height: 270)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                Text("Position your face in the circle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 16)
                
                Spacer()
                
                // Capture Button
                Button(action: {
                    // For demo, create a placeholder image
                    // In real app, this would capture from camera
                    capturedImage = createPlaceholderSelfie()
                    
                    if let image = capturedImage {
                        onCapture(image)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 82, height: 82)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func createPlaceholderSelfie() -> UIImage {
        // Create a simple placeholder image for demo
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.gray.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw a simple face icon
        let iconRect = CGRect(x: 50, y: 50, width: 100, height: 100)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: iconRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}
