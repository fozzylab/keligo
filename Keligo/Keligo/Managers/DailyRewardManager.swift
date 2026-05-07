import Foundation
import Combine

// MARK: - Daily Login Reward Manager

class DailyRewardManager: ObservableObject {
    static let shared = DailyRewardManager()
    private init() {}

    // Jetons per consecutive login day (cycles every 7 days)
    private let rewards = [10, 20, 30, 50, 75, 100, 150]

    // MARK: - State

    @Published var pendingReward: (streak: Int, jetons: Int)? = nil

    var loginStreak: Int {
        UserDefaults.standard.integer(forKey: "dailyLoginStreak")
    }

    var hasClaimedToday: Bool {
        UserDefaults.standard.string(forKey: "dailyRewardLastClaimed") == todayString()
    }

    // MARK: - Claim

    /// Call once on app foreground. Publishes `pendingReward` if a new reward is available.
    func checkAndClaim() {
        guard !hasClaimedToday else { return }

        let lastClaimed = UserDefaults.standard.string(forKey: "dailyRewardLastClaimed") ?? ""
        var streak = UserDefaults.standard.integer(forKey: "dailyLoginStreak")

        if lastClaimed == yesterdayString() {
            streak += 1          // Consecutive day
        } else {
            streak = 1           // Streak broken or first time
        }

        let reward = rewards[(streak - 1) % rewards.count]

        UserDefaults.standard.set(streak, forKey: "dailyLoginStreak")
        UserDefaults.standard.set(todayString(), forKey: "dailyRewardLastClaimed")

        JetonManager.shared.earn(reward)
        pendingReward = (streak: streak, jetons: reward)
    }

    func dismissReward() { pendingReward = nil }

    // MARK: - Helpers

    private func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func yesterdayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }
}
