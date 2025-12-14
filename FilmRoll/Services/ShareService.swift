import SwiftUI
import Photos

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    // MARK: - Share Event Link
    func shareEventLink(event: Event, from viewController: UIViewController? = nil) {
        let joinUrl = "https://filmroll.app/join/\(event.joinCode)"
        let message = "Join my FilmRoll event: \(event.title)\n\nScan the QR code or tap this link to join and capture moments together!"
        
        let activityItems: [Any] = [message, URL(string: joinUrl)!]
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let vc = viewController ?? UIApplication.shared.topViewController {
            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = vc.view
                popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            vc.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Share Photo
    func sharePhoto(image: UIImage, from viewController: UIViewController? = nil) {
        let activityItems: [Any] = [image]
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let vc = viewController ?? UIApplication.shared.topViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = vc.view
                popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            vc.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Save to Camera Roll
    func saveToPhotoLibrary(image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            throw ShareError.permissionDenied
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    func saveMultipleToPhotoLibrary(images: [UIImage], progress: @escaping (Int, Int) -> Void) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            throw ShareError.permissionDenied
        }
        
        for (index, image) in images.enumerated() {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            progress(index + 1, images.count)
        }
    }
    
    // MARK: - Download Photo from URL
    func downloadPhoto(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ShareError.downloadFailed
        }
        
        guard let image = UIImage(data: data) else {
            throw ShareError.invalidImageData
        }
        
        return image
    }
}

// MARK: - Errors
enum ShareError: Error, LocalizedError {
    case permissionDenied
    case downloadFailed
    case invalidImageData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access denied. Please enable in Settings."
        case .downloadFailed:
            return "Failed to download photo."
        case .invalidImageData:
            return "Invalid image data."
        case .saveFailed:
            return "Failed to save photo."
        }
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var topViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }
}
