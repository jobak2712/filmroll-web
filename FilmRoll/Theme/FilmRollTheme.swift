import SwiftUI

struct FilmRollTheme {
    // MARK: - Adaptive Colors (Light/Dark Mode)
    static var background: Color {
        Color("Background", bundle: nil)
    }
    static var cardBackground: Color {
        Color("CardBackground", bundle: nil)
    }
    static var primaryText: Color {
        Color("PrimaryText", bundle: nil)
    }
    static var secondaryText: Color {
        Color("SecondaryText", bundle: nil)
    }
    static var divider: Color {
        Color("Divider", bundle: nil)
    }
    static var inputBackground: Color {
        Color("InputBackground", bundle: nil)
    }
    static var buttonBackground: Color {
        Color("ButtonBackground", bundle: nil)
    }
    
    // MARK: - Static Colors (Same in both modes)
    static let accent = Color(hex: "E85C2B")
    static let accentLight = Color(hex: "FFF0EB")
    static let destructive = Color(hex: "DC3545")
    static let destructiveLight = Color(hex: "FFEBEE")
    
    // MARK: - Fallback Colors (Used if Color Assets not found)
    static let backgroundLight = Color(hex: "F5F3EF")
    static let backgroundDark = Color(hex: "1A1A1A")
    static let cardBackgroundLight = Color(hex: "FFFFFF")
    static let cardBackgroundDark = Color(hex: "2C2C2C")
    static let primaryTextLight = Color(hex: "1A1A1A")
    static let primaryTextDark = Color(hex: "F5F3EF")
    static let secondaryTextLight = Color(hex: "6B6B6B")
    static let secondaryTextDark = Color(hex: "A0A0A0")
    static let dividerLight = Color(hex: "E5E5E5")
    static let dividerDark = Color(hex: "3C3C3C")
    static let inputBackgroundLight = Color(hex: "F8F8F8")
    static let inputBackgroundDark = Color(hex: "252525")
    
    // MARK: - Typography
    static let titleFont = Font.custom("PlayfairDisplay-Bold", size: 28)
    static let headlineFont = Font.custom("PlayfairDisplay-SemiBold", size: 22)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .medium)
    static let labelFont = Font.system(size: 14, weight: .medium)
    
    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusPill: CGFloat = 24
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
