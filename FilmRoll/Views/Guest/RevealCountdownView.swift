import SwiftUI
import Combine

struct RevealCountdownView: View {
    @ObservedObject var viewModel: GuestViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(FilmRollTheme.cardBackground)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Text("PHOTOS LOCKED")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FilmRollTheme.secondaryText)
                            
                            if let event = viewModel.event {
                                Text(event.title)
                                    .font(.custom("PlayfairDisplay-Bold", size: 28))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                
                                Text("\(viewModel.formatEventDate()) • \(viewModel.formatEventTime())")
                                    .font(.system(size: 14))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Countdown Card
                        CardContainer {
                            VStack(spacing: 20) {
                                // Lock Icon
                                ZStack {
                                    Circle()
                                        .fill(FilmRollTheme.accentLight)
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(FilmRollTheme.accent)
                                    
                                    Circle()
                                        .fill(FilmRollTheme.accent)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 28, y: -28)
                                }
                                
                                Text("PHOTOS UNLOCK IN")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                
                                if let revealTime = viewModel.event?.revealTime {
                                    CountdownView(targetDate: revealTime)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("Photos captured")
                                        .font(.system(size: 13))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                    
                                    Text("\(viewModel.shotsTaken) of \(viewModel.shotLimit)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(FilmRollTheme.inputBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 24)
                        
                        // Explanation Card
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "film")
                                    .font(.system(size: 16))
                                    .foregroundColor(FilmRollTheme.accent)
                                
                                Text("Why are photos hidden?")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                            }
                            
                            Text("Just like developing film, your photos stay hidden until the reveal time. This creates a fun, shared moment when everyone sees the photos together!")
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        // Locked Photo Previews
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                ZStack {
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                                        .fill(FilmRollTheme.inputBackground)
                                        .aspectRatio(1, contentMode: .fit)
                                    
                                    RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusMedium)
                                        .fill(Color.gray.opacity(0.3))
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.canTakePhoto {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera")
                                    Text("Take More Photos (\(viewModel.shotsRemaining) left)")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FilmRollTheme.accent)
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                
                VStack(spacing: 12) {
                    if viewModel.isRevealed {
                        AccentButton("View Photos Now", icon: "eye") {
                            dismiss()
                        }
                    }
                    
                    SecondaryButton("Notify Me When Ready", icon: "bell") {
                        Task {
                            await viewModel.requestRevealNotification()
                            showToastMessage()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if viewModel.isRevealed {
                dismiss()
            }
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
    }
    
    private func showToastMessage() {
        if let success = viewModel.successMessage {
            toastMessage = success
            toastType = .success
            showToast = true
            viewModel.clearMessages()
        } else if let error = viewModel.errorMessage {
            toastMessage = error
            toastType = .error
            showToast = true
            viewModel.clearMessages()
        }
    }
}
