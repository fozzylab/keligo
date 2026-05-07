import Foundation
import Combine

/// Doğru anda doğru CTA göstermek için merkezi prompt yöneticisi.
/// 3. ardışık kayıp, tüm bölümler bitti, tüm temalar açık vb. tetikleyiciler.
@MainActor
final class AppPromptManager: ObservableObject {
    static let shared = AppPromptManager()

    enum PromptKind: String, CaseIterable {
        case losingStreak       // 3 ardışık kayıp → Premium upsell
        case allChaptersDone    // Tüm bölümler bitti → premium pack CTA
        case heavyHintUser      // Çok jeton harcayan kullanıcı → bundle CTA
        case lowOnLives         // 1 can kaldı → life refill CTA
        case lowOnJetons        // Jeton < 100 → jeton pack CTA
        case streakAtRisk       // 4+ seri → streak protection CTA
        case firstPurchaseOffer // İlk satın alma teklifi

        var cooldownDays: Int {
            switch self {
            case .losingStreak:    return 7
            case .allChaptersDone: return 30
            case .heavyHintUser:   return 14
            case .lowOnLives:      return 3
            case .lowOnJetons:     return 5
            case .streakAtRisk:    return 7
            case .firstPurchaseOffer: return 999 // Once only
            }
        }

        var title: String {
            switch self {
            case .losingStreak:    return "Tıkanma yaşıyorsun? 💪"
            case .allChaptersDone: return "Tüm bölümleri bitirdin! 🎉"
            case .heavyHintUser:   return "İpucu kullanırken jetonun mu eridi?"
            case .lowOnLives:      return "Son Canın Kaldı! ❤️"
            case .lowOnJetons:     return "Jetonların Azalıyor 🟡"
            case .streakAtRisk:    return "Serin Tehlikede! 🔥"
            case .firstPurchaseOffer: return "Yeni Oyuncu Özel! 🎁"
            }
        }

        var subtitle: String {
            switch self {
            case .losingStreak:
                return "Premium paketle 200+ ekstra kelime ve sınırsız can ile akışın bozulmasın."
            case .allChaptersDone:
                return "Premium kelime paketleriyle bilim, tarih, spor ve müzik dünyasına dal."
            case .heavyHintUser:
                return "5.000 jeton + sınırsız can + tüm paketler = Premium Paket. Tek seferlik %50 tasarruf."
            case .lowOnLives:
                return "Canların tükenmek üzere. Mağazadan anında doldur veya reklam izle."
            case .lowOnJetons:
                return "Jeton paketi al veya reklam izleyerek hızlıca jeton kazan."
            case .streakAtRisk:
                return "Seri korumayı unutma! Bir sonraki kayıpta tüm serin sıfırlanacak."
            case .firstPurchaseOffer:
                return "Sadece bugün: Başlangıç Paketi — 1.000 jeton + özel tema sadece ₺9.99!"
            }
        }

        var ctaText: String {
            switch self {
            case .firstPurchaseOffer: return "Hemen Al"
            default: return "Mağazayı Aç"
            }
        }
    }

    // MARK: - State
    @Published var current: PromptKind?

    // MARK: - Persistence keys
    private let kConsecutiveLosses = "prompt_consecutiveLosses"
    private func kLastShown(_ kind: PromptKind) -> String { "prompt_lastShown_\(kind.rawValue)" }

    private init() {}

    // MARK: - Triggers (oyun olaylarından çağrılır)

    /// Oyun bittikten sonra çağır. `won == false` ise art arda kayıp sayacını arttırır.
    func notifyGameEnded(won: Bool) {
        let ud = UserDefaults.standard
        if won {
            ud.set(0, forKey: kConsecutiveLosses)
        } else {
            let n = ud.integer(forKey: kConsecutiveLosses) + 1
            ud.set(n, forKey: kConsecutiveLosses)
            if n >= 3 && eligible(.losingStreak) && !IAPManager.shared.isUnlimitedLives {
                show(.losingStreak)
                ud.set(0, forKey: kConsecutiveLosses)
            }
        }
    }

    /// ChapterSelectView her açıldığında veya bölüm tamamlandığında çağır.
    func notifyChapterStateChanged() {
        let chapters = ChapterManager.shared
        let allDone = chapters.chapters.allSatisfy { (chapters.stars[$0.id] ?? 0) >= 1 }
        if allDone && eligible(.allChaptersDone) && !IAPManager.shared.isPackUnlocked("premium_bundle") {
            show(.allChaptersDone)
        }
    }

    /// Düşük can kontrolü
    func notifyLowLives(currentLives: Int) {
        guard currentLives == 1, eligible(.lowOnLives), !IAPManager.shared.isUnlimitedLives else { return }
        show(.lowOnLives)
    }
    
    /// Düşük jeton kontrolü
    func notifyLowJetons(balance: Int) {
        guard balance < 100, eligible(.lowOnJetons) else { return }
        show(.lowOnJetons)
    }
    
    /// Seri risk kontrolü
    func notifyStreakAtRisk(streak: Int) {
        guard streak >= 4, eligible(.streakAtRisk) else { return }
        show(.streakAtRisk)
    }
    
    /// İlk satın alma teklifi
    func notifyFirstPurchaseEligible(gamesPlayed: Int) {
        guard gamesPlayed >= 3, eligible(.firstPurchaseOffer) else { return }
        show(.firstPurchaseOffer)
    }
    
    /// Jeton harcama sonrası — eğer kullanıcı az sürede çok harcadıysa (7 gün içinde 1000+) tetikle.
    func notifyHintSpent(amount: Int) {
        let key = "prompt_jetonSpent7d"
        let dateKey = "prompt_jetonSpent7dStart"
        let ud = UserDefaults.standard
        let now = Date()
        if let start = ud.object(forKey: dateKey) as? Date,
           now.timeIntervalSince(start) > 7 * 24 * 3600 {
            ud.set(0, forKey: key)
            ud.set(now, forKey: dateKey)
        } else if ud.object(forKey: dateKey) == nil {
            ud.set(now, forKey: dateKey)
        }
        let total = ud.integer(forKey: key) + amount
        ud.set(total, forKey: key)
        if total >= 1000 && eligible(.heavyHintUser) && !IAPManager.shared.isPackUnlocked("premium_bundle") {
            show(.heavyHintUser)
        }
    }

    // MARK: - Public API

    func dismiss() { current = nil }

    func reset(_ kind: PromptKind) {
        UserDefaults.standard.removeObject(forKey: kLastShown(kind))
    }

    // MARK: - Private

    private func eligible(_ kind: PromptKind) -> Bool {
        guard let last = UserDefaults.standard.object(forKey: kLastShown(kind)) as? Date else { return true }
        let elapsed = Date().timeIntervalSince(last)
        return elapsed >= TimeInterval(kind.cooldownDays * 24 * 3600)
    }

    private func show(_ kind: PromptKind) {
        UserDefaults.standard.set(Date(), forKey: kLastShown(kind))
        current = kind
    }
}
