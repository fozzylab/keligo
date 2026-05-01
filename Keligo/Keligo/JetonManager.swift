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

    // MARK: - Reward amounts
    static let rewardWin         = 15  // (was 10) Lives oyunu yavaşlattığı için tempo telafisi
    static let rewardDaily       = 25
    static let rewardStreak      = 50   // every 5-win streak milestone
    static let rewardAd          = 100
    static let rewardJetonAdBonus = 25  // 1/gün ana menüden rewarded ad ile

    // MARK: - Costs
    static let costVowel            = 200
    static let costLetter           = 100
    static let costSkip             = 50
    static let costUndo             = 75   // (was 100) — daha sık kullanılsın
    static let costStreakProtection = 75   // (was 50) — yüksek değer
    static let costRefillOne        = 50   // 1 can refill
    static let costRefillAll        = 200  // tam dolum (5 can = ~50% indirim)
    static let costHint             = 50   // kelime ipucu — kısa açıklayıcı cümle

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
