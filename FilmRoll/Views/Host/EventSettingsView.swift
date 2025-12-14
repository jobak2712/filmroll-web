import SwiftUI

struct EventSettingsView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventViewModel = EventViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
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
                    
                    Text("Event Settings")
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Event Configuration Card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Event Configuration")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                            
                            // Reveal Time
                            if event.revealMode == .delayed {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Reveal Time")
                                        .font(.system(size: 13))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                    
                                    HStack {
                                        Text(formatRevealTime())
                                            .font(.system(size: 15))
                                            .foregroundColor(FilmRollTheme.primaryText)
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $eventViewModel.settingsRevealTime, displayedComponents: [.date, .hourAndMinute])
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .tint(FilmRollTheme.accent)
                                    }
                                    .padding(14)
                                    .background(FilmRollTheme.inputBackground)
                                    .cornerRadius(10)
                                    
                                    Text("Photos will be revealed to all participants at this time")
                                        .font(.system(size: 11))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                        .padding(.top, 4)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }

                            
                            // Shot Limit per Person
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Shot Limit per Person")
                                    .font(.system(size: 13))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                
                                TextField("", value: $eventViewModel.settingsShotLimit, format: .number)
                                    .font(.system(size: 15))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .keyboardType(.numberPad)
                                    .padding(14)
                                    .background(FilmRollTheme.inputBackground)
                                    .cornerRadius(10)
                                
                                Text("Maximum number of photos each participant can take")
                                    .font(.system(size: 11))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            
                            // Participant Cap
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Participant Cap")
                                    .font(.system(size: 13))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                
                                TextField("", value: $eventViewModel.settingsParticipantCap, format: .number)
                                    .font(.system(size: 15))
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .keyboardType(.numberPad)
                                    .padding(14)
                                    .background(FilmRollTheme.inputBackground)
                                    .cornerRadius(10)
                                
                                Text("Maximum number of people who can join this event")
                                    .font(.system(size: 11))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Event Controls Card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Event Controls")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 12)
                            
                            // Lock Event Toggle
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(FilmRollTheme.accentLight)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.accent)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Lock Event")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Text("Prevent new participants from joining")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $eventViewModel.settingsIsLocked)
                                    .toggleStyle(SwitchToggleStyle(tint: FilmRollTheme.accent))
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            
                            Divider()
                                .padding(.leading, 68)
                            
                            // Allow New Photos Toggle
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(FilmRollTheme.inputBackground)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Allow New Photos")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Text("Participants can continue taking photos")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $eventViewModel.settingsAllowNewPhotos)
                                    .toggleStyle(SwitchToggleStyle(tint: FilmRollTheme.accent))
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .padding(.bottom, 8)
                        }
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        
                        // Advanced Settings Card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Advanced Settings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 12)
                            
                            // Download All Photos
                            Button(action: {
                                Task {
                                    await eventViewModel.downloadAllPhotos()
                                    showToastMessage()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(FilmRollTheme.buttonBackground)
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Download All Photos")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .padding(.bottom, 8)
                        }
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 100) // Space for buttons
                }

                
                // Bottom Buttons
                VStack(spacing: 12) {
                    // Save Changes Button
                    Button(action: {
                        Task {
                            let success = await eventViewModel.saveSettings()
                            if success {
                                toastMessage = "Settings saved"
                                toastType = .success
                                showToast = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    dismiss()
                                }
                            } else {
                                showToastMessage()
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            if eventViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Text("Save Changes")
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
                    
                    // Delete Event Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Delete Event")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(FilmRollTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(FilmRollTheme.accentLight)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .background(FilmRollTheme.background)
            }
            
            // Download Progress Overlay
            if eventViewModel.isDownloading, let progress = eventViewModel.downloadProgress {
                LoadingOverlay(message: "Downloading \(progress.current) of \(progress.total)...")
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Event", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await eventViewModel.deleteEvent() {
                        dismiss()
                    } else {
                        showToastMessage()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone and all photos will be permanently deleted.")
        }
        .toast(isPresented: $showToast, message: toastMessage, type: toastType)
        .task {
            await eventViewModel.loadEvent(id: event.id)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func formatRevealTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: eventViewModel.settingsRevealTime)
    }
    
    private func showToastMessage() {
        if let success = eventViewModel.successMessage {
            toastMessage = success
            toastType = .success
            showToast = true
            eventViewModel.clearMessages()
        } else if let error = eventViewModel.errorMessage {
            toastMessage = error
            toastType = .error
            showToast = true
            eventViewModel.clearMessages()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
