import Foundation
import AVFoundation
import UIKit
import CoreImage
import Combine

/// Service to generate highlight reels from event photos
@MainActor
class ReelGeneratorService: ObservableObject {
    static let shared = ReelGeneratorService()
    
    @Published var isGenerating = false
    @Published var progress: Float = 0
    @Published var generatedVideoURL: URL?
    @Published var errorMessage: String?
    
    private let photoDisplayDuration: Double = 2.0 // seconds per photo
    private let transitionDuration: Double = 0.5
    private let outputSize = CGSize(width: 1080, height: 1920) // 9:16 vertical
    
    nonisolated init() {}
    
    // MARK: - Generate Highlight Reel
    func generateReel(
        from photos: [Photo],
        eventTitle: String,
        eventDate: Date,
        loadImage: @escaping (Photo) async -> UIImage?
    ) async -> URL? {
        guard !photos.isEmpty else {
            errorMessage = "No photos to create reel"
            return nil
        }
        
        isGenerating = true
        progress = 0
        errorMessage = nil
        
        // Limit to 15 photos for a ~30 second reel
        let selectedPhotos = Array(photos.prefix(15))
        
        // Load all images first
        var images: [UIImage] = []
        for (index, photo) in selectedPhotos.enumerated() {
            if let image = await loadImage(photo) {
                images.append(image)
            }
            progress = Float(index + 1) / Float(selectedPhotos.count) * 0.3
        }
        
        guard !images.isEmpty else {
            errorMessage = "Failed to load images"
            isGenerating = false
            return nil
        }
        
        // Generate video
        let videoURL = await createVideo(
            from: images,
            eventTitle: eventTitle,
            eventDate: eventDate
        )
        
        isGenerating = false
        progress = 1.0
        generatedVideoURL = videoURL
        
        return videoURL
    }
    
    // MARK: - Create Video from Images
    private func createVideo(
        from images: [UIImage],
        eventTitle: String,
        eventDate: Date
    ) async -> URL? {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("filmroll_reel_\(UUID().uuidString).mp4")
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            errorMessage = "Failed to create video writer"
            return nil
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(outputSize.width),
            AVVideoHeightKey: Int(outputSize.height)
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(outputSize.width),
                kCVPixelBufferHeightKey as String: Int(outputSize.height)
            ]
        )
        
        videoWriter.add(writerInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
        let photoDurationFrames = Int(photoDisplayDuration * 30)
        
        var frameCount = 0
        
        for (index, image) in images.enumerated() {
            // Process image with film effect
            let processedImage = applyFilmEffect(to: image, eventTitle: eventTitle, eventDate: eventDate, photoIndex: index + 1, totalPhotos: images.count)
            
            guard let pixelBuffer = pixelBuffer(from: processedImage) else { continue }
            
            // Write frames for this photo
            for _ in 0..<photoDurationFrames {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                
                let presentationTime = CMTime(value: CMTimeValue(frameCount), timescale: 30)
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                frameCount += 1
            }
            
            progress = 0.3 + Float(index + 1) / Float(images.count) * 0.7
        }
        
        writerInput.markAsFinished()
        await videoWriter.finishWriting()
        
        if videoWriter.status == .completed {
            return outputURL
        } else {
            errorMessage = "Failed to generate video"
            return nil
        }
    }
    
    // MARK: - Apply Film Effect
    private func applyFilmEffect(
        to image: UIImage,
        eventTitle: String,
        eventDate: Date,
        photoIndex: Int,
        totalPhotos: Int
    ) -> UIImage {
        let size = outputSize
        
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        
        // Fill background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Calculate image rect (center crop to fill)
        let imageAspect = image.size.width / image.size.height
        let targetAspect = size.width / size.height
        
        var drawRect: CGRect
        if imageAspect > targetAspect {
            // Image is wider
            let height = size.height * 0.7
            let width = height * imageAspect
            let x = (size.width - width) / 2
            let y = (size.height - height) / 2 - 50
            drawRect = CGRect(x: x, y: y, width: width, height: height)
        } else {
            // Image is taller
            let width = size.width * 0.9
            let height = width / imageAspect
            let x = (size.width - width) / 2
            let y = (size.height - height) / 2 - 50
            drawRect = CGRect(x: x, y: y, width: width, height: height)
        }
        
        // Draw image with rounded corners
        let path = UIBezierPath(roundedRect: drawRect, cornerRadius: 16)
        context.addPath(path.cgPath)
        context.clip()
        image.draw(in: drawRect)
        context.resetClip()
        
        // Add film grain overlay
        addFilmGrain(to: context, size: size)
        
        // Add vignette
        addVignette(to: context, size: size)
        
        // Add timestamp caption
        addTimestamp(to: context, size: size, eventTitle: eventTitle, eventDate: eventDate, photoIndex: photoIndex, totalPhotos: totalPhotos)
        
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return result
    }
    
    private func addFilmGrain(to context: CGContext, size: CGSize) {
        // Simple noise pattern
        for _ in 0..<500 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let alpha = CGFloat.random(in: 0.01..<0.05)
            
            context.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
    }
    
    private func addVignette(to context: CGContext, size: CGSize) {
        let colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.4).cgColor
        ]
        
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.5, 1.0]
        )!
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = max(size.width, size.height) / 1.5
        
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )
    }
    
    private func addTimestamp(
        to context: CGContext,
        size: CGSize,
        eventTitle: String,
        eventDate: Date,
        photoIndex: Int,
        totalPhotos: Int
    ) {
        // Event title at top
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let titleString = NSAttributedString(string: eventTitle, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleRect = CGRect(
            x: (size.width - titleSize.width) / 2,
            y: 80,
            width: titleSize.width,
            height: titleSize.height
        )
        titleString.draw(in: titleRect)
        
        // Date below title
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let dateString = dateFormatter.string(from: eventDate)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        let dateAttrString = NSAttributedString(string: dateString, attributes: dateAttributes)
        let dateSize = dateAttrString.size()
        let dateRect = CGRect(
            x: (size.width - dateSize.width) / 2,
            y: 120,
            width: dateSize.width,
            height: dateSize.height
        )
        dateAttrString.draw(in: dateRect)
        
        // Photo counter at bottom
        let counterString = "\(photoIndex) / \(totalPhotos)"
        let counterAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor.orange
        ]
        
        let counterAttrString = NSAttributedString(string: counterString, attributes: counterAttributes)
        let counterSize = counterAttrString.size()
        let counterRect = CGRect(
            x: (size.width - counterSize.width) / 2,
            y: size.height - 120,
            width: counterSize.width,
            height: counterSize.height
        )
        counterAttrString.draw(in: counterRect)
    }
    
    // MARK: - Pixel Buffer Helper
    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(outputSize.width),
            Int(outputSize.height),
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: outputSize.height)
        context.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: outputSize))
        UIGraphicsPopContext()
        
        return buffer
    }
    
    func reset() {
        isGenerating = false
        progress = 0
        generatedVideoURL = nil
        errorMessage = nil
    }
}
