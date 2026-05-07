import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    private init() { preload() }

    var soundEnabled   = true
    var hapticEnabled  = true
    /// 0.0–1.0 arası global ses çarpanı (ayarlardan kontrol edilir)
    var globalVolume: Float = 1.0

    // MARK: - Players

    private var players: [String: AVAudioPlayer] = [:]

    private let soundMap: [String: String] = [
        "correct"    : "correct",
        "wrong"      : "wrong",
        "win"        : "win",
        "lose"       : "lose",
        "hint"       : "hint",
        "button_tap" : "button_tap",
        "skip"       : "skip"
    ]

    private func preload() {
        for (key, name) in soundMap {
            guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else {
                print("⚠️ Ses dosyası bulunamadı: \(name).caf")
                continue
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[key] = player
            }
        }
    }

    private func play(_ key: String, volume: Float = 1.0) {
        guard soundEnabled else { return }
        guard let player = players[key] else { return }
        player.volume = volume * globalVolume
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    // MARK: - Game Sounds

    func playCorrect() {
        play("correct")
        impact(.light)
    }

    func playWrong() {
        play("wrong")
        notify(.warning)
    }

    func playWin() {
        play("win")
        notify(.success)
    }

    func playLose() {
        play("lose")
        notify(.error)
    }

    func playHint() {
        play("hint", volume: 0.8)
        impact(.medium)
    }

    func playButtonTap() {
        play("button_tap", volume: 0.6)
        impact(.light)
    }

    /// Bölüm tamamlama sesi — `playWin` ile aynı ama ayrı adlandırılmış.
    func playLevelComplete() { playWin() }

    func playUnlock() {
        play("hint")
        impact(.heavy)
    }

    func playSkip() {
        play("skip")
        impact(.light)
    }

    // MARK: - Haptics

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
