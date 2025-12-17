import SwiftUI

struct EventThumbnail: View {
    let title: String
    let coverUrl: String?
    
    var body: some View {
        ZStack {
            if let coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [FilmRollTheme.inputBackground, FilmRollTheme.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Text(initial)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(FilmRollTheme.secondaryText.opacity(0.7))
        }
    }
    
    private var initial: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first { return String(first).uppercased() }
        return "?"
    }
}

#Preview {
    VStack(spacing: 16) {
        EventThumbnail(title: "Summer Bash", coverUrl: nil)
            .frame(width: 80, height: 80)
            .cornerRadius(12)
        EventThumbnail(title: "Beach Day", coverUrl: "https://picsum.photos/seed/thumbnail/200/200")
            .frame(width: 80, height: 80)
            .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemBackground))
}
