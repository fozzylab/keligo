import Foundation
import Combine

// MARK: - Weekly Challenge Manager

class WeeklyChallengeManager: ObservableObject {
    static let shared = WeeklyChallengeManager()
    private init() {}

    static let bonusJetons = 400

    // MARK: - ISO Calendar

    private var isoCal: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.locale = Locale(identifier: "tr_TR")
        return c
    }

    // MARK: - Seed helpers

    private func weekComponents(for date: Date) -> (year: Int, week: Int) {
        let comps = isoCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }

    /// Seed = year * 100 + ISO week number
    private func weekSeed(for date: Date) -> UInt64 {
        let (year, week) = weekComponents(for: date)
        return UInt64(year * 100 + week)
    }

    /// Day offset within the week: Monday = 0 … Sunday = 6
    private func dayOffset(for date: Date) -> Int {
        // isoCal weekday: Monday=2…Sunday=1 (ISO: Mon=2, Tue=3, … Sun=1)
        let weekday = isoCal.component(.weekday, from: date)
        // Convert to 0-based Mon-first
        return (weekday + 5) % 7
    }

    // MARK: - Word selection

    /// Returns the weekly challenge word for a given date (deterministric).
    func weekWord(for date: Date) -> WordEntry {
        let seed      = weekSeed(for: date)
        let offset    = dayOffset(for: date)
        var rng       = SeededRNG(seed: seed)
        var words     = WordList.words

        // Shuffle the entire list with the week seed, then pick by day offset.
        words.shuffle(using: &rng)

        // Guard against empty word list (should never happen in production).
        guard !words.isEmpty else {
            return WordEntry(word: "KELIME", category: "Haftalık Meydan Okuma")
        }
        return words[offset % words.count]
    }

    // MARK: - Storage keys

    private func storageKey(for date: Date, suffix: String = "") -> String {
        let (year, week) = weekComponents(for: date)
        let day          = dayOffset(for: date) + 1      // 1..7
        let base         = "weekly_\(year)_\(week)_\(day)"
        return suffix.isEmpty ? base : base + suffix
    }

    private func bonusKey(for date: Date) -> String {
        let (year, week) = weekComponents(for: date)
        return "weekly_\(year)_\(week)_bonus"
    }

    // MARK: - Play status

    func hasPlayed(_ date: Date) -> Bool {
        UserDefaults.standard.bool(forKey: storageKey(for: date))
    }

    func result(for date: Date) -> Bool? {
        guard hasPlayed(date) else { return nil }
        return UserDefaults.standard.bool(forKey: storageKey(for: date, suffix: "_won"))
    }

    func markPlayed(date: Date, won: Bool) {
        let key = storageKey(for: date)
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.set(won,  forKey: key + "_won")
    }

    // MARK: - Week helpers

    /// Returns the 7 dates of the current ISO week (Monday … Sunday).
    func weekDates() -> [Date] {
        let today = Date()
        let (year, week) = weekComponents(for: today)

        var comps            = DateComponents()
        comps.yearForWeekOfYear = year
        comps.weekOfYear     = week
        comps.weekday        = 2        // Monday in ISO calendar

        guard let monday = isoCal.date(from: comps) else { return [] }

        return (0..<7).compactMap { isoCal.date(byAdding: .day, value: $0, to: monday) }
    }

    /// Number of days played (won OR lost) in the current week.
    func weekProgress() -> Int {
        weekDates().filter { hasPlayed($0) }.count
    }

    func isWeekComplete() -> Bool {
        weekProgress() == 7
    }

    // MARK: - Bonus

    func weekBonusClaimed() -> Bool {
        UserDefaults.standard.bool(forKey: bonusKey(for: Date()))
    }

    /// Awards 300 jetons once per week when the week is fully complete.
    func claimBonus() {
        guard isWeekComplete(), !weekBonusClaimed() else { return }
        UserDefaults.standard.set(true, forKey: bonusKey(for: Date()))
        JetonManager.shared.earn(WeeklyChallengeManager.bonusJetons)
    }

    // MARK: - Date helpers

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isFuture(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    func isPast(_ date: Date) -> Bool {
        !isToday(date) && !isFuture(date)
    }
}
