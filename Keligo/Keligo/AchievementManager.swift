import Foundation
import Combine

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool = false
}

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    private init() { load() }

    @Published var achievements: [Achievement] = [
        // --- İlk adımlar ---
        Achievement(id: "first_win",        title: "İlk Adım",            description: "İlk kelimeni doğru bul",                    icon: "🎯"),
        Achievement(id: "wins_10",          title: "Kelime Çırağı",       description: "10 oyun kazan",                             icon: "📖"),
        Achievement(id: "wins_25",          title: "Kelime Avcısı",       description: "25 oyun kazan",                             icon: "🎪"),
        Achievement(id: "wins_50",          title: "Efsane",              description: "50 oyun kazan",                             icon: "👑"),
        Achievement(id: "wins_100",         title: "Kelime Tanrısı",      description: "100 oyun kazan",                            icon: "🏆"),
        Achievement(id: "wins_250",         title: "İmparator",           description: "250 oyun kazan",                            icon: "👸"),
        // --- Günlük seri ---
        Achievement(id: "streak_3",         title: "Üç Üstüne",           description: "Günlük kelimeyi 3 gün üst üste bil",        icon: "🔥"),
        Achievement(id: "streak_5",         title: "Seri Başlangıcı",     description: "Günlük kelimeyi 5 gün üst üste bil",        icon: "🔥"),
        Achievement(id: "streak_7",         title: "Haftalık Seri",       description: "7 günlük kesintisiz galibiyet",             icon: "🔥🔥"),
        Achievement(id: "streak_10",        title: "Seri Ustası",         description: "10 günlük kesintisiz galibiyet",            icon: "🔥🔥"),
        Achievement(id: "streak_14",        title: "İki Hafta Kesintisiz",description: "14 günlük kesintisiz galibiyet",            icon: "🏅"),
        Achievement(id: "streak_30",        title: "Ay Şampiyonu",        description: "30 günlük kesintisiz galibiyet",            icon: "🏅"),
        Achievement(id: "streak_60",        title: "Efsane Seri",         description: "60 günlük kesintisiz galibiyet",            icon: "🌟"),
        // --- Mükemmellik ---
        Achievement(id: "perfect",          title: "Kusursuz",            description: "Hiç yanlış yapmadan kazan",                 icon: "⭐️"),
        Achievement(id: "no_hint",          title: "İpuçsuz Zafer",       description: "İpucu kullanmadan kelimeyi bil",            icon: "💡"),
        Achievement(id: "perfect_3",        title: "Hatasız Üçlü",        description: "3 kez sıfır hatayla kazan",                 icon: "💫"),
        Achievement(id: "perfect_10",       title: "Hatasız Usta",        description: "10 kez sıfır hatayla kazan",                icon: "✨"),
        // --- Bölüm ---
        Achievement(id: "chapter1",         title: "Bölüm Tamamlayıcı",  description: "Başlangıç bölümünü bitir",                  icon: "🏁"),
        Achievement(id: "all_chapters",     title: "Bölüm Ustası",        description: "Tüm bölümleri tamamla",                     icon: "🗺️"),
        Achievement(id: "chapter_3star",    title: "Üç Yıldız",           description: "Herhangi bir bölümü 3 yıldızla bitir",      icon: "⭐️⭐️⭐️"),
        // --- Hız ---
        Achievement(id: "speed_5",          title: "Hız Şampiyonu",       description: "Hız modunda 5 kelime çöz",                  icon: "⚡️"),
        Achievement(id: "speed_10",         title: "Rüzgar Gibi",         description: "Hız modunda 10 kelime çöz",                 icon: "💨"),
        Achievement(id: "speed_20",         title: "Şimşek",              description: "Hız modunda 20 kelime çöz",                 icon: "🌩️"),
        // --- Kategori ---
        Achievement(id: "categories_5",     title: "Kategori Gezgini",    description: "5 farklı kategoride kazan",                 icon: "🗂️"),
        Achievement(id: "categories_10",    title: "Keşifçi",             description: "10 farklı kategoride kazan",                icon: "🧭"),
        Achievement(id: "all_categories",   title: "Ansiklopedi",         description: "Tüm kategorilerde kazan",                   icon: "📚"),
        // --- Günlük oynama ---
        Achievement(id: "daily_5",          title: "Günlük Kahraman",     description: "Günlük kelimeyi 5 kez oyna",                icon: "📅"),
        Achievement(id: "daily_10",         title: "Gün Sayıcı",          description: "Günlük kelimeyi 10 kez oyna",               icon: "🗓️"),
        Achievement(id: "daily_30",         title: "Aylık Oyuncu",        description: "Günlük kelimeyi 30 kez oyna",               icon: "🎖️"),
        Achievement(id: "daily_100",        title: "Her Gün Burada",      description: "100 günlük kelime oyna",                    icon: "🏆"),
        // --- Toplam oyun ---
        Achievement(id: "games_played_50",  title: "Tecrübeli",           description: "Toplam 50 oyun oyna",                       icon: "🎮"),
        Achievement(id: "games_played_200", title: "Veteran",             description: "Toplam 200 oyun oyna",                      icon: "🎲"),
        // --- Haftalık ---
        Achievement(id: "weekly_first",     title: "Haftalık Meydan Okuyucu", description: "Bir haftalık meydan okumayı tamamla",   icon: "📆"),
        Achievement(id: "weekly_3",         title: "Hafta Sona Ermez",    description: "3 farklı haftalık meydan okumayı tamamla",  icon: "🗓️"),
    ]

    @Published var pendingToast: Achievement? = nil

    func check(stats: StatsManager, chapters: ChapterManager,
               wrongCount: Int = 99, hintUsed: Bool = false, won: Bool = true) {
        var newlyUnlocked: [Achievement] = []

        func unlock(_ id: String) {
            guard let idx = achievements.firstIndex(where: { $0.id == id }),
                  !achievements[idx].isUnlocked else { return }
            achievements[idx].isUnlocked = true
            newlyUnlocked.append(achievements[idx])
        }

        // Galibiyet sayısı
        if stats.wins >= 1   { unlock("first_win") }
        if stats.wins >= 10  { unlock("wins_10") }
        if stats.wins >= 25  { unlock("wins_25") }
        if stats.wins >= 50  { unlock("wins_50") }
        if stats.wins >= 100 { unlock("wins_100") }
        if stats.wins >= 250 { unlock("wins_250") }

        // Günlük galibiyet serisi
        if stats.currentStreak >= 3  { unlock("streak_3") }
        if stats.currentStreak >= 5  { unlock("streak_5") }
        if stats.currentStreak >= 7  { unlock("streak_7") }
        if stats.currentStreak >= 10 { unlock("streak_10") }
        if stats.currentStreak >= 14 { unlock("streak_14") }
        if stats.currentStreak >= 30 { unlock("streak_30") }
        if stats.currentStreak >= 60 { unlock("streak_60") }

        // Mükemmellik — sadece galibiyet durumunda
        if won {
            if wrongCount == 0 { unlock("perfect") }
            if !hintUsed       { unlock("no_hint") }  // ← artık sadece kazanınca

            // Hatasız sayacı (UserDefaults ile track et)
            if wrongCount == 0 {
                let key = "perfect_count"
                let n = UserDefaults.standard.integer(forKey: key) + 1
                UserDefaults.standard.set(n, forKey: key)
                if n >= 3  { unlock("perfect_3") }
                if n >= 10 { unlock("perfect_10") }
            }
        }

        // Bölüm
        if (chapters.stars[0] ?? 0) >= 1 { unlock("chapter1") }
        if chapters.chapters.allSatisfy({ (chapters.stars[$0.id] ?? 0) >= 1 }) {
            unlock("all_chapters")
        }
        if chapters.chapters.contains(where: { (chapters.stars[$0.id] ?? 0) >= 3 }) {
            unlock("chapter_3star")
        }

        // Hız modu
        if stats.speedHighScore >= 5  { unlock("speed_5") }
        if stats.speedHighScore >= 10 { unlock("speed_10") }
        if stats.speedHighScore >= 20 { unlock("speed_20") }

        // Kategori
        if stats.wonCategories.count >= 5  { unlock("categories_5") }
        if stats.wonCategories.count >= 10 { unlock("categories_10") }
        if stats.wonCategories.count >= WordList.categories.count { unlock("all_categories") }

        // Günlük oynama (toplam kümülatif)
        if stats.totalDailyPlays >= 5   { unlock("daily_5") }
        if stats.totalDailyPlays >= 10  { unlock("daily_10") }
        if stats.totalDailyPlays >= 30  { unlock("daily_30") }
        if stats.totalDailyPlays >= 100 { unlock("daily_100") }

        // Toplam oyun
        if stats.totalGames >= 50  { unlock("games_played_50") }
        if stats.totalGames >= 200 { unlock("games_played_200") }

        // Haftalık meydan okuma
        if WeeklyChallengeManager.shared.isWeekComplete() { unlock("weekly_first") }
        let completedWeeks = UserDefaults.standard.integer(forKey: "completedWeeksCount")
        if completedWeeks >= 3 { unlock("weekly_3") }

        save()

        if let first = newlyUnlocked.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.pendingToast = first
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.pendingToast = nil
                }
            }
        }
    }

    // MARK: Theme unlock rules (derived, not stored)

    func isThemeUnlocked(_ theme: AppTheme, stats: StatsManager, chapters: ChapterManager) -> Bool {
        switch theme {
        case .classic:  return true
        case .ocean:    return stats.wins >= 10
        case .forest:   return stats.currentStreak >= 7
        case .sunset:   return stats.wins >= 25 || chapters.chapters.contains { (chapters.stars[$0.id] ?? 0) >= 3 }
        case .midnight: return stats.wins >= 50
        // Premium themes — IAP ile açılır
        case .neon, .galaxy, .pastel, .vintage, .halloween, .chalk:
            return IAPManager.shared.isThemePackUnlocked
        }
    }

    func unlockRequirement(_ theme: AppTheme) -> String {
        switch theme {
        case .classic:    return ""
        case .ocean:      return "10 galibiyet"
        case .forest:     return "7 galibiyet serisi"
        case .sunset:     return "25 galibiyet veya bir bölümde 3 yıldız"
        case .midnight:   return "50 galibiyet"
        case .neon, .galaxy, .pastel, .vintage, .halloween, .chalk:
            return "Premium Tema Paketi"
        }
    }

    // MARK: Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "achievements"),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data) else { return }
        for a in decoded where a.isUnlocked {
            if let idx = achievements.firstIndex(where: { $0.id == a.id }) {
                achievements[idx].isUnlocked = true
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
}
