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
    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID     = "ca-app-pub-3940256099942544/1712485313"
    private let appOpenAdUnitID      = "ca-app-pub-3940256099942544/5575463023"
    #else
    private let interstitialAdUnitID = "ca-app-pub-2301774166987825/6849458927"
    private let rewardedAdUnitID     = "ca-app-pub-2301774166987825/8162540596"
    private let appOpenAdUnitID      = "ca-app-pub-2301774166987825/2243809555"
    #endif

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
        case letter, life, jetonBonus, streakSave, continueGame

        var dailyCap: Int {
            switch self {
            case .letter:       return AdManager.capLetterReveal
            case .life:         return AdManager.capLifeRefill
            case .jetonBonus:   return AdManager.capJetonBonus
            case .streakSave:   return AdManager.capStreakSave
            case .continueGame: return 999  // pratikte sınırsız
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
    /// Rewarded ad delegate — retained for the duration of ad presentation
    private var rewardDelegate: RewardedAdDelegateHandler?
    /// Rewarded ad şu an gösteriliyorsa true — App Open Ad'ın üste binmesini önler
    private var isShowingRewardedAd = false
    /// App Open Ad en son ne zaman gösterildi — Apple Guideline 4: soğuk açılışta gösterim yasak
    private let kLastAppOpenAt = "ad_lastAppOpenAt"
    /// App Open Ad'ın aralarındaki minimum süre (saniye) — Apple gözlemcisi 3 dk içinde görmemeli
    private let appOpenMinInterval: TimeInterval = 180
    /// Rewarded ad yükleme işlemi devam ediyorsa true — çift yüklemeyi önler
    private var isLoadingRewarded = false

    private init() {
        // Preload'lar MobileAds başladıktan sonra startPreloading() ile tetiklenir.
        // init()'te çağrılmaz — SDK henüz hazır değil.
    }

    /// MobileAds.shared.start tamamlandıktan hemen sonra çağır.
    /// Rewarded + Interstitial preload'larını başlatır.
    /// App Open Ad soğuk açılışta gösterilmez (Apple Guideline 4).
    func startPreloadingAndShowOpenAd() {
        // Rewarded her zaman preload edilir — "Remove Ads" satın alımı sadece
        // zorla gösterilen reklamları (interstitial, app open) kaldırır;
        // kullanıcının kendi isteğiyle izlediği rewarded reklamları kaldırmaz.
        preloadRewarded()

        guard !IAPManager.shared.isAdsRemoved else {
            log.info("📺 Interstitial/AppOpen preload atlandı — reklamlar kaldırılmış")
            return
        }
        preloadInterstitial()
        // Soğuk açılışta App Open Ad gösterilmez — sadece background→foreground geçişinde.
        // Apple Guideline 4: kullanıcı uygulamayı kullanmadan önce reklam görmemeli.
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
        guard !isLoadingRewarded else { return }
        isLoadingRewarded = true
        Task {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: rewardedAdUnitID, request: Request()
                )
                log.info("📺 Rewarded preloaded")
            } catch {
                log.error("📺 Rewarded preload failed: \(error.localizedDescription)")
            }
            isLoadingRewarded = false
        }
    }

    /// Rewarded ad'ı döndürür: önce preload'u dener, yoksa anında yükler.
    private func loadRewardedAdIfNeeded() async throws -> RewardedAd {
        if let ad = rewardedAd {
            rewardedAd = nil
            return ad
        }
        // Preload henüz hazır değil — hemen yükle (kullanıcıyı beklet)
        isLoadingRewarded = false  // mevcut preload task'ını geçersiz say
        log.info("📺 Rewarded on-demand yükleniyor...")
        let ad = try await RewardedAd.load(with: rewardedAdUnitID, request: Request())
        return ad
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

    /// Ön plana her gelişte çağır (scenePhase .active).
    /// Önceden yüklenmiş reklam varsa gösterir, yoksa sessizce geçer.
    func presentAppOpenAd() async {
        guard !IAPManager.shared.isAdsRemoved else {
            log.info("📺 App Open Ad — reklamlar kaldırılmış, atlanıyor")
            return
        }
        // Rewarded ad şu an gösteriliyorsa veya yakın zamanda izlendiyse atla
        guard !isShowingRewardedAd else {
            log.info("📺 App Open Ad — rewarded gösterimde, atlanıyor")
            return
        }
        if let lastRewarded = UserDefaults.standard.object(forKey: kLastRewardedAt) as? Date,
           Date().timeIntervalSince(lastRewarded) < 60 {
            log.info("📺 App Open Ad — rewarded yakın zamanda izlendi, atlanıyor")
            return
        }
        // Apple Guideline 4: Son gösterimden bu yana minimum süre geçmeli
        if let lastShown = UserDefaults.standard.object(forKey: kLastAppOpenAt) as? Date,
           Date().timeIntervalSince(lastShown) < appOpenMinInterval {
            log.info("📺 App Open Ad — minimum süre dolmadı, atlanıyor")
            return
        }
        guard let rootVC = rootViewController else { return }
        guard let ad = appOpenAd else {
            preloadAppOpenAd()
            return
        }
        appOpenAd = nil
        ad.present(from: rootVC)
        UserDefaults.standard.set(Date(), forKey: kLastAppOpenAt)
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

        // Preload hazırsa hemen kullan, değilse on-demand yükle
        let ad: RewardedAd
        do {
            ad = try await loadRewardedAdIfNeeded()
        } catch {
            log.error("📺 Rewarded yüklenemedi: \(error.localizedDescription)")
            errorMessage = "Reklam yüklenemedi. İnternet bağlantınızı kontrol edin."
            preloadRewarded()
            return false
        }

        isShowingRewardedAd = true

        let result = await withCheckedContinuation { continuation in
            var didResume = false

            let delegate = RewardedAdDelegateHandler {
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: false)
            }
            self.rewardDelegate = delegate
            ad.fullScreenContentDelegate = delegate

            ad.present(from: rootVC) { [weak self] in
                guard let self else {
                    if !didResume { didResume = true; continuation.resume(returning: false) }
                    return
                }
                didResume = true
                let day = self.todayKey()
                let key = self.kRewardedUsed(kind, day: day)
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
                UserDefaults.standard.set(Date(), forKey: self.kLastRewardedAt)
                self.log.info("📺 Rewarded \(kind.rawValue) — kalan: \(self.remaining(kind))")
                self.rewardDelegate = nil
                self.preloadRewarded()
                continuation.resume(returning: true)
            }
        }
        isShowingRewardedAd = false
        return result
    }

    // MARK: - Helpers

    private var rootViewController: UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController else { return nil }
        // Traverse up to the topmost presented VC.
        // Ads must be presented from the VC that currently owns the screen;
        // presenting from root fails when a sheet or alert is already on top.
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
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

// MARK: - Rewarded Ad Delegate

/// Handles rewarded ad dismiss / failure so the async continuation is always resumed.
final class RewardedAdDelegateHandler: NSObject, FullScreenContentDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    /// Called when ad closes (after reward callback if reward was earned, or alone if dismissed early)
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismiss()
    }

    /// Called when ad fails to present (e.g. already presenting another ad)
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismiss()
    }
}
