import AVFoundation
import UIKit

@MainActor
final class PracticeFeedbackPlayer {
    private var sounds: [String: AVAudioPlayer] = [:]
    private var effect: AVAudioPlayer?
    private var pulseGate = FeedbackPulseGate()
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        // Preparing a player activates the session, so configure mixing first.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        for name in Self.soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                sounds[name] = player
            }
        }
    }

    static var soundNames: [String] {
        (0...4).flatMap { stage in ["hit", "milestone", "record"].map { "feedback_\($0)_\(stage)" } }
            + ["feedback_broken", "feedback_correction", "feedback_beat"]
    }

    func play(_ event: FeedbackEvent, settings: FeedbackSettings) {
        if settings.sound {
            // Keep the existing playback behavior, including the iPhone silent switch.
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            effect?.stop()
            effect = sounds[event.soundName]
            effect?.currentTime = 0
            effect?.play()
        }
        let now = ProcessInfo.processInfo.systemUptime
        guard settings.haptics, let strength = event.strength, pulseGate.accept(at: now) else { return }
        let generator: UIImpactFeedbackGenerator
        switch strength {
        case .light: generator = light
        case .medium: generator = medium
        case .heavy: generator = heavy
        }
        generator.impactOccurred()
        generator.prepare()
    }

    func beat() {
        let player = sounds["feedback_beat"]
        player?.currentTime = 0
        player?.play()
    }

    func stop() {
        sounds.values.forEach { $0.stop() }
    }
}
