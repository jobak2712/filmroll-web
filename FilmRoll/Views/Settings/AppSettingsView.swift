import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showClearCacheConfirm = false
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance Section
                        SettingsSection(title: "Appearance") {
                            SettingsToggleRow(
                                icon: "moon.fill",
                                iconColor: .purple,
                                title: "Dark Mode",
                                subtitle: "Switch between light and dark theme",
                                isOn: Binding(
                                    get: { settingsManager.isDarkMode },
                                    set: { settingsManager.isDarkMode = $0 }
                                )
                            )
                        }

                        // Notifications Section
                        SettingsSection(title: "Notifications") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: FilmRollTheme.accent,
                                title: "Push Notifications",
                                subtitle: "Get notified when photos are revealed",
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

                            Divider().padding(.leading, 52)

                            SettingsToggleRow(
                                icon: "envelope.fill",
                                iconColor: .blue,
                                title: "Email Notifications",
                                subtitle: "Receive event updates via email",
                                isOn: .constant(true)
                            )
                        }

                        // Storage Section
                        SettingsSection(title: "Storage") {
                            SettingsActionRow(
                                icon: "trash.circle.fill",
                                iconColor: .red,
                                title: "Clear Cache",
                                subtitle: "Free up space by clearing cached images"
                            ) {
                                showClearCacheConfirm = true
                            }

                            Divider().padding(.leading, 52)

                            SettingsInfoRow(
                                icon: "internaldrive.fill",
                                iconColor: .gray,
                                title: "Cache Size",
                                value: formatCacheSize()
                            )
                        }

                        // About Section
                        SettingsSection(title: "About") {
                            SettingsInfoRow(
                                icon: "info.circle.fill",
                                iconColor: .blue,
                                title: "Version",
                                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                            )

                            Divider().padding(.leading, 52)

                            SettingsLinkRow(
                                icon: "doc.text.fill",
                                iconColor: FilmRollTheme.primaryText,
                                title: "Terms of Service"
                            ) {
                                if let url = URL(string: "https://filmroll.app/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }

                            Divider().padding(.leading, 52)

                            SettingsLinkRow(
                                icon: "hand.raised.fill",
                                iconColor: FilmRollTheme.primaryText,
                                title: "Privacy Policy"
                            ) {
                                if let url = URL(string: "https://filmroll.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }

                            Divider().padding(.leading, 52)

                            SettingsLinkRow(
                                icon: "questionmark.circle.fill",
                                iconColor: .green,
                                title: "Help & Support"
                            ) {
                                if let url = URL(string: "https://filmroll.app/support") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        // System Settings Link
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "gear")
                                    .font(.system(size: 16))
                                    .foregroundColor(FilmRollTheme.secondaryText)

                                Text("Open System Settings")
                                    .font(.system(size: 15))
                                    .foregroundColor(FilmRollTheme.secondaryText)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(FilmRollTheme.secondaryText)
                            }
                            .padding(16)
                            .background(FilmRollTheme.cardBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FilmRollTheme.accent)
                    .fontWeight(.medium)
                }
            }
            .alert("Clear Cache", isPresented: $showClearCacheConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                    toastMessage = "Cache cleared successfully"
                    showToast = true
                }
            } message: {
                Text("This will clear all cached images. Your photos and account data will not be affected.")
            }
            .toast(isPresented: $showToast, message: toastMessage, type: .success)
        }
    }

    private func formatCacheSize() -> String {
        let cacheSize = URLCache.shared.currentDiskUsage
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(cacheSize))
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(FilmRollTheme.secondaryText)
                .textCase(.uppercase)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                content
            }
            .background(FilmRollTheme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
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

// MARK: - Settings Action Row
struct SettingsActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(FilmRollTheme.primaryText)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(16)
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(FilmRollTheme.secondaryText)
        }
        .padding(16)
    }
}

// MARK: - Settings Link Row
struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(16)
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(SettingsManager.shared)
}
