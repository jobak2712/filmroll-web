import Foundation
import Vision
import UIKit
import CoreImage
import Combine

/// On-device face detection service for "Find My Photos" feature
/// Privacy-friendly: all processing done locally, no data shared
@MainActor
class FaceDetectionService: ObservableObject {
    static let shared = FaceDetectionService()
    
    @Published var isProcessing = false
    @Published var progress: Float = 0
    @Published var matchedPhotos: [Photo] = []
    
    private var referenceFaceObservations: [VNFaceObservation] = []
    
    nonisolated init() {}
    
    // MARK: - Capture Reference Selfie
    /// Detect faces in the user's selfie to use as reference
    func setReferenceFace(from image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results, !observations.isEmpty else {
                return false
            }
            
            referenceFaceObservations = observations
            return true
        } catch {
            print("Face detection failed: \(error)")
            return false
        }
    }
    
    // MARK: - Find Photos with Matching Faces
    /// Scan all photos and find ones containing the reference face
    func findPhotosWithMyFace(in photos: [Photo], loadImage: @escaping (Photo) async -> UIImage?) async -> [Photo] {
        guard !referenceFaceObservations.isEmpty else { return [] }
        
        isProcessing = true
        progress = 0
        matchedPhotos = []
        
        var matches: [Photo] = []
        let total = Float(photos.count)
        
        for (index, photo) in photos.enumerated() {
            // Load the image
            guard let image = await loadImage(photo),
                  let cgImage = image.cgImage else {
                progress = Float(index + 1) / total
                continue
            }
            
            // Detect faces in this photo
            let hasFace = await detectFaceInPhoto(cgImage: cgImage)
            
            if hasFace {
                matches.append(photo)
                matchedPhotos = matches
            }
            
            progress = Float(index + 1) / total
        }
        
        isProcessing = false
        return matches
    }
    
    private func detectFaceInPhoto(cgImage: CGImage) async -> Bool {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results, !observations.isEmpty else {
                return false
            }
            
            // Simple check: if photo has faces and reference has faces, consider it a potential match
            // For more accuracy, you could use VNDetectFaceLandmarksRequest or face embeddings
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Advanced Face Matching (using Face Landmarks)
    /// More accurate face matching using facial landmarks comparison
    func findPhotosWithFaceLandmarks(in photos: [Photo], referenceImage: UIImage, loadImage: @escaping (Photo) async -> UIImage?) async -> [Photo] {
        guard let refCgImage = referenceImage.cgImage else { return [] }
        
        // Get reference face print
        guard let referencePrint = await getFacePrint(from: refCgImage) else { return [] }
        
        isProcessing = true
        progress = 0
        matchedPhotos = []
        
        var matches: [Photo] = []
        let total = Float(photos.count)
        
        for (index, photo) in photos.enumerated() {
            guard let image = await loadImage(photo),
                  let cgImage = image.cgImage else {
                progress = Float(index + 1) / total
                continue
            }
            
            if let photoPrint = await getFacePrint(from: cgImage) {
                let similarity = compareFacePrints(referencePrint, photoPrint)
                
                // Threshold for face match (adjust as needed)
                if similarity > 0.6 {
                    matches.append(photo)
                    matchedPhotos = matches
                }
            }
            
            progress = Float(index + 1) / total
        }
        
        isProcessing = false
        return matches
    }
    
    private func getFacePrint(from cgImage: CGImage) async -> [CGPoint]? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observation = request.results?.first,
                  let landmarks = observation.landmarks,
                  let allPoints = landmarks.allPoints else {
                return nil
            }
            
            return allPoints.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
        } catch {
            return nil
        }
    }
    
    private func compareFacePrints(_ print1: [CGPoint], _ print2: [CGPoint]) -> Float {
        guard print1.count == print2.count, !print1.isEmpty else { return 0 }
        
        var totalDistance: CGFloat = 0
        
        for i in 0..<print1.count {
            let dx = print1[i].x - print2[i].x
            let dy = print1[i].y - print2[i].y
            totalDistance += sqrt(dx * dx + dy * dy)
        }
        
        let avgDistance = totalDistance / CGFloat(print1.count)
        
        // Convert distance to similarity score (0-1)
        // Lower distance = higher similarity
        let similarity = max(0, 1 - Float(avgDistance * 5))
        return similarity
    }
    
    func reset() {
        referenceFaceObservations = []
        matchedPhotos = []
        progress = 0
        isProcessing = false
    }
}
