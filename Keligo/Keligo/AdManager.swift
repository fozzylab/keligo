import Foundation
import Combine
import UIKit
import os.log

/// Centralized ad cadence + cap manager.
/// AdMob entegrasyonu yapılana kadar `presentInterstitial` ve `presentRewarded`
/// log atan stub'lardır. Gerçek SDK bağlanırken sadece bu iki method değişir.
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    // MARK: - Tunables
    static let interstitialEveryN: Int = 4
    static let interstitialCooldownSec: TimeInterval = 75
    static let firstAdFreeGames: Int = 3
    static let rewardedToInterstitialCooldownSec: TimeInterval = 30

    static let capLetterReveal = 5
    static let capLifeRefill   = 3
    static let capJetonBonus   = 1
    static let capStreakSave   = 1

    enum RewardKind: String {
        case letter, life, jetonBonus, streakSave

        var dailyCap: Int {
            switch self {
            case .letter:     return AdManager.capLetterReveal
            case .life:       return AdManager.capLifeRefill
            case .jetonBonus: return AdManager.capJetonBonus
            case .streakSave: return AdManager.capStreakSave
            }
        }
    }

    // MARK: - Persistence keys
    private let kTotalGamesEver       = "ad_totalGamesEver"
    private let kGamesSinceLastInter  = "ad_gamesSinceLastInter"
    private let kLastInterstitialAt   = "ad_lastInterstitialAt"
    private let kLastRewardedAt       = "ad_lastRewardedAt"
    private func kRewardedUsed(_ kind: RewardKind, day: String) -> String {
        "ad_rewarded_\(kind.rawValue)_\(day)"
    }

    private let log = Logger(subsystem: "com.fozzylabs.keligo", category: "AdManager")

    private init() {}

    // MARK: - Public API

    /// Bir oyun bittiğinde GameBoardView buradan çağırır (won veya lost).
    func notifyGameEnded() {
        let ud = UserDefaults.standard
        ud.set(ud.integer(forKey: kTotalGamesEver) + 1,      forKey: kTotalGamesEver)
        ud.set(ud.integer(forKey: kGamesSinceLastInter) + 1, forKey: kGamesSinceLastInter)
    }

    /// `notifyGameEnded` çağrıldıktan sonra kontrol et.
    func shouldShowInterstitial() -> Bool {
        if IAPManager.shared.isAdsRemoved { return false }

        let ud = UserDefaults.standard
        let totalGames = ud.integer(forKey: kTotalGamesEver)
        if totalGames <= Self.firstAdFreeGames { return false }

        let gamesSince = ud.integer(forKey: kGamesSinceLastInter)
        if gamesSince < Self.interstitialEveryN { return false }

        if let lastInter = ud.object(forKey: kLastInterstitialAt) as? Date,
           Date().timeIntervalSince(lastInter) < Self.interstitialCooldownSec {
            return false
        }

        if let lastRewarded = ud.object(forKey: kLastRewardedAt) as? Date,
           Date().timeIntervalSince(lastRewarded) < Self.rewardedToInterstitialCooldownSec {
            return false
        }

        return true
    }

    /// STUB: gerçek SDK bağlanana kadar log atıp `true` döner (gösterildi varsayımı).
    @discardableResult
    func presentInterstitial() async -> Bool {
        let ud = UserDefaults.standard
        ud.set(Date(), forKey: kLastInterstitialAt)
        ud.set(0,      forKey: kGamesSinceLastInter)
        log.info("📺 [STUB] Interstitial shown")
        return true
    }

    func remaining(_ kind: RewardKind) -> Int {
        let day = todayKey()
        let used = UserDefaults.standard.integer(forKey: kRewardedUsed(kind, day: day))
        return max(0, kind.dailyCap - used)
    }

    func canShowRewarded(_ kind: RewardKind) -> Bool {
        remaining(kind) > 0
    }

    /// STUB: tüketim ve cooldown güncellemesi yapar.
    @discardableResult
    func presentRewarded(_ kind: RewardKind) async -> Bool {
        guard canShowRewarded(kind) else {
            log.info("📺 [STUB] Rewarded \(kind.rawValue) — cap reached")
            return false
        }
        let day = todayKey()
        let key = kRewardedUsed(kind, day: day)
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
        UserDefaults.standard.set(Date(), forKey: kLastRewardedAt)
        log.info("📺 [STUB] Rewarded \(kind.rawValue) shown — remaining: \(self.remaining(kind))")
        return true
    }

    // MARK: - Helpers

    private func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Test/reset için
    func resetAllCaps() {
        let prefix = "ad_rewarded_"
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.removeObject(forKey: kLastInterstitialAt)
        UserDefaults.standard.removeObject(forKey: kLastRewardedAt)
        UserDefaults.standard.set(0, forKey: kGamesSinceLastInter)
    }
}
