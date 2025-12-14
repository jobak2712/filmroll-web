import SwiftUI
import AVFoundation
import PhotosUI

struct GuestCameraView: View {
    @ObservedObject var viewModel: GuestViewModel
    @StateObject private var cameraViewModel = CameraViewModel()
    @ObservedObject private var photoService = PhotoService.shared
    @State private var showCountdown = false
    @State private var showGallery = false
    @State private var lastCapturedImage: UIImage?
    @State private var showCaptureFlash = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showCreateMessage = false
    @State private var selectedFilter: PhotoFilter = .none
    @State private var photoCaption: String = ""
    @State private var showFilters = false
    @State private var showGrid = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingFromLibrary = false
    @State private var pendingImage: UIImage?
    @State private var showPhotoPreview = false
    @State private var isSendingPhoto = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if showPhotoPreview, let image = pendingImage {
                PhotoPreviewOverlay(
                    image: image,
                    caption: $photoCaption,
                    selectedFilter: $selectedFilter,
                    isSending: isSendingPhoto,
                    onSend: sendPhoto,
                    onRetake: discardPhoto
                )
            } else {
                cameraView
            }
            
            if showCaptureFlash {
                Color.white.ignoresSafeArea().opacity(0.6)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraViewModel.setupCamera()
        }
        .onDisappear { cameraViewModel.stopSession() }
        .fullScreenCover(isPresented: $showCountdown) {
            RevealCountdownView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showGallery) {
            GuestGalleryView(viewModel: viewModel)
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .sheet(isPresented: $showCreateMessage) {
            if let event = viewModel.event, let participant = viewModel.participant {
                CreateMessageView(
                    eventId: event.id,
                    participantId: participant.id,
                    participantName: viewModel.guestName.isEmpty ? nil : viewModel.guestName,
                    onMessageCreated: { message in
                        viewModel.sendMessage(message)
                        toastMessage = "Message sent!"
                        toastType = .success
                        showToast = true
                    }
                )
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if let error = newValue {
                toastMessage = error
                toastType = .error
                showToast = true
                viewModel.clearMessages()
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task { await loadPhotoFromLibrary(item) }
        }
    }

    
    private var cameraView: some View {
        ZStack {
            if let error = cameraViewModel.errorMessage {
                permissionDeniedView(error: error)
            } else {
                CameraPreviewView(session: cameraViewModel.session).ignoresSafeArea()
                cameraOverlay
            }
            
            if photoService.pendingUploadCount > 0 {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.7)
                        Text("\(photoService.pendingUploadCount) uploading...")
                            .font(.system(size: 12)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.black.opacity(0.6)).cornerRadius(16)
                    .padding(.bottom, 120)
                }
            }
        }
    }
    
    private func permissionDeniedView(error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill").font(.system(size: 64)).foregroundColor(FilmRollTheme.secondaryText)
            Text("Camera Access Required").font(.custom("PlayfairDisplay-Bold", size: 24)).foregroundColor(FilmRollTheme.primaryText)
            Text(error).font(.system(size: 15)).foregroundColor(FilmRollTheme.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 32)
            Button(action: { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }) {
                Text("Open Settings").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(FilmRollTheme.buttonBackground).cornerRadius(28)
            }.padding(.horizontal, 48)
            Button(action: { appState.isGuestMode = false }) {
                Text("Go Back").font(.system(size: 14)).foregroundColor(FilmRollTheme.secondaryText)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(FilmRollTheme.background)
    }
    
    private var cameraOverlay: some View {
        VStack {
            topBar
            photoCounter
            Spacer()
            viewfinderFrame
            Spacer()
            bottomControls
            if showFilters {
                CompactFilterStrip(selectedFilter: $selectedFilter)
                    .transition(.move(edge: .bottom).combined(with: .opacity)).padding(.bottom, 8)
            }
            hintText
        }
    }
    
    private var topBar: some View {
        HStack {
            Menu {
                Button(action: { cameraViewModel.stopSession(); viewModel.leaveEvent() }) {
                    Label("Join Different Event", systemImage: "arrow.left.arrow.right")
                }
                Button(role: .destructive, action: { cameraViewModel.stopSession(); viewModel.leaveEvent(); appState.isGuestMode = false }) {
                    Label("Exit Guest Mode", systemImage: "xmark")
                }
            } label: {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "line.3.horizontal").font(.system(size: 16, weight: .medium)).foregroundColor(.white))
            }
            Spacer()
            if selectedFilter != .none {
                HStack(spacing: 4) {
                    Image(systemName: "camera.filters").font(.system(size: 10))
                    Text(selectedFilter.rawValue).font(.system(size: 11, weight: .medium))
                }.foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                .background(FilmRollTheme.accent.opacity(0.8)).cornerRadius(12)
            }
            Spacer()
            Button(action: { cameraViewModel.switchCamera(); HapticFeedback.light() }) {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "camera.rotate").font(.system(size: 16, weight: .medium)).foregroundColor(.white))
            }
            Button(action: { cameraViewModel.toggleFlash(); HapticFeedback.light() }) {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: cameraViewModel.isFlashOn ? "bolt.fill" : "bolt.slash").font(.system(size: 16, weight: .medium)).foregroundColor(cameraViewModel.isFlashOn ? .yellow : .white))
            }
            Button(action: { showGrid.toggle(); HapticFeedback.light() }) {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "grid").font(.system(size: 16, weight: .medium)).foregroundColor(showGrid ? FilmRollTheme.accent : .white))
            }
        }.padding(.horizontal, 16).padding(.top, 16)
    }
    
    private var photoCounter: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(FilmRollTheme.accent)
                Text("\(viewModel.shotsRemaining)").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("/\(viewModel.shotLimit)").font(.system(size: 16)).foregroundColor(.white.opacity(0.6))
            }
            Text("photos remaining").font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
        }.padding(.horizontal, 20).padding(.vertical, 10).background(Color.black.opacity(0.6)).cornerRadius(24).padding(.top, 20)
    }

    
    private var viewfinderFrame: some View {
        let frameSize = UIScreen.main.bounds.width - 48
        return ZStack {
            RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: frameSize, height: frameSize)
                .overlay(
                    GeometryReader { geo in
                        let size: CGFloat = 20
                        Group {
                            Path { p in p.move(to: CGPoint(x: 0, y: size)); p.addLine(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: size, y: 0)) }.stroke(Color.white.opacity(0.5), lineWidth: 3)
                            Path { p in p.move(to: CGPoint(x: geo.size.width - size, y: 0)); p.addLine(to: CGPoint(x: geo.size.width, y: 0)); p.addLine(to: CGPoint(x: geo.size.width, y: size)) }.stroke(Color.white.opacity(0.5), lineWidth: 3)
                            Path { p in p.move(to: CGPoint(x: 0, y: geo.size.height - size)); p.addLine(to: CGPoint(x: 0, y: geo.size.height)); p.addLine(to: CGPoint(x: size, y: geo.size.height)) }.stroke(Color.white.opacity(0.5), lineWidth: 3)
                            Path { p in p.move(to: CGPoint(x: geo.size.width - size, y: geo.size.height)); p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height)); p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - size)) }.stroke(Color.white.opacity(0.5), lineWidth: 3)
                        }
                    }
                )
            if showGrid {
                Path { p in
                    p.move(to: CGPoint(x: frameSize/3, y: 0)); p.addLine(to: CGPoint(x: frameSize/3, y: frameSize))
                    p.move(to: CGPoint(x: frameSize*2/3, y: 0)); p.addLine(to: CGPoint(x: frameSize*2/3, y: frameSize))
                    p.move(to: CGPoint(x: 0, y: frameSize/3)); p.addLine(to: CGPoint(x: frameSize, y: frameSize/3))
                    p.move(to: CGPoint(x: 0, y: frameSize*2/3)); p.addLine(to: CGPoint(x: frameSize, y: frameSize*2/3))
                }.stroke(Color.white.opacity(0.4), lineWidth: 0.5).frame(width: frameSize, height: frameSize)
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 40) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    if let img = lastCapturedImage {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 2))
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2)).frame(width: 50, height: 50)
                            .overlay(Image(systemName: "photo.on.rectangle").font(.system(size: 18)).foregroundColor(.white.opacity(0.8)))
                    }
                }.disabled(!viewModel.canTakePhoto || isLoadingFromLibrary).opacity(viewModel.canTakePhoto ? 1 : 0.5)
                
                Button(action: capturePhoto) {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 72, height: 72)
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 4).frame(width: 84, height: 84)
                        if viewModel.isCapturing || isLoadingFromLibrary {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: FilmRollTheme.primaryText))
                        }
                    }
                }.disabled(!viewModel.canTakePhoto || viewModel.isCapturing || isLoadingFromLibrary).opacity(viewModel.canTakePhoto ? 1 : 0.5)
                
                Button(action: { if viewModel.isRevealed { showGallery = true } else { showCountdown = true } }) {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 50, height: 50)
                        .overlay(Image(systemName: viewModel.isRevealed ? "photo.stack" : "clock").font(.system(size: 18)).foregroundColor(.white))
                }
            }
            
            HStack(spacing: 16) {
                Button(action: { withAnimation { showFilters.toggle() }; HapticFeedback.light() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.filters").font(.system(size: 12))
                        Text(selectedFilter == .none ? "Filters" : selectedFilter.rawValue).font(.system(size: 13, weight: .medium))
                    }.foregroundColor(selectedFilter == .none ? .white : FilmRollTheme.accent)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(selectedFilter == .none ? Color.white.opacity(0.2) : FilmRollTheme.accent.opacity(0.3)).cornerRadius(20)
                }
                Button(action: { showCreateMessage = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill").font(.system(size: 12))
                        Text("Message").font(.system(size: 13, weight: .medium))
                    }.foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.white.opacity(0.2)).cornerRadius(20)
                }
            }
        }.padding(.bottom, 8)
    }
    
    private var hintText: some View {
        Group {
            if viewModel.canTakePhoto {
                Text("Tap to capture").font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
            } else {
                Text("No shots remaining").font(.system(size: 14)).foregroundColor(FilmRollTheme.accent)
            }
        }.padding(.bottom, 40)
    }

    
    @MainActor
    private func loadPhotoFromLibrary(_ item: PhotosPickerItem) async {
        guard viewModel.canTakePhoto else { return }
        isLoadingFromLibrary = true
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                toastMessage = "Failed to load photo"
                toastType = .error
                showToast = true
                isLoadingFromLibrary = false
                return
            }
            // Set pending image and show preview
            self.pendingImage = image
            self.selectedPhotoItem = nil
            self.showPhotoPreview = true
            HapticFeedback.success()
        } catch {
            toastMessage = "Failed to load photo from library"
            toastType = .error
            showToast = true
        }
        isLoadingFromLibrary = false
    }
    
    private func capturePhoto() {
        guard viewModel.canTakePhoto else { return }
        HapticFeedback.medium()
        Task { @MainActor in
            showCaptureFlash = true
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second flash
            
            if let image = await cameraViewModel.capturePhoto() {
                // Set pending image and show preview
                self.pendingImage = image
                self.showPhotoPreview = true
            }
            
            showCaptureFlash = false
        }
    }
    
    private func sendPhoto() {
        guard let image = pendingImage else { return }
        isSendingPhoto = true
        Task { @MainActor in
            let filteredImage = PhotoFilterService.shared.applyFilter(selectedFilter, to: image)
            lastCapturedImage = filteredImage
            let captionToSave = photoCaption.isEmpty ? nil : photoCaption
            let filterName = selectedFilter == .none ? nil : selectedFilter.rawValue
            await viewModel.capturePhoto(filteredImage, caption: captionToSave, filter: filterName)
            
            // Reset state after sending
            self.photoCaption = ""
            self.pendingImage = nil
            self.showPhotoPreview = false
            self.isSendingPhoto = false
            self.selectedFilter = .none
            
            if viewModel.isRevealed {
                toastMessage = "Photo sent! \(viewModel.shotsRemaining) shots left 📸"
            } else {
                toastMessage = "Photo sent! You'll see it at reveal time 🎬"
            }
            toastType = .success
            showToast = true
            HapticFeedback.success()
        }
    }
    
    private func discardPhoto() {
        pendingImage = nil
        photoCaption = ""
        showPhotoPreview = false
        selectedFilter = .none
        HapticFeedback.light()
    }
}

// MARK: - Photo Preview Overlay
struct PhotoPreviewOverlay: View {
    let image: UIImage
    @Binding var caption: String
    @Binding var selectedFilter: PhotoFilter
    let isSending: Bool
    let onSend: () -> Void
    let onRetake: () -> Void
    @State private var previewImage: UIImage?
    @State private var showFilters = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: onRetake) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark").font(.system(size: 16, weight: .medium))
                            Text("Discard").font(.system(size: 14, weight: .medium))
                        }.foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.white.opacity(0.2)).cornerRadius(20)
                    }.disabled(isSending)
                    Spacer()
                    Text("Review Photo").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 90, height: 40)
                }.padding(.horizontal, 16).padding(.top, 16)
                
                Spacer()
                Image(uiImage: previewImage ?? image).resizable().scaledToFit().cornerRadius(16).padding(.horizontal, 24)
                Spacer()
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "text.bubble").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                        TextField("Add a caption...", text: $caption).font(.system(size: 15)).foregroundColor(.white)
                    }.padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.white.opacity(0.15)).cornerRadius(12).padding(.horizontal, 24)
                    
                    Button(action: { withAnimation { showFilters.toggle() }; HapticFeedback.light() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.filters").font(.system(size: 14))
                            Text(selectedFilter == .none ? "Add Filter" : selectedFilter.rawValue).font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.down").font(.system(size: 10))
                        }.foregroundColor(selectedFilter == .none ? .white.opacity(0.8) : FilmRollTheme.accent)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(selectedFilter == .none ? Color.white.opacity(0.15) : FilmRollTheme.accent.opacity(0.3)).cornerRadius(20)
                    }
                    
                    if showFilters {
                        CompactFilterStrip(selectedFilter: $selectedFilter).transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }.padding(.bottom, 16)
                
                Button(action: onSend) {
                    HStack(spacing: 10) {
                        if isSending {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill").font(.system(size: 16))
                        }
                        Text(isSending ? "Sending..." : "Send Photo").font(.system(size: 17, weight: .semibold))
                    }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(FilmRollTheme.accent).cornerRadius(28)
                }.disabled(isSending).padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .onAppear { updatePreview() }
        .onChange(of: selectedFilter) { _, _ in updatePreview() }
    }
    
    private func updatePreview() {
        Task.detached(priority: .userInitiated) {
            let filtered = PhotoFilterService.shared.applyFilter(selectedFilter, to: image)
            await MainActor.run { previewImage = filtered }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero); view.backgroundColor = .black
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { context.coordinator.previewLayer?.frame = uiView.bounds }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var previewLayer: AVCaptureVideoPreviewLayer? }
}
