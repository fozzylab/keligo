import Foundation
import Combine
import StoreKit
import UIKit
import CloudKit

// MARK: - Game History Entry

struct GameHistoryEntry: Codable, Identifiable {
    let id: UUID
    let word: String
    let category: String
    let won: Bool
    let wrongCount: Int
    let maxWrong: Int
    let date: Date
    let mode: String   // "Günlük", "Sonsuz", "Bölüm", "Hız", "Meydan Okuma"

    init(word: String, category: String, won: Bool, wrongCount: Int, maxWrong: Int, mode: String = "Sonsuz") {
        self.id = UUID(); self.date = Date()
        self.word = word; self.category = category
        self.won = won; self.wrongCount = wrongCount
        self.maxWrong = maxWrong; self.mode = mode
    }
}

// MARK: - Chart data model

struct ChartDay: Identifiable {
    let id = UUID()
    let label: String
    let wins: Int
    let losses: Int
}

// MARK: - Calendar day model

struct CalendarDay: Identifiable {
    let id: String   // date string
    let date: Date
    let played: Bool
    let won: Bool
}

// MARK: - StatsManager

class StatsManager: ObservableObject {
    @Published var totalGames: Int      { didSet { save("totalGames", totalGames) } }
    @Published var wins: Int            { didSet { save("wins", wins) } }
    @Published var currentStreak: Int   { didSet { save("currentStreak", currentStreak); sharedSave("currentStreak", currentStreak) } }
    @Published var bestStreak: Int      { didSet { save("bestStreak", bestStreak) } }
    @Published var speedHighScore: Int  { didSet { save("speedHighScore", speedHighScore) } }
    @Published var totalDailyPlays: Int { didSet { save("totalDailyPlays", totalDailyPlays) } }
    @Published var wonCategories: Set<String> {
        didSet {
            if let d = try? JSONEncoder().encode(Array(wonCategories)) {
                UserDefaults.standard.set(d, forKey: "wonCategories")
            }
        }
    }

    // MARK: - New: XP & level
    @Published var xp: Int { didSet { save("xp", xp) } }

    // MARK: - New: Best word tracking
    @Published var bestWordText: String  { didSet { UserDefaults.standard.set(bestWordText, forKey: "bestWordText") } }
    @Published var bestWordWrong: Int    { didSet { save("bestWordWrong", bestWordWrong) } }

    // MARK: - New: Category stats
    @Published var categoryWins: [String: Int] {
        didSet {
            if let d = try? JSONEncoder().encode(categoryWins) {
                UserDefaults.standard.set(d, forKey: "categoryWins")
            }
        }
    }
    @Published var categoryGames: [String: Int] {
        didSet {
            if let d = try? JSONEncoder().encode(categoryGames) {
                UserDefaults.standard.set(d, forKey: "categoryGames")
            }
        }
    }

    // MARK: - Game history (last 50)
    @Published var gameHistory: [GameHistoryEntry] = [] {
        didSet {
            if let d = try? JSONEncoder().encode(gameHistory) {
                UserDefaults.standard.set(d, forKey: "gameHistory")
            }
        }
    }

    // MARK: - Streak milestones
    /// Published when a streak milestone is reached. UI can observe and show toast.
    @Published var pendingMilestonToast: (days: Int, jetons: Int)? = nil

    private let streakMilestones: [(days: Int, jetons: Int)] = [
        (3, 30), (7, 100), (14, 250), (30, 600), (50, 1000), (100, 2000)
    ]

    func dismissMilestoneToast() { pendingMilestonToast = nil }

    private func checkStreakMilestone() {
        guard let milestone = streakMilestones.first(where: { $0.days == currentStreak }) else { return }
        let streakKey = "milestone_\(milestone.days)_streak"
        let lastClaimedStreak = UserDefaults.standard.integer(forKey: streakKey)
        // Only claim if we haven't claimed at this exact streak level before (re-earnable after a reset)
        guard lastClaimedStreak < currentStreak else { return }
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        JetonManager.shared.earn(milestone.jetons)
        pendingMilestonToast = (days: milestone.days, jetons: milestone.jetons)
    }

    // MARK: - Streak protection
    /// Saved automatically just before currentStreak is reset on a loss.
    @Published var streakBeforeLoss: Int = 0

    var streakProtectionUsedDate: String {
        get { UserDefaults.standard.string(forKey: "streakProtectionDate") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "streakProtectionDate") }
    }

    // MARK: - Computed basics
    var losses: Int     { totalGames - wins }
    var winRate: Double { totalGames == 0 ? 0 : Double(wins) / Double(totalGames) * 100 }

    // MARK: - Level system
    var level: Int {
        if xp == 0 { return 1 }
        return Int((-1.0 + sqrt(1.0 + Double(8 * xp) / 100.0)) / 2.0) + 1
    }

    var xpForCurrentLevel: Int {
        let l = level - 1
        return l * (l + 1) / 2 * 100
    }

    var xpForNextLevel: Int {
        let l = level
        return l * (l + 1) / 2 * 100
    }

    var levelProgress: Double {
        let current = xp - xpForCurrentLevel
        let needed = xpForNextLevel - xpForCurrentLevel
        guard needed > 0 else { return 1.0 }
        return min(1.0, Double(current) / Double(needed))
    }

    var levelTitle: String {
        switch level {
        case 1: return "Çaylak"
        case 2: return "Meraklı"
        case 3: return "Hevesli"
        case 4: return "Tecrübeli"
        case 5: return "Usta"
        case 6: return "Uzman"
        case 7: return "Şampiyon"
        case 8: return "Efsane"
        case 9...Int.max: return "İmparator"
        default: return "Çaylak"
        }
    }

    // MARK: - Streak protection helpers
    var canUseStreakProtection: Bool {
        let today = dateString(Date())
        return streakBeforeLoss > 0 && streakProtectionUsedDate != today
    }

    func useStreakProtection() -> Bool {
        guard canUseStreakProtection else { return false }
        guard JetonManager.shared.spend(JetonManager.costStreakProtection) else { return false }
        currentStreak = streakBeforeLoss   // Restore streak
        streakProtectionUsedDate = dateString(Date())
        streakBeforeLoss = 0
        return true
    }

    /// Reklam ile seri koruma — jeton tüketmez, ad cap kontrolü dış katmanda.
    @discardableResult
    func restoreStreakFromAd() -> Bool {
        guard canUseStreakProtection else { return false }
        currentStreak = streakBeforeLoss
        streakProtectionUsedDate = dateString(Date())
        streakBeforeLoss = 0
        return true
    }

    // MARK: - iCloud

    var iCloudEnabled: Bool { UserDefaults.standard.bool(forKey: "iCloudSync") }

    func syncToiCloud() {
        #if !targetEnvironment(simulator)
        guard iCloudEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.set(wins, forKey: "icloud_wins")
        store.set(bestStreak, forKey: "icloud_bestStreak")
        store.set(xp, forKey: "icloud_xp")
        store.set(speedHighScore, forKey: "icloud_speedHighScore")
        if let d = try? JSONEncoder().encode(Array(wonCategories)) {
            store.set(d, forKey: "icloud_wonCategories")
        }
        store.synchronize()
        #endif
    }

    func loadFromiCloud() {
        #if !targetEnvironment(simulator)
        guard iCloudEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        let cloudWins = Int(store.longLong(forKey: "icloud_wins"))
        if cloudWins > wins { wins = cloudWins }
        let cloudBest = Int(store.longLong(forKey: "icloud_bestStreak"))
        if cloudBest > bestStreak { bestStreak = cloudBest }
        let cloudXP = Int(store.longLong(forKey: "icloud_xp"))
        if cloudXP > xp { xp = cloudXP }
        let cloudSpeed = Int(store.longLong(forKey: "icloud_speedHighScore"))
        if cloudSpeed > speedHighScore { speedHighScore = cloudSpeed }
        if let d = store.data(forKey: "icloud_wonCategories"),
           let cats = try? JSONDecoder().decode(Set<String>.self, from: d) {
            wonCategories = wonCategories.union(cats)
        }
        #endif
    }

    func observeCloudChanges() {
        #if !targetEnvironment(simulator)
        guard iCloudEnabled else { return }
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.loadFromiCloud()
        }
        NSUbiquitousKeyValueStore.default.synchronize()
        #endif
    }

    // MARK: - Init
    init() {
        let ud = UserDefaults.standard
        totalGames      = ud.integer(forKey: "totalGames")
        wins            = ud.integer(forKey: "wins")
        currentStreak   = ud.integer(forKey: "currentStreak")
        bestStreak      = ud.integer(forKey: "bestStreak")
        speedHighScore  = ud.integer(forKey: "speedHighScore")
        totalDailyPlays = ud.integer(forKey: "totalDailyPlays")
        wonCategories = (try? JSONDecoder().decode(Set<String>.self,
            from: ud.data(forKey: "wonCategories") ?? Data())) ?? []

        xp           = ud.integer(forKey: "xp")
        bestWordText = ud.string(forKey: "bestWordText") ?? ""
        bestWordWrong = ud.object(forKey: "bestWordWrong") as? Int ?? 99
        categoryWins  = (try? JSONDecoder().decode([String: Int].self, from: ud.data(forKey: "categoryWins")  ?? Data())) ?? [:]
        categoryGames = (try? JSONDecoder().decode([String: Int].self, from: ud.data(forKey: "categoryGames") ?? Data())) ?? [:]
        gameHistory   = (try? JSONDecoder().decode([GameHistoryEntry].self, from: ud.data(forKey: "gameHistory") ?? Data())) ?? []

        observeCloudChanges()
        loadFromiCloud()
    }

    // MARK: - Record results

    func recordWin(category: String, wrongCount: Int = 0, maxWrong: Int = 6) {
        totalGames += 1
        wins += 1
        currentStreak += 1
        if currentStreak > bestStreak { bestStreak = currentStreak }
        wonCategories.insert(category)
        updateDayStats(won: true)
        requestReviewIfNeeded()

        // Jeton rewards
        JetonManager.shared.earn(JetonManager.rewardWin)
        if currentStreak > 0 && currentStreak % 5 == 0 {
            JetonManager.shared.earn(JetonManager.rewardStreak)
        }

        // Streak milestone bonus
        checkStreakMilestone()

        // XP award
        let bonusXP = max(0, (maxWrong - wrongCount)) * 3
        xp += 20 + bonusXP
        GameCenterManager.shared.submitXP(xp)   // sync to leaderboard

        // Category tracking
        categoryGames[category, default: 0] += 1
        categoryWins[category, default: 0] += 1

        // Best word tracking (fewest wrong guesses)
        if bestWordText.isEmpty || wrongCount < bestWordWrong {
            bestWordWrong = wrongCount
            bestWordText  = category  // store category as context label
        }

        syncToiCloud()
    }

    func recordLoss(category: String = "") {
        totalGames += 1
        streakBeforeLoss = currentStreak   // Save before reset so protection can restore
        currentStreak = 0
        updateDayStats(won: false)

        // Small consolation XP
        xp += 5

        // Category tracking
        if !category.isEmpty {
            categoryGames[category, default: 0] += 1
        }

        syncToiCloud()
    }

    func recordDailyPlay() {
        totalDailyPlays += 1
    }

    func addHistory(_ entry: GameHistoryEntry) {
        gameHistory.insert(entry, at: 0)
        if gameHistory.count > 50 { gameHistory = Array(gameHistory.prefix(50)) }
    }

    func reset() {
        totalGames = 0; wins = 0; currentStreak = 0; bestStreak = 0
        speedHighScore = 0; totalDailyPlays = 0; wonCategories = []
        xp = 0; bestWordText = ""; bestWordWrong = 99
        categoryWins = [:]; categoryGames = [:]
        gameHistory = []
    }

    // MARK: - Daily chart data

    var last7Days: [ChartDay] {
        let cal = Calendar.current
        let dayNames = ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let key = "day_\(dateString(date))"
            let d = UserDefaults.standard.data(forKey: key) ?? Data()
            let s = (try? JSONDecoder().decode(DayStats.self, from: d)) ?? DayStats()
            let weekday = cal.component(.weekday, from: date) - 1
            return ChartDay(label: dayNames[weekday], wins: s.wins, losses: s.losses)
        }
    }

    // MARK: - 30-day calendar data

    var last30Days: [CalendarDay] {
        let cal = Calendar.current
        return (0..<30).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let key = "day_\(dateString(date))"
            let d = UserDefaults.standard.data(forKey: key) ?? Data()
            let s = (try? JSONDecoder().decode(DayStats.self, from: d)) ?? DayStats()
            let played = s.wins + s.losses > 0
            let won = s.wins > 0
            return CalendarDay(id: dateString(date), date: date, played: played, won: won)
        }
    }

    // MARK: - Helpers

    private func updateDayStats(won: Bool) {
        let key = "day_\(dateString(Date()))"
        let d = UserDefaults.standard.data(forKey: key) ?? Data()
        var s = (try? JSONDecoder().decode(DayStats.self, from: d)) ?? DayStats()
        if won { s.wins += 1 } else { s.losses += 1 }
        UserDefaults.standard.set(try? JSONEncoder().encode(s), forKey: key)
    }

    func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func requestReviewIfNeeded() {
        let milestones = [10, 50, 100]
        let lastAsked = UserDefaults.standard.integer(forKey: "lastReviewWins")
        for m in milestones where wins >= m && lastAsked < m {
            UserDefaults.standard.set(m, forKey: "lastReviewWins")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                else { return }
                AppStore.requestReview(in: scene)
            }
            break
        }
    }

    private func save(_ key: String, _ value: Int) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func sharedSave(_ key: String, _ value: Int) {
        let shared = UserDefaults(suiteName: "group.com.fozzylabs.keligo") ?? .standard
        shared.set(value, forKey: key)
    }
}

private struct DayStats: Codable {
    var wins: Int = 0
    var losses: Int = 0
}
