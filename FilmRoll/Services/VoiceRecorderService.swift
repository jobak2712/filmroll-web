import Foundation
import AVFoundation
import Combine

/// Service for recording and playing voice notes
@MainActor
class VoiceRecorderService: NSObject, ObservableObject {
    static let shared = VoiceRecorderService()
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var playbackTime: TimeInterval = 0
    @Published var recordingURL: URL?
    @Published var audioLevel: Float = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    
    let maxRecordingDuration: TimeInterval = 30 // 30 seconds max
    
    override nonisolated init() {
        super.init()
    }
    
    // MARK: - Recording
    func startRecording() async -> Bool {
        // Request permission
        let permission = await requestPermission()
        guard permission else { return false }
        
        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            return false
        }
        
        // Create recording URL
        let fileName = "voice_note_\(UUID().uuidString).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            recordingURL = url
            isRecording = true
            recordingTime = 0
            
            // Start timer
            startRecordingTimer()
            startLevelTimer()
            
            return true
        } catch {
            print("Failed to start recording: \(error)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        
        return recordingURL
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        
        // Delete the file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        recordingTime = 0
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recordingTime += 0.1
                
                // Auto-stop at max duration
                if self.recordingTime >= self.maxRecordingDuration {
                    _ = self.stopRecording()
                }
            }
        }
    }
    
    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let level = recorder.averagePower(forChannel: 0)
                // Normalize from -160...0 to 0...1
                self.audioLevel = max(0, (level + 50) / 50)
            }
        }
    }
    
    // MARK: - Playback
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playbackTime = 0
    }
    
    // MARK: - Permission
    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func reset() {
        cancelRecording()
        stopPlayback()
        recordingURL = nil
        recordingTime = 0
        playbackTime = 0
        audioLevel = 0
    }
}

extension VoiceRecorderService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            playbackTime = 0
        }
    }
}
