import Foundation
import SwiftUI
import Combine

// MARK: - Player Archetype

enum PlayerArchetype: String, CaseIterable {
    case explorer, perfectionist, speedster, casual
    
    var displayName: String {
        switch self {
        case .explorer: return "Kaşif"
        case .perfectionist: return "Mükemmeliyetçi"
        case .speedster: return "Hız Canavarı"
        case .casual: return "Rahat Oyuncu"
        }
    }
    
    var description: String {
        switch self {
        case .explorer: return "Farklı kategorileri keşfetmeyi seversin."
        case .perfectionist: return "Az hata ile bitirmeyi hedeflersin."
        case .speedster: return "Hızlı tahminlerle ilerlemeyi seversin."
        case .casual: return "Keyif almak için oynarsın, stres yok."
        }
    }
    
    var suggestedAmbientMood: AmbientMood {
        switch self {
        case .explorer: return .mysterious
        case .perfectionist: return .focused
        case .speedster: return .urgent
        case .casual: return .calm
        }
    }
    
    var suggestedTheme: AppTheme {
        switch self {
        case .explorer: return .galaxy
        case .perfectionist: return .midnight
        case .speedster: return .neon
        case .casual: return .pastel
        }
    }
}

// MARK: - Gesture Heatmap Entry

struct GestureHeatmapEntry: Codable {
    let letter: String
    let frequency: Int
    let lastPlayed: Date
}

// MARK: - AI Personalization Engine

class AIPersonalizationEngine: ObservableObject {
    static let shared = AIPersonalizationEngine()
    
    @Published var currentArchetype: PlayerArchetype = .casual
    @Published var suggestedTheme: AppTheme = .classic
    @Published var suggestedAmbientMood: AmbientMood = .calm
    @Published var predictiveHint: Character?
    @Published var sessionMood: AmbientMood = .focused
    @Published var gestureHeatmap: [Character: Int] = [:]
    @Published var coldZoneLetters: Set<Character> = []
    
    private let ud = UserDefaults.standard
    private let minGamesForArchetype = 10
    
    private init() {
        loadHeatmap()
        analyzeArchetype()
    }
    
    // MARK: - Session Analysis
    
    func recordGame(word: String, won: Bool, wrongGuesses: Int, duration: TimeInterval, category: String) {
        var history = (ud.array(forKey: "ai_gameHistory") as? [[String: Any]]) ?? []
        let entry: [String: Any] = [
            "word": word,
            "won": won,
            "wrongGuesses": wrongGuesses,
            "duration": duration,
            "category": category,
            "date": Date().timeIntervalSince1970
        ]
        history.append(entry)
        if history.count > 50 { history = Array(history.suffix(50)) }
        ud.set(history, forKey: "ai_gameHistory")
        
        analyzeArchetype()
        updateSessionMood()
    }
    
    func recordLetterTap(_ letter: Character) {
        gestureHeatmap[letter, default: 0] += 1
        saveHeatmap()
        computeColdZones()
    }
    
    // MARK: - Archetype Detection
    
    private func analyzeArchetype() {
        guard let history = ud.array(forKey: "ai_gameHistory") as? [[String: Any]],
              history.count >= minGamesForArchetype else { return }
        
        let recent = history.suffix(minGamesForArchetype)
        var categorySet = Set<String>()
        var totalWrong = 0
        var totalDuration: TimeInterval = 0
        var winCount = 0
        
        for entry in recent {
            if let cat = entry["category"] as? String { categorySet.insert(cat) }
            if let wrong = entry["wrongGuesses"] as? Int { totalWrong += wrong }
            if let dur = entry["duration"] as? TimeInterval { totalDuration += dur }
            if let won = entry["won"] as? Bool, won { winCount += 1 }
        }
        
        let avgWrong = Double(totalWrong) / Double(recent.count)
        let avgDuration = totalDuration / Double(recent.count)
        let categoryDiversity = Double(categorySet.count)
        let winRate = Double(winCount) / Double(recent.count)
        
        // Scoring
        var scores: [PlayerArchetype: Double] = [:]
        scores[.explorer] = categoryDiversity * 1.5 + (avgDuration > 45 ? 1 : 0)
        scores[.perfectionist] = (avgWrong < 2.5 ? 3 : 0) + winRate * 2
        scores[.speedster] = (avgDuration < 20 ? 3 : 0) + (avgWrong > 3 ? 1 : 0)
        scores[.casual] = (avgDuration > 30 && avgWrong < 4 ? 2 : 0) + (winRate < 0.6 ? 1 : 0)
        
        if let best = scores.max(by: { $0.value < $1.value }) {
            currentArchetype = best.key
            suggestedTheme = best.key.suggestedTheme
            suggestedAmbientMood = best.key.suggestedAmbientMood
        }
    }
    
    // MARK: - Session Mood
    
    private func updateSessionMood() {
        guard let history = ud.array(forKey: "ai_gameHistory") as? [[String: Any]],
              history.count >= 3 else { return }
        
        let recent = history.suffix(3)
        let wins = recent.filter { ($0["won"] as? Bool) ?? false }.count
        
        if wins == 3 {
            sessionMood = .celebratory
        } else if wins == 0 {
            sessionMood = .calm // Calm them down
        } else {
            sessionMood = .focused
        }
    }
    
    // MARK: - Predictive Hint
    
    func generatePredictiveHint(for word: String, guessed: Set<Character>) -> Character? {
        let unguessed = Set(word.filter { !guessed.contains($0) && $0 != " " })
        guard !unguessed.isEmpty else { return nil }
        
        // Frequency analysis for Turkish
        let turkishFreq: [Character: Double] = [
            "A": 11.5, "E": 9.0, "İ": 8.0, "N": 7.0, "R": 7.0,
            "L": 6.0, "I": 5.5, "K": 5.0, "D": 4.5, "M": 4.0,
            "T": 4.0, "S": 3.5, "U": 3.5, "Y": 3.0, "B": 2.5,
            "O": 2.5, "Ü": 2.0, "Ş": 2.0, "V": 2.0, "Ç": 1.5,
            "G": 1.5, "Z": 1.5, "H": 1.5, "C": 1.0, "P": 1.0,
            "Ö": 1.0, "Ğ": 0.8, "F": 0.7, "J": 0.1
        ]
        
        let candidates = unguessed.sorted {
            (turkishFreq[$0] ?? 1.0) > (turkishFreq[$1] ?? 1.0)
        }
        
        // Don't always pick #1 — add slight randomness for "AI feel"
        let topN = min(3, candidates.count)
        return candidates.prefix(topN).randomElement()
    }
    
    // MARK: - Gesture Heatmap
    
    private func loadHeatmap() {
        if let data = ud.data(forKey: "ai_gestureHeatmap"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            gestureHeatmap = Dictionary(uniqueKeysWithValues: decoded.map { (Character($0.key), $0.value) })
            computeColdZones()
        }
    }
    
    private func saveHeatmap() {
        let encodable = Dictionary(uniqueKeysWithValues: gestureHeatmap.map { (String($0.key), $0.value) })
        if let data = try? JSONEncoder().encode(encodable) {
            ud.set(data, forKey: "ai_gestureHeatmap")
        }
    }
    
    private func computeColdZones() {
        let allTurkish = Set("ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ")
        guard !gestureHeatmap.isEmpty else { coldZoneLetters = []; return }
        
        let avgFreq = Double(gestureHeatmap.values.reduce(0, +)) / Double(allTurkish.count)
        coldZoneLetters = Set(allTurkish.filter { letter in
            Double(gestureHeatmap[letter] ?? 0) < avgFreq * 0.5
        })
    }
    
    // MARK: - Smart Theme Suggestion
    
    func smartThemeSuggestion(currentHour: Int) -> AppTheme {
        switch currentHour {
        case 6..<12: return .classic
        case 12..<17: return .ocean
        case 17..<21: return .sunset
        default: return .midnight
        }
    }
    
    // MARK: - Adaptive UI Density
    
    var recommendedAnimationIntensity: Double {
        switch currentArchetype {
        case .explorer: return 1.0
        case .perfectionist: return 0.6
        case .speedster: return 0.8
        case .casual: return 1.0
        }
    }
}
