import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(FilmRollTheme.buttonBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusPill)
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to activate")
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(FilmRollTheme.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                    .stroke(FilmRollTheme.divider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Accent Button
struct AccentButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(FilmRollTheme.accent)
            .cornerRadius(FilmRollTheme.cornerRadiusPill)
        }
    }
}

// MARK: - Destructive Button
struct DestructiveButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(FilmRollTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(FilmRollTheme.accentLight)
            .cornerRadius(FilmRollTheme.cornerRadiusPill)
        }
    }
}

// MARK: - Text Field
struct FilmTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var helperText: String? = nil
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
            
            HStack {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
                
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(FilmRollTheme.inputBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusMedium)
            
            if let helper = helperText {
                Text(helper)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
    }
}


// MARK: - Social Sign In Button
struct SocialSignInButton: View {
    enum IconType {
        case system
        case google
        case apple
    }
    
    let title: String
    let icon: String
    let iconType: IconType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Group {
                    switch iconType {
                    case .system:
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    case .google:
                        GoogleIcon()
                            .frame(width: 18, height: 18)
                    case .apple:
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    }
                }
                .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                    .stroke(FilmRollTheme.divider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Google Icon (Custom drawn)
struct GoogleIcon: View {
    var body: some View {
        ZStack {
            // Google "G" logo colors
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                
                ZStack {
                    // Blue arc (right)
                    Circle()
                        .trim(from: 0.0, to: 0.25)
                        .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), lineWidth: size * 0.2)
                        .rotationEffect(.degrees(-45))
                    
                    // Green arc (bottom)
                    Circle()
                        .trim(from: 0.25, to: 0.5)
                        .stroke(Color(red: 52/255, green: 168/255, blue: 83/255), lineWidth: size * 0.2)
                        .rotationEffect(.degrees(-45))
                    
                    // Yellow arc (left-bottom)
                    Circle()
                        .trim(from: 0.5, to: 0.75)
                        .stroke(Color(red: 251/255, green: 188/255, blue: 5/255), lineWidth: size * 0.2)
                        .rotationEffect(.degrees(-45))
                    
                    // Red arc (top)
                    Circle()
                        .trim(from: 0.75, to: 0.95)
                        .stroke(Color(red: 234/255, green: 67/255, blue: 53/255), lineWidth: size * 0.2)
                        .rotationEffect(.degrees(-45))
                    
                    // Blue horizontal bar
                    Rectangle()
                        .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
                        .frame(width: size * 0.5, height: size * 0.2)
                        .offset(x: size * 0.15)
                }
                .frame(width: size * 0.8, height: size * 0.8)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}
