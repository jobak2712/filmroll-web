import SwiftUI
import PhotosUI

struct ProfileMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showImagePicker = false
    @State private var showEditName = false
    @State private var showEditPhone = false
    @State private var showPrivacySettings = false
    @State private var showChangePassword = false
    @State private var showAppSettings = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    // Edit fields
    @State private var editedName = ""
    @State private var editedPhone = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host Profile")
                                .font(.custom("PlayfairDisplay-Bold", size: 28))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            Text("Manage your account details")
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Profile Avatar
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let profileImage = profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    } else {
                                        Circle()
                                            .fill(FilmRollTheme.cardBackground)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Text(avatarInitials)
                                                    .font(.system(size: 32, weight: .semibold))
                                                    .foregroundColor(FilmRollTheme.secondaryText)
                                            )
                                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    // Camera button
                                    Circle()
                                        .fill(FilmRollTheme.accent)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .onChange(of: selectedImage) { _, newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        profileImage = image
                                        settingsManager.saveProfileImage(image)
                                    }
                                }
                            }
                            
                            Text(displayName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                        }
                        .padding(.vertical, 8)
                        
                        // Account Information Section
                        ProfileSection(title: "Account Information") {
                            ProfileInfoRow(
                                icon: "person.fill",
                                title: "Full Name",
                                value: displayName
                            ) {
                                editedName = displayName
                                showEditName = true
                            }
                            
                            Divider().padding(.leading, 48)
                            
                            ProfileInfoRow(
                                icon: "envelope.fill",
                                title: "Email Address",
                                value: authViewModel.currentUser?.email ?? "Not set"
                            ) {
                                // Email typically can't be changed easily
                            }
                            
                            Divider().padding(.leading, 48)
                            
                            ProfileInfoRow(
                                icon: "phone.fill",
                                title: "Phone Number",
                                value: settingsManager.userPhoneNumber.isEmpty ? "Not set" : settingsManager.userPhoneNumber
                            ) {
                                editedPhone = settingsManager.userPhoneNumber
                                showEditPhone = true
                            }
                        }
                        
                        // Hosting Statistics Section
                        ProfileSection(title: "Hosting Statistics") {
                            HStack(spacing: 16) {
                                StatBox(value: "\(settingsManager.totalFilms)", label: "Total Films")
                                StatBox(value: "\(settingsManager.guestsServed)", label: "Guests Served")
                                StatBox(value: String(format: "%.1f", settingsManager.avgRating), label: "Avg Rating")
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Preferences Section
                        ProfileSection(title: "Preferences") {
                            PreferenceToggleRow(
                                icon: "bell.fill",
                                iconColor: FilmRollTheme.accent,
                                title: "Push Notifications",
                                isOn: Binding(
                                    get: { settingsManager.pushNotificationsEnabled },
                                    set: { newValue in
                                        if newValue && settingsManager.notificationPermissionStatus == .denied {
                                            settingsManager.openNotificationSettings()
                                        } else {
                                            settingsManager.pushNotificationsEnabled = newValue
                                        }
                                    }
                                )
                            )
                            
                            Divider().padding(.leading, 48)
                            
                            PreferenceToggleRow(
                                icon: "moon.fill",
                                iconColor: FilmRollTheme.secondaryText,
                                title: "Dark Mode",
                                isOn: Binding(
                                    get: { settingsManager.isDarkMode },
                                    set: { settingsManager.isDarkMode = $0 }
                                )
                            )
                            
                            Divider().padding(.leading, 48)
                            
                            ProfileNavigationRow(
                                icon: "checkmark.shield.fill",
                                iconColor: FilmRollTheme.accent,
                                title: "Privacy Settings"
                            ) {
                                showPrivacySettings = true
                            }
                        }

                        // Account Actions Section
                        ProfileSection(title: "Account Actions") {
                            VStack(spacing: 12) {
                                // Change Password Button
                                Button(action: {
                                    showChangePassword = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 14))
                                        Text("Change Password")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(FilmRollTheme.buttonBackground)
                                    .cornerRadius(FilmRollTheme.cornerRadiusPill)
                                }
                                
                                // Sign Out Button
                                Button(action: {
                                    showSignOutConfirmation = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 14))
                                        Text("Sign Out")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(FilmRollTheme.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(FilmRollTheme.cardBackground)
                                    .cornerRadius(FilmRollTheme.cornerRadiusPill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FilmRollTheme.cornerRadiusPill)
                                            .stroke(FilmRollTheme.divider, lineWidth: 1)
                                    )
                                }
                                
                                // Delete Account Button
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 14))
                                        Text("Delete Account")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(FilmRollTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(FilmRollTheme.accentLight)
                                    .cornerRadius(FilmRollTheme.cornerRadiusPill)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAppSettings = true
                    }) {
                        Circle()
                            .fill(FilmRollTheme.cardBackground)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(FilmRollTheme.primaryText)
                            )
                    }
                }
            }
            .sheet(isPresented: $showAppSettings) {
                AppSettingsView()
                    .environmentObject(settingsManager)
            }
            .onAppear {
                profileImage = settingsManager.getProfileImage()
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await settingsManager.loadUserStats(userId: userId)
                    }
                }
            }
            // Edit Name Sheet
            .sheet(isPresented: $showEditName) {
                EditFieldSheet(
                    title: "Edit Name",
                    placeholder: "Enter your name",
                    text: $editedName,
                    keyboardType: .default
                ) {
                    settingsManager.userDisplayName = editedName
                }
            }
            // Edit Phone Sheet
            .sheet(isPresented: $showEditPhone) {
                EditFieldSheet(
                    title: "Edit Phone Number",
                    placeholder: "+1 (555) 123-4567",
                    text: $editedPhone,
                    keyboardType: .phonePad
                ) {
                    settingsManager.userPhoneNumber = editedPhone
                }
            }
            // Change Password Sheet
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet()
                    .environmentObject(authViewModel)
            }
            // Privacy Settings Sheet
            .sheet(isPresented: $showPrivacySettings) {
                PrivacySettingsSheet()
            }
            // Sign Out Confirmation
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            // Delete Account Confirmation
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        // In production, call API to delete account
                        settingsManager.resetAllSettings()
                        await authViewModel.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
    
    private var displayName: String {
        if !settingsManager.userDisplayName.isEmpty {
            return settingsManager.userDisplayName
        }
        return authViewModel.currentUser?.displayName ?? "User"
    }
    
    private var avatarInitials: String {
        let name = displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}


// MARK: - Profile Section
struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(FilmRollTheme.primaryText)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(FilmRollTheme.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
            .padding(.vertical, 8)
        }
        .disabled(action == nil)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(FilmRollTheme.primaryText)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(FilmRollTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(FilmRollTheme.background)
        .cornerRadius(FilmRollTheme.cornerRadiusMedium)
    }
}

// MARK: - Preference Toggle Row
struct PreferenceToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: FilmRollTheme.accent))
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Profile Navigation Row
struct ProfileNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Edit Field Sheet
struct EditFieldSheet: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .keyboardType(keyboardType)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(FilmRollTheme.cardBackground)
                        .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.secondaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            SecureField("Enter current password", text: $currentPassword)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(FilmRollTheme.cardBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            SecureField("Enter new password", text: $newPassword)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(FilmRollTheme.cardBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(FilmRollTheme.cardBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.destructive)
                        }
                        
                        // Save Button
                        Button(action: changePassword) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Update Password")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(FilmRollTheme.buttonBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusPill)
                        }
                        .disabled(isLoading)
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been successfully updated.")
            }
        }
    }
    
    private func changePassword() {
        errorMessage = nil
        
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "New password must be at least 6 characters"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        // Simulate password change (in production, call API)
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
            showSuccess = true
        }
    }
}

// MARK: - Privacy Settings Sheet
struct PrivacySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shareAnalytics") private var shareAnalytics = true
    @AppStorage("showInSearch") private var showInSearch = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowFaceDetection") private var allowFaceDetection = true
    @AppStorage("autoSavePhotos") private var autoSavePhotos = false
    @State private var showClearCacheConfirm = false
    @State private var showDownloadDataConfirm = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Privacy Policy Link
                        Button(action: {
                            if let url = URL(string: "https://filmroll.app/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16))
                                    .foregroundColor(FilmRollTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    Text("Read our full privacy policy")
                                        .font(.system(size: 12))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                            }
                            .padding(16)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                        }
                        .padding(.horizontal, 24)
                        
                        // Photo Privacy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo Privacy")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                PrivacyToggleRow(
                                    title: "Face Detection",
                                    subtitle: "Allow 'Find My Photos' feature to detect your face",
                                    isOn: $allowFaceDetection
                                )
                                
                                Divider().padding(.leading, 16)
                                
                                PrivacyToggleRow(
                                    title: "Allow Photo Tagging",
                                    subtitle: "Let guests tag you in photos",
                                    isOn: $allowTagging
                                )
                                
                                Divider().padding(.leading, 16)
                                
                                PrivacyToggleRow(
                                    title: "Auto-Save to Camera Roll",
                                    subtitle: "Automatically save your photos when revealed",
                                    isOn: $autoSavePhotos
                                )
                            }
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                            .padding(.horizontal, 24)
                        }
                        
                        // Discovery Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Discovery")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                PrivacyToggleRow(
                                    title: "Show in Search",
                                    subtitle: "Allow others to find your public events",
                                    isOn: $showInSearch
                                )
                            }
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                            .padding(.horizontal, 24)
                        }
                        
                        // Analytics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analytics")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                PrivacyToggleRow(
                                    title: "Share Analytics",
                                    subtitle: "Help improve FilmRoll by sharing anonymous usage data",
                                    isOn: $shareAnalytics
                                )
                            }
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                            .padding(.horizontal, 24)
                        }
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Management")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                PrivacyActionRow(title: "Download My Data", icon: "arrow.down.circle") {
                                    showDownloadDataConfirm = true
                                }
                                
                                Divider().padding(.leading, 16)
                                
                                PrivacyActionRow(title: "Clear Cache", icon: "trash.circle") {
                                    showClearCacheConfirm = true
                                }
                            }
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                            .padding(.horizontal, 24)
                        }
                        
                        // Data Retention Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data Retention")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            Text("Your photos are stored securely and retained for 1 year after the event. You can download or delete your data at any time.")
                                .font(.system(size: 13))
                                .foregroundColor(FilmRollTheme.secondaryText)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(FilmRollTheme.accentLight)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.accent)
                }
            }
            .alert("Clear Cache", isPresented: $showClearCacheConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // Clear cached images
                    URLCache.shared.removeAllCachedResponses()
                    toastMessage = "Cache cleared successfully"
                    showToast = true
                }
            } message: {
                Text("This will clear all cached images and data. Your account and photos will not be affected.")
            }
            .alert("Download My Data", isPresented: $showDownloadDataConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Request Download") {
                    // In production, trigger data export
                    toastMessage = "Data export requested. You'll receive an email when ready."
                    showToast = true
                }
            } message: {
                Text("We'll prepare a download of all your data including photos, events, and account information.")
            }
            .toast(isPresented: $showToast, message: toastMessage, type: .success)
        }
    }
}

struct PrivacyToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: FilmRollTheme.accent))
                .labelsHidden()
        }
        .padding(16)
    }
}

struct PrivacyActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(FilmRollTheme.accent)
            }
            .padding(16)
        }
    }
}

#Preview {
    ProfileMenuView()
        .environmentObject(AuthViewModel())
}
