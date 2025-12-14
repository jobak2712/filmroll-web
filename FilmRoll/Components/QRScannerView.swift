import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isFlashOn = false
    @State private var hasPermission = false
    @State private var showPermissionDenied = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if hasPermission {
                    // Camera view
                    QRScannerCameraView(onCodeScanned: { code in
                        HapticFeedback.success()
                        onCodeScanned(code)
                    })
                    .ignoresSafeArea()
                    
                    // Overlay
                    VStack {
                        Spacer()
                        
                        // Scan frame
                        ZStack {
                            // Corner brackets
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 250, height: 250)
                            
                            // Scanning line animation
                            ScanningLineView()
                                .frame(width: 230, height: 230)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Text("Point at QR code to scan")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.top, 24)
                        
                        Spacer()
                        
                        // Flash toggle
                        Button(action: toggleFlash) {
                            VStack(spacing: 8) {
                                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 24))
                                Text(isFlashOn ? "Flash On" : "Flash Off")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                            .padding()
                        }
                        .padding(.bottom, 40)
                    }
                } else if showPermissionDenied {
                    // Permission denied view
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(FilmRollTheme.secondaryText)
                        
                        Text("Camera Access Required")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FilmRollTheme.primaryText)
                        
                        Text("Please enable camera access in Settings to scan QR codes")
                            .font(.system(size: 14))
                            .foregroundColor(FilmRollTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(FilmRollTheme.accent)
                        .cornerRadius(25)
                    }
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Scan QR Code")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                hasPermission = granted
                showPermissionDenied = !granted
            }
        case .denied, .restricted:
            await MainActor.run {
                showPermissionDenied = true
            }
        @unknown default:
            break
        }
    }
    
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .off : .on
            isFlashOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Flash toggle error: \(error)")
        }
    }
}

// MARK: - Scanning Line Animation
struct ScanningLineView: View {
    @State private var offset: CGFloat = -100
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, FilmRollTheme.accent.opacity(0.8), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 100
                }
            }
    }
}

// MARK: - Camera View (UIKit wrapper)
struct QRScannerCameraView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.captureSession = session
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        hasScanned = true
        onCodeScanned?(stringValue)
    }
}

#Preview {
    QRScannerView { code in
        print("Scanned: \(code)")
    }
}
