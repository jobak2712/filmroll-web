import SwiftUI

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(FilmRollTheme.buttonBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        FilmRollTheme.inputBackground,
                        FilmRollTheme.divider,
                        FilmRollTheme.inputBackground
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(FilmRollTheme.secondaryText.opacity(0.5))
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FilmRollTheme.primaryText)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(FilmRollTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FilmRollTheme.accent)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Upload Progress
struct UploadProgressView: View {
    let progress: Double
    let fileName: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(FilmRollTheme.accent)
                
                Text("Uploading...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FilmRollTheme.inputBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FilmRollTheme.accent)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text(fileName)
                .font(.system(size: 12))
                .foregroundColor(FilmRollTheme.secondaryText)
                .lineLimit(1)
        }
        .padding(16)
        .background(FilmRollTheme.cardBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Toast Message
struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return FilmRollTheme.destructive
            case .info: return FilmRollTheme.accent
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FilmRollTheme.buttonBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusPill)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Modifier for Toast
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    ToastView(message: message, type: type)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: isPresented)
    }
}

extension View {
    // M01: Increased default duration, auto-adjust for long messages
    func toast(isPresented: Binding<Bool>, message: String, type: ToastView.ToastType = .info, duration: Double? = nil) -> some View {
        // Calculate duration based on message length (min 3s, +1s per 50 chars)
        let calculatedDuration = duration ?? max(3.0, Double(message.count) / 50.0 + 2.0)
        return modifier(ToastModifier(isPresented: isPresented, message: message, type: type, duration: calculatedDuration))
    }
}
