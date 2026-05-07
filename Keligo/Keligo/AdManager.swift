import Foundation
import Combine
import UIKit
import os.log
import GoogleMobileAds

/// Centralized ad cadence + cap manager with real GoogleMobileAds SDK integration.
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs
    // ⚠️ TEST IDs — Google demo birimleri (review için)
    // Yayın öncesi aşağıdaki PRODUCTION satırlarını aktif et, TEST satırlarını comment'e al.
    //
    // PRODUCTION:
    // private let interstitialAdUnitID = "ca-app-pub-2301774166987825/6849458927"
    // private let rewardedAdUnitID     = "ca-app-pub-2301774166987825/8162540596"
    // private let appOpenAdUnitID      = "YOUR_APP_OPEN_AD_UNIT_ID" // AdMob'dan oluştur
    //
    // TEST:
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID     = "ca-app-pub-3940256099942544/1712485313"
    private let appOpenAdUnitID      = "ca-app-pub-3940256099942544/5575463023"

    @Published var errorMessage: String?

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

    // MARK: - Loaded ads
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var appOpenAd: AppOpenAd?

    private init() {
        preloadInterstitial()
        preloadRewarded()
        preloadAppOpenAd()
    }

    // MARK: - Preloading

    private func preloadInterstitial() {
        Task {
            do {
                interstitialAd = try await InterstitialAd.load(
                    with: interstitialAdUnitID, request: Request()
                )
                log.info("📺 Interstitial preloaded")
            } catch {
                log.error("📺 Interstitial preload failed: \(error.localizedDescription)")
            }
        }
    }

    private func preloadRewarded() {
        Task {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: rewardedAdUnitID, request: Request()
                )
                log.info("📺 Rewarded preloaded")
            } catch {
                log.error("📺 Rewarded preload failed: \(error.localizedDescription)")
            }
        }
    }

    private func preloadAppOpenAd() {
        Task {
            do {
                appOpenAd = try await AppOpenAd.load(
                    with: appOpenAdUnitID, request: Request()
                )
                log.info("📺 App Open Ad preloaded")
            } catch {
                log.error("📺 App Open Ad preload failed: \(error.localizedDescription)")
            }
        }
    }

    /// Uygulama açılışında veya ön plana gelince çağır.
    /// Reklamlar satın alınmışsa veya ad henüz hazır değilse sessizce geçer.
    func presentAppOpenAd() async {
        guard !IAPManager.shared.isAdsRemoved else {
            log.info("📺 App Open Ad — reklamlar kaldırılmış, atlanıyor")
            return
        }
        guard let rootVC = rootViewController else { return }
        guard let ad = appOpenAd else {
            preloadAppOpenAd()
            return
        }
        appOpenAd = nil
        ad.present(from: rootVC)
        preloadAppOpenAd()
        log.info("📺 App Open Ad gösterildi")
    }

    // MARK: - Public API

    func notifyGameEnded() {
        let ud = UserDefaults.standard
        ud.set(ud.integer(forKey: kTotalGamesEver) + 1,      forKey: kTotalGamesEver)
        ud.set(ud.integer(forKey: kGamesSinceLastInter) + 1, forKey: kGamesSinceLastInter)
    }

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

    @discardableResult
    func presentInterstitial() async -> Bool {
        guard let rootVC = rootViewController else {
            log.error("📺 Interstitial: rootViewController bulunamadı")
            return false
        }

        guard let ad = interstitialAd else {
            log.info("📺 Interstitial henüz yüklenmedi, preload başlatılıyor")
            errorMessage = "Reklam şu an hazır değil."
            preloadInterstitial()
            return false
        }

        let ud = UserDefaults.standard
        ud.set(Date(), forKey: kLastInterstitialAt)
        ud.set(0,      forKey: kGamesSinceLastInter)

        ad.present(from: rootVC)
        interstitialAd = nil
        preloadInterstitial()
        log.info("📺 Interstitial gösterildi")
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

    @discardableResult
    func presentRewarded(_ kind: RewardKind) async -> Bool {
        guard canShowRewarded(kind) else {
            log.info("📺 Rewarded \(kind.rawValue) — cap doldu")
            return false
        }

        guard let rootVC = rootViewController else {
            log.error("📺 Rewarded: rootViewController bulunamadı")
            return false
        }

        guard let ad = rewardedAd else {
            log.info("📺 Rewarded henüz yüklenmedi, preload başlatılıyor")
            errorMessage = "Reklam şu an hazır değil. Lütfen daha sonra deneyin."
            preloadRewarded()
            return false
        }

        return await withCheckedContinuation { continuation in
            ad.present(from: rootVC) { [weak self] in
                guard let self else { continuation.resume(returning: false); return }
                let day = self.todayKey()
                let key = self.kRewardedUsed(kind, day: day)
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
                UserDefaults.standard.set(Date(), forKey: self.kLastRewardedAt)
                self.log.info("📺 Rewarded \(kind.rawValue) — kalan: \(self.remaining(kind))")
                self.rewardedAd = nil
                self.preloadRewarded()
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Helpers

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

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
