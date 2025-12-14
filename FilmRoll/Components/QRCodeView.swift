import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let code: String
    let size: CGFloat
    
    var body: some View {
        if let qrImage = generateQRCode(from: code) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Rectangle()
                .fill(FilmRollTheme.inputBackground)
                .frame(width: size, height: size)
                .overlay(
                    Text("QR Code")
                        .foregroundColor(FilmRollTheme.secondaryText)
                )
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = size / outputImage.extent.size.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - QR Card
struct QRCard: View {
    let joinCode: String
    let joinUrl: String
    let onCopyLink: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            QRCodeView(code: joinUrl, size: 180)
                .padding(20)
            
            VStack(spacing: 4) {
                Text("SCAN TO")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
                Text("JOIN")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FilmRollTheme.primaryText)
                Text("filmroll.app/join/\(joinCode)")
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            Button(action: onCopyLink) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                    Text("Copy Link")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(FilmRollTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(FilmRollTheme.inputBackground)
                .cornerRadius(FilmRollTheme.cornerRadiusPill)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
