import SwiftUI

// Model used by OnboardingView
struct OnboardingPage {
    let emoji: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "📸",
            title: "Capture\nTogether",
            subtitle: "Everyone at your event takes photos on their phone. One shared album, countless perspectives.",
            gradient: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")]
        ),
        OnboardingPage(
            emoji: "🎞️",
            title: "Wait for\nthe Magic",
            subtitle: "Like real film, photos stay hidden until reveal time. No peeking, no filters, just real moments.",
            gradient: [Color(hex: "4ECDC4"), Color(hex: "44A08D")]
        ),
        OnboardingPage(
            emoji: "✨",
            title: "Reveal\nTogether",
            subtitle: "When the timer hits zero, everyone sees everything at once. The anticipation makes it special.",
            gradient: [Color(hex: "667EEA"), Color(hex: "764BA2")]
        ),
        OnboardingPage(
            emoji: "💫",
            title: "Keep\nForever",
            subtitle: "Download, share, and relive your favorite moments. Your memories, beautifully preserved.",
            gradient: [Color(hex: "F093FB"), Color(hex: "F5576C")]
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // Floating circles decoration
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: -50)
                    .blur(radius: 2)
                
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 200)
                    .blur(radius: 2)
                
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: geo.size.width - 120, y: 100)
            }
            
            VStack(spacing: 0) {
                // Top bar with skip
                HStack {
                    // Page counter
                    Text("\(currentPage + 1)/\(pages.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Main content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom section
                VStack(spacing: 24) {
                    // Progress dots
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(.white.opacity(currentPage == index ? 1 : 0.4))
                                .frame(width: currentPage == index ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button(action: nextAction) {
                        HStack(spacing: 12) {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Let's Go!")
                                .font(.system(size: 17, weight: .bold))
                            
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(pages[currentPage].gradient[0])
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(.white)
                        .cornerRadius(29)
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateContent = true
        }
    }
    
    private func nextAction() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4)) {
                currentPage += 1
            }
            HapticFeedback.light()
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        HapticFeedback.success()
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation(.easeOut(duration: 0.3)) {
            hasSeenOnboarding = true
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    
    @State private var emojiScale: CGFloat = 0.5
    @State private var emojiRotation: Double = -30
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Large emoji with animation
            Text(page.emoji)
                .font(.system(size: 120))
                .scaleEffect(emojiScale)
                .rotationEffect(.degrees(emojiRotation))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            Spacer()
                .frame(height: 48)
            
            // Title
            Text(page.title)
                .font(.system(size: 48, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(-4)
                .opacity(textOpacity)
                .offset(y: textOffset)
            
            Spacer()
                .frame(height: 20)
            
            // Subtitle
            Text(page.subtitle)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(textOpacity)
                .offset(y: textOffset)
            
            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                animateIn()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isActive {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            emojiScale = 1.0
            emojiRotation = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            textOpacity = 1
            textOffset = 0
        }
    }
    
    private func resetAnimation() {
        emojiScale = 0.5
        emojiRotation = -30
        textOpacity = 0
        textOffset = 30
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}

