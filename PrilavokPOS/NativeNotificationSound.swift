import AVFoundation
import Foundation

/// Pleasant short notification tones for POS events.
/// Uses native iOS audio so playback remains reliable inside the iPad POS app.
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

    private struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
        let volume: Double
        let harmonic: Double
    }

    private static func notes(for name: String) -> [Note] {
        switch name {
        case "chime":
            return [Note(frequency: 659.25, start: 0.00, duration: 0.32, volume: 0.32, harmonic: 0.18),
                    Note(frequency: 987.77, start: 0.16, duration: 0.46, volume: 0.30, harmonic: 0.24)]
        case "glass":
            return [Note(frequency: 1174.66, start: 0.00, duration: 0.52, volume: 0.24, harmonic: 0.42),
                    Note(frequency: 1760.00, start: 0.03, duration: 0.38, volume: 0.12, harmonic: 0.20)]
        case "ding":
            return [Note(frequency: 880.00, start: 0.00, duration: 0.48, volume: 0.34, harmonic: 0.32)]
        case "double":
            return [Note(frequency: 783.99, start: 0.00, duration: 0.24, volume: 0.28, harmonic: 0.16),
                    Note(frequency: 1046.50, start: 0.23, duration: 0.34, volume: 0.31, harmonic: 0.20)]
        case "warm":
            return [Note(frequency: 523.25, start: 0.00, duration: 0.34, volume: 0.27, harmonic: 0.10),
                    Note(frequency: 659.25, start: 0.14, duration: 0.40, volume: 0.25, harmonic: 0.12),
                    Note(frequency: 783.99, start: 0.28, duration: 0.46, volume: 0.23, harmonic: 0.15)]
        case "pop":
            return [Note(frequency: 740.00, start: 0.00, duration: 0.16, volume: 0.34, harmonic: 0.08),
                    Note(frequency: 1110.00, start: 0.10, duration: 0.20, volume: 0.22, harmonic: 0.10)]
        case "bright":
            return [Note(frequency: 987.77, start: 0.00, duration: 0.25, volume: 0.27, harmonic: 0.24),
                    Note(frequency: 1318.51, start: 0.12, duration: 0.34, volume: 0.25, harmonic: 0.28)]
        case "soft", "alert":
            return [Note(frequency: 587.33, start: 0.00, duration: 0.36, volume: 0.20, harmonic: 0.08),
                    Note(frequency: 739.99, start: 0.16, duration: 0.38, volume: 0.18, harmonic: 0.10)]
        case "classic", "bell":
            return [Note(frequency: 1046.50, start: 0.00, duration: 0.44, volume: 0.28, harmonic: 0.34)]
        default:
            return [Note(frequency: 659.25, start: 0.00, duration: 0.28, volume: 0.26, harmonic: 0.14),
                    Note(frequency: 880.00, start: 0.14, duration: 0.38, volume: 0.25, harmonic: 0.18)]
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

        let sequence = notes(for: name)
        let totalDuration = (sequence.map { $0.start + $0.duration }.max() ?? 0.5) + 0.04
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var sample = 0.0
            for note in sequence where time >= note.start && time < note.start + note.duration {
                let local = time - note.start
                let progress = local / note.duration
                let attack = min(1.0, progress / 0.045)
                let decay = exp(-4.2 * progress)
                let envelope = attack * decay
                let fundamental = sin(2.0 * .pi * note.frequency * local)
                let overtone = sin(2.0 * .pi * note.frequency * 2.01 * local) * note.harmonic
                sample += (fundamental + overtone) * envelope * note.volume
            }
            channel[frame] = Float(max(-0.82, min(0.82, sample)))
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
