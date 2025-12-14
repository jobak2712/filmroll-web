import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    let onPermissionGranted: () -> Void
    let onCancel: () -> Void
    
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Camera Icon
                ZStack {
                    Circle()
                        .fill(FilmRollTheme.accentLight)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(FilmRollTheme.accent)
                }
                
                // Title and Description
                VStack(spacing: 12) {
                    Text("Camera Access")
                        .font(.custom("PlayfairDisplay-Bold", size: 28))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Text("FilmRoll needs access to your camera to capture photos for this event. Your photos will be shared with other guests after the reveal.")
                        .font(.system(size: 16))
                        .foregroundColor(FilmRollTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    PermissionFeatureRow(
                        icon: "camera.viewfinder",
                        title: "Take Photos",
                        description: "Capture moments at the event"
                    )
                    
                    PermissionFeatureRow(
                        icon: "photo.stack",
                        title: "Share Memories",
                        description: "Your photos join the group gallery"
                    )
                    
                    PermissionFeatureRow(
                        icon: "lock.shield",
                        title: "Private Until Reveal",
                        description: "Photos stay hidden until the host reveals them"
                    )
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: requestPermission) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                            Text("Enable Camera")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(FilmRollTheme.buttonBackground)
                        .cornerRadius(FilmRollTheme.cornerRadiusPill)
                    }
                    
                    Button(action: onCancel) {
                        Text("Maybe Later")
                            .font(.system(size: 14))
                            .foregroundColor(FilmRollTheme.secondaryText)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    onPermissionGranted()
                } else {
                    // Permission denied - still proceed but camera view will show error
                    onPermissionGranted()
                }
            }
        }
    }
}

// MARK: - Permission Feature Row
struct PermissionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(FilmRollTheme.cardBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(FilmRollTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
    }
}

#Preview {
    CameraPermissionView(
        onPermissionGranted: {},
        onCancel: {}
    )
}
