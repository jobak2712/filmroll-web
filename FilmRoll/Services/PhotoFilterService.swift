import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Photo Filter Types
enum PhotoFilter: String, CaseIterable, Identifiable {
    case none = "Original"
    case vintage = "Vintage"
    case disposable = "Disposable"
    case blackWhite = "B&W"
    case warm = "Warm"
    case cool = "Cool"
    case fade = "Fade"
    case vivid = "Vivid"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .vintage: return "camera.filters"
        case .disposable: return "film"
        case .blackWhite: return "circle.lefthalf.filled"
        case .warm: return "sun.max"
        case .cool: return "snowflake"
        case .fade: return "cloud"
        case .vivid: return "sparkles"
        }
    }
}

// MARK: - Photo Filter Service
class PhotoFilterService {
    static let shared = PhotoFilterService()
    private let context = CIContext()
    
    private init() {}
    
    func applyFilter(_ filter: PhotoFilter, to image: UIImage) -> UIImage {
        guard filter != .none else { return image }
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filteredImage: CIImage?
        
        switch filter {
        case .none:
            return image
        case .vintage:
            filteredImage = applyVintageFilter(to: ciImage)
        case .disposable:
            filteredImage = applyDisposableFilter(to: ciImage)
        case .blackWhite:
            filteredImage = applyBlackWhiteFilter(to: ciImage)
        case .warm:
            filteredImage = applyWarmFilter(to: ciImage)
        case .cool:
            filteredImage = applyCoolFilter(to: ciImage)
        case .fade:
            filteredImage = applyFadeFilter(to: ciImage)
        case .vivid:
            filteredImage = applyVividFilter(to: ciImage)
        }
        
        guard let output = filteredImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Filter Implementations
    
    private func applyVintageFilter(to image: CIImage) -> CIImage? {
        // Sepia tone + vignette + slight grain
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = image
        sepia.intensity = 0.6
        
        guard let sepiaOutput = sepia.outputImage else { return nil }
        
        let vignette = CIFilter.vignette()
        vignette.inputImage = sepiaOutput
        vignette.intensity = 1.5
        vignette.radius = 2.0
        
        return vignette.outputImage
    }
    
    private func applyDisposableFilter(to image: CIImage) -> CIImage? {
        // Slight color shift, grain, light leak effect
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = image
        colorControls.saturation = 1.2
        colorControls.contrast = 1.1
        colorControls.brightness = 0.05
        
        guard let colorOutput = colorControls.outputImage else { return nil }
        
        // Add slight vignette
        let vignette = CIFilter.vignette()
        vignette.inputImage = colorOutput
        vignette.intensity = 0.8
        vignette.radius = 1.5
        
        guard let vignetteOutput = vignette.outputImage else { return nil }
        
        // Warm color temperature
        let tempAndTint = CIFilter.temperatureAndTint()
        tempAndTint.inputImage = vignetteOutput
        tempAndTint.neutral = CIVector(x: 6500, y: 0)
        tempAndTint.targetNeutral = CIVector(x: 5500, y: 50)
        
        return tempAndTint.outputImage
    }
    
    private func applyBlackWhiteFilter(to image: CIImage) -> CIImage? {
        let noir = CIFilter.photoEffectNoir()
        noir.inputImage = image
        return noir.outputImage
    }
    
    private func applyWarmFilter(to image: CIImage) -> CIImage? {
        let tempAndTint = CIFilter.temperatureAndTint()
        tempAndTint.inputImage = image
        tempAndTint.neutral = CIVector(x: 6500, y: 0)
        tempAndTint.targetNeutral = CIVector(x: 4500, y: 0)
        
        guard let tempOutput = tempAndTint.outputImage else { return nil }
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = tempOutput
        colorControls.saturation = 1.1
        
        return colorControls.outputImage
    }
    
    private func applyCoolFilter(to image: CIImage) -> CIImage? {
        let tempAndTint = CIFilter.temperatureAndTint()
        tempAndTint.inputImage = image
        tempAndTint.neutral = CIVector(x: 6500, y: 0)
        tempAndTint.targetNeutral = CIVector(x: 9000, y: 0)
        
        guard let tempOutput = tempAndTint.outputImage else { return nil }
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = tempOutput
        colorControls.saturation = 0.9
        
        return colorControls.outputImage
    }
    
    private func applyFadeFilter(to image: CIImage) -> CIImage? {
        let fade = CIFilter.photoEffectFade()
        fade.inputImage = image
        return fade.outputImage
    }
    
    private func applyVividFilter(to image: CIImage) -> CIImage? {
        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = image
        vibrance.amount = 0.5
        
        guard let vibranceOutput = vibrance.outputImage else { return nil }
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = vibranceOutput
        colorControls.saturation = 1.3
        colorControls.contrast = 1.1
        
        return colorControls.outputImage
    }
    
    // MARK: - Preview Generation
    func generateFilterPreviews(for image: UIImage, size: CGSize = CGSize(width: 80, height: 80)) -> [PhotoFilter: UIImage] {
        var previews: [PhotoFilter: UIImage] = [:]
        
        // Resize image for faster preview generation
        let resizedImage = resizeImage(image, to: size)
        
        for filter in PhotoFilter.allCases {
            previews[filter] = applyFilter(filter, to: resizedImage)
        }
        
        return previews
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }
}
