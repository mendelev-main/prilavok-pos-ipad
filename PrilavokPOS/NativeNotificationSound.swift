import AudioToolbox
import Foundation

/// Native short alert sounds for POS events.
/// Keeps sound playback outside WKWebView so it behaves consistently on iPad.
enum NativeNotificationSound {
    static func play(named name: String) {
        let soundID: SystemSoundID
        switch name {
        case "alert":
            soundID = 1007
        case "bell":
            soundID = 1013
        case "soft":
            soundID = 1104
        default:
            soundID = 1000
        }
        AudioServicesPlaySystemSound(soundID)
    }
}
