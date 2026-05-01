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

        var cooldownDays: Int {
            switch self {
            case .losingStreak:    return 7
            case .allChaptersDone: return 30
            case .heavyHintUser:   return 14
            }
        }

        var title: String {
            switch self {
            case .losingStreak:    return "Tıkanma yaşıyorsun? 💪"
            case .allChaptersDone: return "Tüm bölümleri bitirdin! 🎉"
            case .heavyHintUser:   return "İpucu kullanırken jetonun mu eridi?"
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
            }
        }

        var ctaText: String { "Mağazayı Aç" }
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
