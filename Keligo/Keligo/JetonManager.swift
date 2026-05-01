import Foundation
import Combine

class JetonManager: ObservableObject {
    static let shared = JetonManager()

    @Published var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: "jetonBalance") }
    }

    private init() {
        balance = UserDefaults.standard.integer(forKey: "jetonBalance")
    }

    // MARK: - Reward amounts (rebalanced — less inflation)
    static let rewardWin         = 15
    static let rewardDaily       = 20
    static let rewardStreak      = 40   // every 5-win streak milestone
    static let rewardAd          = 80
    static let rewardJetonAdBonus = 15  // 1/gün ana menüden rewarded ad ile

    // MARK: - Costs
    static let costVowel            = 200
    static let costLetter           = 100
    static let costSkip             = 50
    static let costUndo             = 75
    static let costStreakProtection = 200  // rebalance: was 75
    static let costRefillOne        = 50   // base, see LivesManager for escalation
    static let costRefillAll        = 250  // was 200 — removes single-refill advantage
    static let costHint             = 50
    static let costContinueAfterLoss = 100 // new: keep playing after max wrong guesses

    // MARK: - Actions

    func earn(_ amount: Int) {
        balance += amount
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }

    func canAfford(_ amount: Int) -> Bool { balance >= amount }
}
