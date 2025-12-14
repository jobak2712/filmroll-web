import Foundation
import UIKit
import Combine

class PhotoService: ObservableObject {
    static let shared = PhotoService()
    
    private let uploadQueue = DispatchQueue(label: "com.filmroll.upload", qos: .background)
    private var pendingUploads: [PendingUpload] = [] {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private var isProcessingQueue = false
    private let processingLock = NSLock() // C03: Thread-safe flag
    
    // C01: Retry configuration
    private let maxRetryAttempts = 5
    private let maxPendingAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // Published property for UI updates
    @Published var uploadStatus: String = ""
    
    private init() {
        loadPendingUploads()
        cleanupStaleUploads() // C01: Remove old failed uploads
        
        // Start processing queue on init
        Task {
            await processUploadQueue()
        }
    }
    
    // C01: Clean up uploads older than maxPendingAge
    private func cleanupStaleUploads() {
        let now = Date()
        let staleUploads = pendingUploads.filter { 
            now.timeIntervalSince($0.createdAt) > maxPendingAge 
        }
        
        for stale in staleUploads {
            let localUrl = URL(fileURLWithPath: stale.localPath)
            try? FileManager.default.removeItem(at: localUrl)
            print("🗑️ Removed stale upload: \(stale.id)")
        }
        
        pendingUploads.removeAll { 
            now.timeIntervalSince($0.createdAt) > maxPendingAge 
        }
        savePendingUploads()
    }
    
    var pendingUploadCount: Int {
        pendingUploads.count
    }
    
    // MARK: - Photo Capture
    func savePhoto(_ image: UIImage, eventId: String, participantId: String, caption: String? = nil, filter: String? = nil) async throws -> String {
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        
        // Apply film filter only if no custom filter was applied
        let finalImage = filter == nil ? applyFilmFilter(to: image) : image
        
        // Compress image
        guard let imageData = finalImage.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }
        
        // Save locally first
        let localUrl = getLocalPhotoUrl(fileName: fileName)
        try imageData.write(to: localUrl)
        
        // Create storage path
        let storagePath = "\(eventId)/\(participantId)/\(fileName)"
        
        // Queue for upload
        let pending = PendingUpload(
            id: photoId,
            eventId: eventId,
            participantId: participantId,
            localPath: localUrl.path,
            storagePath: storagePath,
            fileName: fileName,
            fileSize: Int64(imageData.count),
            createdAt: Date(),
            caption: caption,
            filterApplied: filter
        )
        
        pendingUploads.append(pending)
        savePendingUploads()
        
        // Try upload immediately
        Task {
            await processUploadQueue()
        }
        
        return photoId
    }
    
    // MARK: - Film Filter
    func applyFilmFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        
        // Apply subtle warm tone (Chrome effect gives a nice film look)
        guard let filter = CIFilter(name: "CIPhotoEffectChrome") else { return image }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Upload Queue
    func processUploadQueue() async {
        // C03: Thread-safe check
        processingLock.lock()
        guard !isProcessingQueue else { 
            processingLock.unlock()
            return 
        }
        guard !pendingUploads.isEmpty else { 
            processingLock.unlock()
            return 
        }
        isProcessingQueue = true
        processingLock.unlock()
        
        defer {
            processingLock.lock()
            isProcessingQueue = false
            processingLock.unlock()
        }
        
        // Process uploads one by one
        var successfulUploads: [String] = []
        var failedUploads: [String] = []
        
        for (index, pending) in pendingUploads.enumerated() {
            // C01: Skip if max retries exceeded
            if pending.retryCount >= maxRetryAttempts {
                failedUploads.append(pending.id)
                #if DEBUG
                print("⚠️ Max retries exceeded for \(pending.id), removing")
                #endif
                continue
            }
            
            do {
                try await uploadPhoto(pending)
                successfulUploads.append(pending.id)
                #if DEBUG
                print("✅ Uploaded photo: \(pending.id)")
                #endif
            } catch {
                #if DEBUG
                print("❌ Upload failed for \(pending.id) (attempt \(pending.retryCount + 1)): \(error)")
                #endif
                // C01: Increment retry count
                pendingUploads[index].retryCount += 1
            }
        }
        
        // Remove successful and permanently failed uploads
        for id in successfulUploads + failedUploads {
            removePendingUpload(id: id)
        }
        
        savePendingUploads()
    }
    
    private func uploadPhoto(_ pending: PendingUpload) async throws {
        // Get signed URL from Supabase
        print("📤 Getting signed URL for \(pending.fileName)...")
        let signedUrl: String
        let actualStoragePath: String
        do {
            let result = try await SupabaseService.shared.getSignedUploadUrl(
                eventId: pending.eventId,
                participantId: pending.participantId,
                fileName: pending.fileName
            )
            signedUrl = result.signedUrl
            actualStoragePath = result.storagePath
            print("✅ Got signed URL, storage path: \(actualStoragePath)")
        } catch {
            print("❌ Failed to get signed URL: \(error)")
            throw error
        }
        
        // Read local file
        let localUrl = URL(fileURLWithPath: pending.localPath)
        let imageData = try Data(contentsOf: localUrl)
        print("📦 Image data size: \(imageData.count) bytes")
        
        // Upload to storage
        guard let uploadUrl = URL(string: signedUrl) else {
            print("❌ Invalid upload URL: \(signedUrl)")
            throw PhotoError.uploadFailed
        }
        
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = imageData
        
        print("📤 Uploading to storage...")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ No HTTP response")
            throw PhotoError.uploadFailed
        }
        
        print("📡 Storage upload status: \(httpResponse.statusCode)")
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorString = String(data: responseData, encoding: .utf8) {
                print("❌ Storage upload error: \(errorString)")
            }
            throw PhotoError.uploadFailed
        }
        
        // Register photo in database with the ACTUAL storage path from signPhotoUpload
        print("📝 Registering photo in database with path: \(actualStoragePath)")
        let photoRequest = CreatePhotoRequest(
            eventId: pending.eventId,
            participantId: pending.participantId,
            storagePath: actualStoragePath,  // Use the path returned by signPhotoUpload, not the local one
            fileSize: pending.fileSize,
            caption: pending.caption,
            filterApplied: pending.filterApplied
        )
        
        _ = try await SupabaseService.shared.registerPhoto(photoRequest)
        print("✅ Photo registered successfully")
        
        // Delete local file after successful upload
        try? FileManager.default.removeItem(at: localUrl)
    }
    
    // MARK: - Local Storage
    private func getLocalPhotoUrl(fileName: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("pending_photos")
        
        try? FileManager.default.createDirectory(at: photosPath, withIntermediateDirectories: true)
        
        return photosPath.appendingPathComponent(fileName)
    }
    
    private func loadPendingUploads() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queueFile = documentsPath.appendingPathComponent("upload_queue.json")
        
        guard let data = try? Data(contentsOf: queueFile),
              let uploads = try? JSONDecoder().decode([PendingUpload].self, from: data) else {
            return
        }
        
        pendingUploads = uploads
    }
    
    private func savePendingUploads() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queueFile = documentsPath.appendingPathComponent("upload_queue.json")
        
        guard let data = try? JSONEncoder().encode(pendingUploads) else { return }
        try? data.write(to: queueFile)
    }
    
    private func removePendingUpload(id: String) {
        pendingUploads.removeAll { $0.id == id }
        savePendingUploads()
    }
    
    // MARK: - Cleanup
    func clearAllPendingUploads() {
        // Delete local files
        for pending in pendingUploads {
            let localUrl = URL(fileURLWithPath: pending.localPath)
            try? FileManager.default.removeItem(at: localUrl)
        }
        
        pendingUploads.removeAll()
        savePendingUploads()
    }
    
    func retryFailedUploads() {
        Task {
            await processUploadQueue()
        }
    }
    
    // Reset retry counts and force retry all pending uploads
    func resetAndRetryAll() {
        print("🔄 Resetting \(pendingUploads.count) pending uploads...")
        for i in pendingUploads.indices {
            pendingUploads[i].retryCount = 0
        }
        savePendingUploads()
        Task {
            await processUploadQueue()
        }
    }
}

// MARK: - Models
struct PendingUpload: Codable {
    let id: String
    let eventId: String
    let participantId: String
    let localPath: String
    let storagePath: String
    let fileName: String
    let fileSize: Int64
    let createdAt: Date
    let caption: String?
    let filterApplied: String?
    var retryCount: Int = 0 // C01: Track retry attempts
}

enum PhotoError: Error, LocalizedError {
    case compressionFailed
    case uploadFailed
    case saveFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image"
        case .uploadFailed: return "Failed to upload photo"
        case .saveFailed: return "Failed to save photo"
        case .invalidData: return "Invalid image data"
        }
    }
}
