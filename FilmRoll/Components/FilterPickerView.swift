import SwiftUI

// MARK: - Filter Picker View
struct FilterPickerView: View {
    @Binding var selectedFilter: PhotoFilter
    let previewImage: UIImage?
    @State private var filterPreviews: [PhotoFilter: UIImage] = [:]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PhotoFilter.allCases) { filter in
                    FilterThumbnail(
                        filter: filter,
                        previewImage: filterPreviews[filter] ?? previewImage,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
        .onAppear {
            generatePreviews()
        }
        .onChange(of: previewImage) { _, _ in
            generatePreviews()
        }
    }
    
    private func generatePreviews() {
        guard let image = previewImage else { return }
        
        Task.detached(priority: .userInitiated) {
            let previews = PhotoFilterService.shared.generateFilterPreviews(for: image)
            await MainActor.run {
                filterPreviews = previews
            }
        }
    }
}

// MARK: - Filter Thumbnail
struct FilterThumbnail: View {
    let filter: PhotoFilter
    let previewImage: UIImage?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Preview Image
                ZStack {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: filter.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? FilmRollTheme.accent : Color.clear, lineWidth: 2)
                )
                
                // Filter Name
                Text(filter.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? FilmRollTheme.accent : .white.opacity(0.8))
            }
        }
    }
}

// MARK: - Compact Filter Strip (for camera view)
struct CompactFilterStrip: View {
    @Binding var selectedFilter: PhotoFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PhotoFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                        HapticFeedback.selection()
                    }) {
                        VStack(spacing: 4) {
                            // Filter preview circle with color hint
                            ZStack {
                                Circle()
                                    .fill(filterPreviewColor(filter))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: filter.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
                                    .stroke(selectedFilter == filter ? FilmRollTheme.accent : Color.clear, lineWidth: 2)
                            )
                            
                            Text(filter.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private func filterPreviewColor(_ filter: PhotoFilter) -> Color {
        switch filter {
        case .none: return Color.gray.opacity(0.5)
        case .vintage: return Color(red: 0.6, green: 0.5, blue: 0.4)
        case .disposable: return Color(red: 0.7, green: 0.6, blue: 0.5)
        case .blackWhite: return Color.gray
        case .warm: return Color(red: 0.8, green: 0.5, blue: 0.3)
        case .cool: return Color(red: 0.4, green: 0.6, blue: 0.8)
        case .fade: return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .vivid: return Color(red: 0.9, green: 0.4, blue: 0.5)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            CompactFilterStrip(selectedFilter: .constant(.vintage))
                .padding(.bottom, 20)
        }
    }
}
