import Foundation
import AVFoundation
import SwiftUI
import Combine

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isCameraReady = false
    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false
    @Published var isFrontCamera = false
    @Published var errorMessage: String?
    
    nonisolated let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    
    nonisolated override init() {
        super.init()
    }
    
    // MARK: - Setup
    func setupCamera() {
        Task {
            await requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await configureSession()
            } else {
                errorMessage = "Camera access denied"
            }
        default:
            errorMessage = "Camera access denied"
        }
    }
    
    private func configureSession() async {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Add video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            errorMessage = "No camera available"
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            errorMessage = "Failed to setup camera"
            return
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        session.commitConfiguration()
        
        // Start session on background thread
        Task.detached { [weak self] in
            self?.session.startRunning()
            await MainActor.run {
                self?.isSessionRunning = true
                self?.isCameraReady = true
            }
        }
    }
    
    // MARK: - Camera Controls
    func switchCamera() {
        guard isCameraReady else { return }
        
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Toggle camera position
        isFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            errorMessage = "Failed to switch camera"
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    // MARK: - Capture
    func capturePhoto() async -> UIImage? {
        guard isCameraReady else { return nil }
        
        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = isFlashOn ? .on : .off
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - Cleanup
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
        isSessionRunning = false
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                errorMessage = "Capture failed: \(error.localizedDescription)"
                photoContinuation?.resume(returning: nil)
                photoContinuation = nil
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                photoContinuation?.resume(returning: nil)
                photoContinuation = nil
                return
            }
            
            capturedImage = image
            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}
