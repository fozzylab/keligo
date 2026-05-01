import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var soundEnabled: Bool      { didSet { ud.set(soundEnabled,     forKey: "soundEnabled") } }
    @Published var hapticEnabled: Bool     { didSet { ud.set(hapticEnabled,    forKey: "hapticEnabled") } }
    @Published var showWrongLetters: Bool  { didSet { ud.set(showWrongLetters, forKey: "showWrongLetters") } }
    @Published var theme: AppTheme        { didSet { ud.set(theme.rawValue,    forKey: "theme") } }
    @Published var difficulty: Difficulty { didSet { ud.set(difficulty.rawValue, forKey: "difficulty") } }
    @Published var preferredMode: String  { didSet { ud.set(preferredMode,  forKey: "preferredMode") } }
    @Published var speedDuration: Int     { didSet { ud.set(speedDuration,   forKey: "speedDuration") } }
    @Published var wordLengthMin: Int     { didSet { ud.set(wordLengthMin,   forKey: "wordLengthMin") } }
    @Published var wordLengthMax: Int     { didSet { ud.set(wordLengthMax,   forKey: "wordLengthMax") } }
    @Published var kidsMode: Bool         { didSet { ud.set(kidsMode,        forKey: "kidsMode") } }
    @Published var adaptiveDifficulty: Bool {
        didSet { ud.set(adaptiveDifficulty, forKey: "adaptiveDifficulty") }
    }
    @Published var dailyNotification: Bool {
        didSet {
            ud.set(dailyNotification, forKey: "dailyNotification")
            if dailyNotification {
                NotificationManager.shared.requestPermission { granted in
                    if !granted { self.dailyNotification = false }
                }
            } else {
                NotificationManager.shared.cancelDailyReminder()
            }
        }
    }
    @Published var iCloudSync: Bool     { didSet { ud.set(iCloudSync,    forKey: "iCloudSync") } }
    @Published var keyboardStyle: KeyboardStyle { didSet { ud.set(keyboardStyle.rawValue, forKey: "keyboardStyle") } }

    private let ud = UserDefaults.standard

    init() {
        soundEnabled       = ud.object(forKey: "soundEnabled")      as? Bool ?? true
        hapticEnabled      = ud.object(forKey: "hapticEnabled")     as? Bool ?? true
        showWrongLetters   = ud.object(forKey: "showWrongLetters")  as? Bool ?? true
        dailyNotification  = ud.object(forKey: "dailyNotification") as? Bool ?? false
        adaptiveDifficulty = ud.object(forKey: "adaptiveDifficulty") as? Bool ?? false
        theme              = AppTheme(rawValue:    ud.string(forKey: "theme")      ?? "classic") ?? .classic
        difficulty         = Difficulty(rawValue: ud.string(forKey: "difficulty") ?? "normal")  ?? .normal
        preferredMode = ud.string(forKey: "preferredMode") ?? "daily"
        speedDuration = ud.object(forKey: "speedDuration") as? Int ?? 60
        wordLengthMin = ud.object(forKey: "wordLengthMin") as? Int ?? 0
        wordLengthMax = ud.object(forKey: "wordLengthMax") as? Int ?? 99
        kidsMode      = ud.object(forKey: "kidsMode")      as? Bool ?? false
        iCloudSync    = ud.object(forKey: "iCloudSync")    as? Bool ?? false
        keyboardStyle = KeyboardStyle(rawValue: ud.string(forKey: "keyboardStyle") ?? "glass") ?? .glass
    }

    // MARK: - Adaptive difficulty

    /// Records result and adjusts wordLength bounds if adaptiveDifficulty is on.
    func recordAdaptiveResult(won: Bool) {
        guard adaptiveDifficulty else { return }

        // Rolling window of last 10 results (stored as 1/0)
        var history = (ud.array(forKey: "adaptiveResults") as? [Int]) ?? []
        history.append(won ? 1 : 0)
        if history.count > 10 { history = Array(history.suffix(10)) }
        ud.set(history, forKey: "adaptiveResults")

        guard history.count >= 5 else { return }   // Need at least 5 games to adapt

        let winRate = Double(history.reduce(0, +)) / Double(history.count)

        if winRate > 0.80 {
            // Too easy → increase minimum length (up to max - 2)
            let newMin = min(wordLengthMin + 1, max(wordLengthMax - 2, wordLengthMin))
            if newMin != wordLengthMin { wordLengthMin = newMin }
        } else if winRate < 0.35 {
            // Too hard → decrease minimum length (down to 3)
            let newMin = max(wordLengthMin - 1, 3)
            if newMin != wordLengthMin { wordLengthMin = newMin }
        }
    }

    /// Returns the computed win rate of the last 10 games (for display).
    var adaptiveWinRate: Double {
        let history = (ud.array(forKey: "adaptiveResults") as? [Int]) ?? []
        guard !history.isEmpty else { return 0 }
        return Double(history.reduce(0, +)) / Double(history.count)
    }
}
