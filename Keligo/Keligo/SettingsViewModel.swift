import Foundation
import Combine
import UIKit

enum MicroInteractionLevel: String, CaseIterable, Identifiable {
    case minimal, balanced, cinematic
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .balanced: return "Dengeli"
        case .cinematic: return "Sinematik"
        }
    }
}

enum ColorVisionFilter: String, CaseIterable, Identifiable {
    case none, protanopia, deuteranopia, tritanopia
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return "Yok"
        case .protanopia: return "Protanopi"
        case .deuteranopia: return "Deuteranopi"
        case .tritanopia: return "Tritanopi"
        }
    }
}

enum HapticRichness: String, CaseIterable, Identifiable {
    case basic, rich
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .basic: return "Temel"
        case .rich: return "Zengin"
        }
    }
}

class SettingsViewModel: ObservableObject {
    // MARK: - Legacy Settings
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

    // MARK: - 2026 Next-Gen Settings
    @Published var spatialUIEnabled: Bool {
        didSet { ud.set(spatialUIEnabled, forKey: "spatialUIEnabled") }
    }
    @Published var ambientIntensity: Double {
        didSet { ud.set(ambientIntensity, forKey: "ambientIntensity") }
    }
    @Published var microInteractionLevel: MicroInteractionLevel {
        didSet { ud.set(microInteractionLevel.rawValue, forKey: "microInteractionLevel") }
    }
    @Published var aiAssistantEnabled: Bool {
        didSet { ud.set(aiAssistantEnabled, forKey: "aiAssistantEnabled") }
    }
    @Published var focusModeEnabled: Bool {
        didSet { ud.set(focusModeEnabled, forKey: "focusModeEnabled") }
    }
    @Published var motionSafeMode: Bool {
        didSet { ud.set(motionSafeMode, forKey: "motionSafeMode") }
    }
    @Published var colorVisionFilter: ColorVisionFilter {
        didSet { ud.set(colorVisionFilter.rawValue, forKey: "colorVisionFilter") }
    }
    @Published var voiceControlEnabled: Bool {
        didSet { ud.set(voiceControlEnabled, forKey: "voiceControlEnabled") }
    }
    @Published var dynamicIslandLiveActivity: Bool {
        didSet { ud.set(dynamicIslandLiveActivity, forKey: "dynamicIslandLiveActivity") }
    }
    @Published var hapticRichness: HapticRichness {
        didSet { ud.set(hapticRichness.rawValue, forKey: "hapticRichness") }
    }

    // MARK: - Ses & Bildirim ek ayarlar
    @Published var soundVolume: Double {
        didSet {
            ud.set(soundVolume, forKey: "soundVolume")
            SoundManager.shared.globalVolume = Float(soundVolume)
        }
    }
    @Published var notificationHour: Int {
        didSet { ud.set(notificationHour, forKey: "notificationHour") }
    }
    @Published var notificationMinute: Int {
        didSet { ud.set(notificationMinute, forKey: "notificationMinute") }
    }

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

        // Next-gen defaults
        spatialUIEnabled = ud.object(forKey: "spatialUIEnabled") as? Bool ?? true
        ambientIntensity = ud.object(forKey: "ambientIntensity") as? Double ?? 0.8
        microInteractionLevel = MicroInteractionLevel(rawValue: ud.string(forKey: "microInteractionLevel") ?? "balanced") ?? .balanced
        aiAssistantEnabled = ud.object(forKey: "aiAssistantEnabled") as? Bool ?? true
        focusModeEnabled = ud.object(forKey: "focusModeEnabled") as? Bool ?? false
        motionSafeMode = ud.object(forKey: "motionSafeMode") as? Bool ?? UIAccessibility.isReduceMotionEnabled
        colorVisionFilter = ColorVisionFilter(rawValue: ud.string(forKey: "colorVisionFilter") ?? "none") ?? .none
        voiceControlEnabled = ud.object(forKey: "voiceControlEnabled") as? Bool ?? false
        dynamicIslandLiveActivity = ud.object(forKey: "dynamicIslandLiveActivity") as? Bool ?? true
        hapticRichness = HapticRichness(rawValue: ud.string(forKey: "hapticRichness") ?? "rich") ?? .rich

        soundVolume      = ud.object(forKey: "soundVolume")      as? Double ?? 1.0
        notificationHour   = ud.object(forKey: "notificationHour")   as? Int ?? 9
        notificationMinute = ud.object(forKey: "notificationMinute") as? Int ?? 0

        // Ses volume'u hemen uygula
        SoundManager.shared.globalVolume = Float(soundVolume)
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
