import SwiftUI

struct HostHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @State private var showCreateEvent = false
    @State private var selectedEvent: EventWithStats?
    @State private var showProfileMenu = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        NavigationStack {
            ZStack {
                FilmRollTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Films")
                                .font(.custom("PlayfairDisplay-Bold", size: 32))
                                .foregroundColor(FilmRollTheme.primaryText)
                            
                            Text("Capture the moments that matter")
                                .font(.system(size: 14))
                                .foregroundColor(FilmRollTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Profile Button
                        Button(action: {
                            showProfileMenu = true
                        }) {
                            Circle()
                                .fill(FilmRollTheme.cardBackground)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "person")
                                        .font(.system(size: 18))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Stats Cards
                            HStack(spacing: 12) {
                                // Active Rolls Card
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ACTIVE ROLLS")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack {
                                        Text("\(eventViewModel.activeRollsCount)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding(16)
                                .background(FilmRollTheme.buttonBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                                
                                // Total Shots Card
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TOTAL SHOTS")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                    
                                    Text("\(eventViewModel.totalShotsCount)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(FilmRollTheme.cardBackground)
                                .cornerRadius(FilmRollTheme.cornerRadiusLarge)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            }
                            .padding(.horizontal, 24)
                            
                            // Loading State
                            if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                                VStack(spacing: 16) {
                                    ProgressView()
                                    Text("Loading your films...")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                }
                                .padding(.vertical, 60)
                            }
                            // Events List
                            else if !eventViewModel.events.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(eventViewModel.events) { eventWithStats in
                                        EventCard(event: eventWithStats) {
                                            selectedEvent = eventWithStats
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            // Empty State
                            else {
                                VStack(spacing: 16) {
                                    Image(systemName: "film")
                                        .font(.system(size: 48))
                                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.5))
                                    
                                    Text("No films yet")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(FilmRollTheme.primaryText)
                                    
                                    Text("Tap the button below to start capturing moments")
                                        .font(.system(size: 14))
                                        .foregroundColor(FilmRollTheme.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 60)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .refreshable {
                        if let userId = authViewModel.currentUser?.id {
                            await eventViewModel.loadEvents(hostId: userId)
                        }
                    }
                    
                    // Create Film Button
                    PrimaryButton("Create Film", icon: "camera") {
                        showCreateEvent = true
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(item: $selectedEvent) { eventWithStats in
                EventDashboardView(eventId: eventWithStats.event.id)
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(onEventCreated: { event in
                    // Refresh events list
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await eventViewModel.loadEvents(hostId: userId)
                        }
                    }
                    toastMessage = "Film created! Share the QR code to invite guests."
                    toastType = .success
                    showToast = true
                })
            }
            .sheet(isPresented: $showProfileMenu) {
                ProfileMenuView()
                    .environmentObject(authViewModel)
            }
            .toast(isPresented: $showToast, message: toastMessage, type: toastType)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await eventViewModel.loadEvents(hostId: userId)
                }
            }
        }
    }
}
