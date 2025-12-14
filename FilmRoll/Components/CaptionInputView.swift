import SwiftUI

// MARK: - Caption Input View (for camera)
struct CaptionInputView: View {
    @Binding var caption: String
    @Binding var isEditing: Bool
    let maxLength: Int = 100
    
    var body: some View {
        VStack(spacing: 8) {
            if isEditing {
                // Expanded input
                VStack(spacing: 8) {
                    TextField("Add a caption...", text: $caption)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .onChange(of: caption) { _, newValue in
                            if newValue.count > maxLength {
                                caption = String(newValue.prefix(maxLength))
                            }
                        }
                    
                    HStack {
                        Text("\(caption.count)/\(maxLength)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Button("Done") {
                            withAnimation {
                                isEditing = false
                            }
                            hideKeyboard()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FilmRollTheme.accent)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
            } else {
                // Collapsed button
                Button(action: {
                    withAnimation {
                        isEditing = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: caption.isEmpty ? "text.bubble" : "text.bubble.fill")
                            .font(.system(size: 14))
                        
                        Text(caption.isEmpty ? "Add caption" : caption)
                            .font(.system(size: 14))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Caption Overlay (displayed on photo)
struct CaptionOverlay: View {
    let caption: String
    let authorName: String?
    
    var body: some View {
        if !caption.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                if let author = authorName {
                    Text(author)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Photo Info Overlay (caption + metadata)
struct PhotoInfoOverlay: View {
    let caption: String?
    let authorName: String?
    let timestamp: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let author = authorName {
                HStack(spacing: 6) {
                    Circle()
                        .fill(FilmRollTheme.accent)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(author.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    Text(author)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let time = timestamp {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text(timeAgo(from: time))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            PhotoInfoOverlay(
                caption: "Best night ever! 🎉",
                authorName: "Sarah",
                timestamp: Date().addingTimeInterval(-3600)
            )
        }
    }
}
