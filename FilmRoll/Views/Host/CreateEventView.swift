import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    var onEventCreated: ((Event) -> Void)?
    
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .error
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(FilmRollTheme.cardBackground)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                        }
                    }
                    
                    Text("Create New Film")
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Quick Templates
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Start")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    QuickTemplateButton(icon: "🎂", title: "Birthday") {
                                        eventViewModel.title = "Birthday Party"
                                        eventViewModel.shotLimitPerGuest = 24
                                        eventViewModel.revealModeIndex = 1
                                    }
                                    QuickTemplateButton(icon: "💒", title: "Wedding") {
                                        eventViewModel.title = "Wedding Reception"
                                        eventViewModel.shotLimitPerGuest = 36
                                        eventViewModel.participantCap = 100
                                        eventViewModel.revealModeIndex = 1
                                    }
                                    QuickTemplateButton(icon: "🎉", title: "Party") {
                                        eventViewModel.title = "Party"
                                        eventViewModel.shotLimitPerGuest = 24
                                        eventViewModel.revealModeIndex = 1
                                    }
                                    QuickTemplateButton(icon: "🏢", title: "Corporate") {
                                        eventViewModel.title = "Team Event"
                                        eventViewModel.shotLimitPerGuest = 12
                                        eventViewModel.participantCap = 50
                                        eventViewModel.revealModeIndex = 0
                                    }
                                }
                            }
                        }
                        
                        // Event Title
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Event Title")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                
                                Text("*")
                                    .foregroundColor(FilmRollTheme.accent)
                                
                                Spacer()
                                
                                Text("\(eventViewModel.title.count)/50")
                                    .font(.system(size: 12))
                                    .foregroundColor(eventViewModel.title.count > 50 ? FilmRollTheme.accent : FilmRollTheme.secondaryText)
                            }
                            
                            TextField("e.g., Sarah's Birthday Party", text: $eventViewModel.title)
                                .font(.system(size: 16))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 4)
                                .onChange(of: eventViewModel.title) { _, newValue in
                                    if newValue.count > 50 {
                                        eventViewModel.title = String(newValue.prefix(50))
                                    }
                                }
                            
                            Divider()
                                .background(FilmRollTheme.divider)
                        }

                        // Event Description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Event Description")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                
                                Spacer()
                                
                                Text("\(eventViewModel.description.count)/200")
                                    .font(.system(size: 12))
                                    .foregroundColor(eventViewModel.description.count > 200 ? FilmRollTheme.accent : FilmRollTheme.secondaryText)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if eventViewModel.description.isEmpty {
                                    Text("Tell guests what this film is about...")
                                        .font(.system(size: 16))
                                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.6))
                                        .padding(.top, 8)
                                        .padding(.horizontal, 4)
                                }
                                
                                TextEditor(text: $eventViewModel.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .onChange(of: eventViewModel.description) { _, newValue in
                                        if newValue.count > 200 {
                                            eventViewModel.description = String(newValue.prefix(200))
                                        }
                                    }
                            }
                            
                            Divider()
                                .background(FilmRollTheme.divider)
                        }
                        
                        // Event Date
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event Date & Time")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            DatePicker(
                                "",
                                selection: $eventViewModel.eventDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(FilmRollTheme.accent)
                            
                            Text("When is your event happening?")
                                .font(.system(size: 12))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        
                        // Photo Limit Per Guest
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos Per Guest")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            HStack {
                                // Minus Button
                                Button(action: {
                                    if eventViewModel.shotLimitPerGuest > 1 {
                                        eventViewModel.shotLimitPerGuest -= 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(FilmRollTheme.buttonBackground)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(eventViewModel.shotLimitPerGuest)")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .frame(minWidth: 60)
                                
                                Spacer()
                                
                                // Plus Button
                                Button(action: {
                                    if eventViewModel.shotLimitPerGuest < 99 {
                                        eventViewModel.shotLimitPerGuest += 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(FilmRollTheme.buttonBackground)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Text("Each guest can take up to this many photos")
                                .font(.system(size: 12))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }

                        
                        // Participant Cap
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Participant Cap")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            HStack {
                                // Minus Button
                                Button(action: {
                                    if eventViewModel.participantCap > 1 {
                                        eventViewModel.participantCap -= 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(FilmRollTheme.buttonBackground)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(eventViewModel.participantCap)")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .frame(minWidth: 60)
                                
                                Spacer()
                                
                                // Plus Button
                                Button(action: {
                                    if eventViewModel.participantCap < 999 {
                                        eventViewModel.participantCap += 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(FilmRollTheme.buttonBackground)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Text("Maximum number of guests who can join")
                                .font(.system(size: 12))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        
                        // Reveal Mode with better explanation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reveal Mode")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                
                                // Info tooltip
                                Button(action: {
                                    toastMessage = "Delayed reveal creates anticipation - like developing film! Photos stay hidden until the reveal time."
                                    toastType = .info
                                    showToast = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                            }
                            
                            // Custom Segmented Control with descriptions
                            VStack(spacing: 12) {
                                HStack(spacing: 0) {
                                    // Instant Option
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            eventViewModel.revealModeIndex = 0
                                        }
                                        HapticFeedback.selection()
                                    }) {
                                        Text("Instant")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(eventViewModel.revealModeIndex == 0 ? .white : FilmRollTheme.primaryText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .fill(eventViewModel.revealModeIndex == 0 ? FilmRollTheme.buttonBackground : Color.clear)
                                            )
                                    }
                                    
                                    // Delayed Option
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            eventViewModel.revealModeIndex = 1
                                        }
                                        HapticFeedback.selection()
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("Delayed")
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 10))
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(eventViewModel.revealModeIndex == 1 ? .white : FilmRollTheme.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(eventViewModel.revealModeIndex == 1 ? FilmRollTheme.buttonBackground : Color.clear)
                                        )
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(FilmRollTheme.cardBackground)
                                )
                                
                                // Mode description
                                HStack(spacing: 8) {
                                    Image(systemName: eventViewModel.revealModeIndex == 0 ? "eye" : "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.accent)
                                    
                                    Text(eventViewModel.revealModeIndex == 0 
                                         ? "Photos visible immediately after capture" 
                                         : "Photos hidden until reveal time - like developing film!")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(FilmRollTheme.accentLight)
                                .cornerRadius(8)
                            }
                        }

                        
                        // Reveal Time (if delayed)
                        if eventViewModel.revealModeIndex == 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reveal Time")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                
                                DatePicker(
                                    "",
                                    selection: $eventViewModel.revealTime,
                                    in: eventViewModel.eventDate...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(FilmRollTheme.accent)
                                
                                Text("Photos will be revealed after the event ends")
                                    .font(.system(size: 12))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for button
                }
                
                // Sticky Create Button
                VStack(spacing: 0) {
                    Divider()
                        .background(FilmRollTheme.divider)
                    
                    Button(action: createEvent) {
                        HStack(spacing: 10) {
                            if eventViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "camera")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Create Film")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(FilmRollTheme.buttonBackground)
                        )
                    }
                    .disabled(eventViewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(FilmRollTheme.background)
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: eventViewModel.revealModeIndex)
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func createEvent() {
        // Validate
        guard !eventViewModel.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            toastMessage = "Please enter an event title"
            toastType = .error
            showToast = true
            return
        }
        
        hideKeyboard()
        
        Task {
            if let userId = authViewModel.currentUser?.id {
                if let event = await eventViewModel.createEvent(hostId: userId) {
                    onEventCreated?(event)
                    dismiss()
                } else if let error = eventViewModel.errorMessage {
                    toastMessage = error
                    toastType = .error
                    showToast = true
                    eventViewModel.clearMessages()
                }
            } else {
                toastMessage = "Please sign in to create an event"
                toastType = .error
                showToast = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Quick Template Button
struct QuickTemplateButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticFeedback.selection()
        }) {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
            }
            .frame(width: 72, height: 72)
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}
