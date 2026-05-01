import Foundation
import Combine
import WidgetKit

// MARK: - App Group shared store

private let appGroupID     = "group.com.fozzylabs.keligo"
private let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

class DailyWordManager: ObservableObject {
    static let shared = DailyWordManager()
    private init() {}

    /// Jeton to unlock a past day from the calendar
    static let costPastDay = 30

    // MARK: - Word for any date (deterministic seed)

    func word(for date: Date) -> WordEntry {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let seed = UInt64(c.year! * 10000 + c.month! * 100 + c.day!)
        var rng = SeededRNG(seed: seed)
        return WordList.words.randomElement(using: &rng)!
    }

    var todayWord: WordEntry { word(for: Date()) }

    // MARK: - Storage keys

    func key(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "daily_\(f.string(from: date))"
    }

    // MARK: - Play status

    func hasPlayed(_ date: Date) -> Bool {
        UserDefaults.standard.bool(forKey: key(for: date))
    }

    var hasPlayedToday: Bool { hasPlayed(Date()) }

    func result(for date: Date) -> (won: Bool, wrongCount: Int)? {
        guard hasPlayed(date) else { return nil }
        let k = key(for: date)
        let won   = UserDefaults.standard.bool(forKey: k + "_won")
        let wrong = UserDefaults.standard.integer(forKey: k + "_wrong")
        return (won, wrong)
    }

    var todayResult: (won: Bool, wrongCount: Int)? { result(for: Date()) }

    // MARK: - Mark played

    /// Records the result for a given date.
    /// - Jeton reward and widget sync only for today.
    func markPlayed(date: Date = Date(), won: Bool, wrongCount: Int) {
        let k = key(for: date)
        UserDefaults.standard.set(true,       forKey: k)
        UserDefaults.standard.set(won,         forKey: k + "_won")
        UserDefaults.standard.set(wrongCount,  forKey: k + "_wrong")

        guard Calendar.current.isDateInToday(date) else { return }
        sharedDefaults.set(true, forKey: "widget_hasPlayedToday")
        WidgetCenter.shared.reloadTimelines(ofKind: "KeligoDailyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "KeligoMediumWidget")
        JetonManager.shared.earn(JetonManager.rewardDaily)
    }

    /// Syncs widget with today's hint (call on DailyGameView appear or after StatsManager updates streak).
    func syncWidget(entry: WordEntry, streak: Int = 0) {
        sharedDefaults.set(entry.category,                   forKey: "widget_category")
        sharedDefaults.set(entry.word.filter { $0 != " " }.count, forKey: "widget_letterCount")
        sharedDefaults.set(hasPlayedToday,                   forKey: "widget_hasPlayedToday")
        sharedDefaults.set(streak,                           forKey: "widget_streak")
        WidgetCenter.shared.reloadTimelines(ofKind: "KeligoDailyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "KeligoMediumWidget")
    }

    func shareText(word: String, wrongCount: Int, won: Bool) -> String {
        let date  = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let emoji = won ? "🎉" : "💀"
        let boxes = (0..<6).map { $0 < wrongCount ? "🟥" : "⬜️" }.joined()
        return "Keligo - \(date)\n\(emoji) \(boxes)\n#Keligo"
    }

    // MARK: - Calendar helpers

    var cal: Calendar { Calendar.current }

    func isToday(_ date: Date) -> Bool {
        cal.isDateInToday(date)
    }

    func isFuture(_ date: Date) -> Bool {
        cal.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    func isPast(_ date: Date) -> Bool {
        !isToday(date) && !isFuture(date)
    }

    /// Returns an array of optional Dates for a month grid (Mon-based, nil = leading empty cell).
    func calendarDates(for month: Date) -> [Date?] {
        let start    = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let dayCount = cal.range(of: .day, in: .month, for: month)!.count

        // weekday offset: Monday = 0 … Sunday = 6
        var offset = cal.component(.weekday, from: start) - 2
        if offset < 0 { offset += 7 }

        let leading = Array(repeating: nil as Date?, count: offset)
        let days    = (0..<dayCount).map { i -> Date? in
            cal.date(byAdding: .day, value: i, to: start)
        }
        return leading + days
    }
}
