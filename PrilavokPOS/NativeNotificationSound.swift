import AVFoundation
import Foundation

/// Reliable short notification tones for POS events.
/// Uses the native iOS audio session instead of WKWebView/Web Audio or undocumented system sound IDs.
enum NativeNotificationSound {
    private static var engine: AVAudioEngine?
    private static var player: AVAudioPlayerNode?

    static func play(named name: String) {
        DispatchQueue.main.async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true)
                playTone(named: name)
            } catch {
                print("POS notification sound error: \(error.localizedDescription)")
            }
        }
    }

    private static func playTone(named name: String) {
        engine?.stop()
        player?.stop()

        let audioEngine = AVAudioEngine()
        let audioPlayer = AVAudioPlayerNode()
        audioEngine.attach(audioPlayer)

        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: format)

        let settings: (frequency: Double, duration: Double, volume: Float)
        switch name {
        case "alert": settings = (1040, 0.30, 0.55)
        case "bell": settings = (1320, 0.36, 0.50)
        case "soft": settings = (660, 0.28, 0.38)
        default: settings = (880, 0.30, 0.48)
        }

        let frameCount = AVAudioFrameCount(sampleRate * settings.duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let progress = Double(frame) / Double(frameCount)
            let attack = min(1.0, progress / 0.08)
            let release = min(1.0, (1.0 - progress) / 0.22)
            let envelope = max(0.0, min(attack, release))
            channel[frame] = Float(sin(2.0 * .pi * settings.frequency * time) * envelope) * settings.volume
        }

        do {
            try audioEngine.start()
            engine = audioEngine
            player = audioPlayer
            audioPlayer.scheduleBuffer(buffer, at: nil, options: []) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    audioPlayer.stop()
                    audioEngine.stop()
                    if player === audioPlayer { player = nil }
                    if engine === audioEngine { engine = nil }
                }
            }
            audioPlayer.play()
        } catch {
            print("POS notification tone error: \(error.localizedDescription)")
        }
    }
}
