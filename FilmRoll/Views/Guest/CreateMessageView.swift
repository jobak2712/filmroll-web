import SwiftUI
import AVFoundation

struct CreateMessageView: View {
    let eventId: String
    let participantId: String
    let participantName: String?
    let onMessageCreated: (EventMessage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0 // 0: Polaroid, 1: Voice, 2: Sticker
    
    var body: some View {
        ZStack {
            FilmRollTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Leave a Message")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(FilmRollTheme.primaryText)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Tab Selector
                HStack(spacing: 0) {
                    tabButton(title: "Note", icon: "note.text", index: 0)
                    tabButton(title: "Voice", icon: "mic.fill", index: 1)
                    tabButton(title: "Sticker", icon: "face.smiling", index: 2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Content
                TabView(selection: $selectedTab) {
                    PolaroidNoteView(
                        eventId: eventId,
                        participantId: participantId,
                        participantName: participantName,
                        onSend: { message in
                            onMessageCreated(message)
                            dismiss()
                        }
                    )
                    .tag(0)
                    
                    VoiceNoteView(
                        eventId: eventId,
                        participantId: participantId,
                        participantName: participantName,
                        onSend: { message in
                            onMessageCreated(message)
                            dismiss()
                        }
                    )
                    .tag(1)
                    
                    StickerView(
                        eventId: eventId,
                        participantId: participantId,
                        participantName: participantName,
                        onSend: { message in
                            onMessageCreated(message)
                            dismiss()
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(selectedTab == index ? FilmRollTheme.accent : FilmRollTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selectedTab == index ?
                FilmRollTheme.accentLight :
                Color.clear
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Polaroid Note View
struct PolaroidNoteView: View {
    let eventId: String
    let participantId: String
    let participantName: String?
    let onSend: (EventMessage) -> Void
    
    @State private var noteText = ""
    @State private var selectedColor = PolaroidColor.allColors[0]
    @State private var rotation: Double = Double.random(in: -5...5)
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Polaroid Preview
            VStack(spacing: 0) {
                // Note area
                ZStack {
                    Rectangle()
                        .fill(selectedColor.color)
                    
                    TextEditor(text: $noteText)
                        .font(.custom("Noteworthy-Bold", size: 18))
                        .foregroundColor(.black.opacity(0.8))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(16)
                        .focused($isFocused)
                    
                    if noteText.isEmpty {
                        Text("Write your message...")
                            .font(.custom("Noteworthy-Bold", size: 18))
                            .foregroundColor(.black.opacity(0.3))
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 200)
                
                // Bottom strip
                HStack {
                    if let name = participantName {
                        Text("— \(name)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .frame(width: 280)
            .background(Color.white)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            .rotationEffect(.degrees(rotation))
            .padding(.top, 32)
            
            // Color Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Background Color")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PolaroidColor.allColors) { color in
                            Button(action: {
                                selectedColor = color
                                HapticFeedback.selection()
                            }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColor.id == color.id ?
                                                FilmRollTheme.accent : Color.gray.opacity(0.3),
                                                lineWidth: selectedColor.id == color.id ? 3 : 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Send Button
            Button(action: sendNote) {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                    Text("Send Note")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    FilmRollTheme.secondaryText :
                    FilmRollTheme.primaryText
                )
                .cornerRadius(28)
            }
            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            isFocused = false
        }
    }
    
    private func sendNote() {
        let message = EventMessage(
            id: UUID().uuidString,
            eventId: eventId,
            participantId: participantId,
            participantName: participantName,
            messageType: .polaroidNote,
            content: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            backgroundColor: selectedColor.id,
            rotation: rotation,
            createdAt: Date()
        )
        onSend(message)
        HapticFeedback.success()
    }
}


// MARK: - Voice Note View
struct VoiceNoteView: View {
    let eventId: String
    let participantId: String
    let participantName: String?
    let onSend: (EventMessage) -> Void
    
    @StateObject private var recorder = VoiceRecorderService()
    @State private var hasRecording = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Waveform / Recording Indicator
            ZStack {
                Circle()
                    .fill(recorder.isRecording ? FilmRollTheme.accent.opacity(0.1) : FilmRollTheme.inputBackground)
                    .frame(width: 180, height: 180)
                
                if recorder.isRecording {
                    // Animated rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(FilmRollTheme.accent.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: 180 + CGFloat(i) * 30, height: 180 + CGFloat(i) * 30)
                            .scaleEffect(1 + CGFloat(recorder.audioLevel) * 0.1)
                            .animation(.easeOut(duration: 0.1), value: recorder.audioLevel)
                    }
                }
                
                VStack(spacing: 8) {
                    Image(systemName: recorder.isRecording ? "waveform" : (hasRecording ? "play.fill" : "mic.fill"))
                        .font(.system(size: 48))
                        .foregroundColor(recorder.isRecording ? FilmRollTheme.accent : FilmRollTheme.primaryText)
                    
                    if recorder.isRecording {
                        Text(recorder.formatTime(recorder.recordingTime))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(FilmRollTheme.accent)
                    } else if hasRecording {
                        Text(recorder.formatTime(recorder.recordingTime))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FilmRollTheme.secondaryText)
                    }
                }
            }
            
            // Instructions
            if !recorder.isRecording && !hasRecording {
                Text("Tap and hold to record a voice message\n(up to 30 seconds)")
                    .font(.system(size: 14))
                    .foregroundColor(FilmRollTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Controls
            VStack(spacing: 16) {
                if hasRecording && !recorder.isRecording {
                    // Playback controls
                    HStack(spacing: 24) {
                        Button(action: {
                            recorder.reset()
                            hasRecording = false
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                Text("Delete")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(FilmRollTheme.destructive)
                        }
                        
                        Button(action: {
                            if let url = recorder.recordingURL {
                                if recorder.isPlaying {
                                    recorder.stopPlayback()
                                } else {
                                    recorder.play(url: url)
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(FilmRollTheme.primaryText)
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                _ = await recorder.startRecording()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20))
                                Text("Re-record")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(FilmRollTheme.secondaryText)
                        }
                    }
                } else {
                    // Record button
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(recorder.isRecording ? FilmRollTheme.destructive : FilmRollTheme.accent)
                                .frame(width: 80, height: 80)
                            
                            if recorder.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.1)
                            .onEnded { _ in
                                Task {
                                    _ = await recorder.startRecording()
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { _ in
                                if recorder.isRecording {
                                    _ = recorder.stopRecording()
                                    hasRecording = recorder.recordingURL != nil
                                }
                            }
                    )
                    .onTapGesture {
                        if recorder.isRecording {
                            _ = recorder.stopRecording()
                            hasRecording = recorder.recordingURL != nil
                        } else {
                            Task {
                                _ = await recorder.startRecording()
                            }
                        }
                    }
                }
                
                // Send Button
                if hasRecording && !recorder.isRecording {
                    Button(action: sendVoiceNote) {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                            Text("Send Voice Note")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FilmRollTheme.primaryText)
                        .cornerRadius(28)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }
    
    private func sendVoiceNote() {
        guard let url = recorder.recordingURL else { return }
        
        let message = EventMessage(
            id: UUID().uuidString,
            eventId: eventId,
            participantId: participantId,
            participantName: participantName,
            messageType: .voiceNote,
            content: url.absoluteString,
            backgroundColor: nil,
            rotation: nil,
            createdAt: Date()
        )
        onSend(message)
        HapticFeedback.success()
    }
}

// MARK: - Sticker View
struct StickerView: View {
    let eventId: String
    let participantId: String
    let participantName: String?
    let onSend: (EventMessage) -> Void
    
    @State private var selectedSticker: StickerOption?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Preview
            ZStack {
                Circle()
                    .fill(FilmRollTheme.inputBackground)
                    .frame(width: 120, height: 120)
                
                if let sticker = selectedSticker {
                    Text(sticker.emoji)
                        .font(.system(size: 64))
                } else {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 48))
                        .foregroundColor(FilmRollTheme.secondaryText)
                }
            }
            .padding(.top, 32)
            
            // Sticker Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(StickerOption.allStickers) { sticker in
                        Button(action: {
                            selectedSticker = sticker
                            HapticFeedback.selection()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        selectedSticker?.id == sticker.id ?
                                        FilmRollTheme.accentLight :
                                        FilmRollTheme.cardBackground
                                    )
                                    .frame(height: 70)
                                
                                if selectedSticker?.id == sticker.id {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(FilmRollTheme.accent, lineWidth: 2)
                                }
                                
                                Text(sticker.emoji)
                                    .font(.system(size: 36))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Send Button
            Button(action: sendSticker) {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                    Text("Send Sticker")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedSticker == nil ?
                    FilmRollTheme.secondaryText :
                    FilmRollTheme.primaryText
                )
                .cornerRadius(28)
            }
            .disabled(selectedSticker == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func sendSticker() {
        guard let sticker = selectedSticker else { return }
        
        let message = EventMessage(
            id: UUID().uuidString,
            eventId: eventId,
            participantId: participantId,
            participantName: participantName,
            messageType: .sticker,
            content: sticker.id,
            backgroundColor: nil,
            rotation: nil,
            createdAt: Date()
        )
        onSend(message)
        HapticFeedback.success()
    }
}
