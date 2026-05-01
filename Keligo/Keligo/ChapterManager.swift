import Foundation
import Combine

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let difficulty: Difficulty
    let wordCount: Int
    let color: String
    let category: String?   // nil = tüm kategoriler (zorlukla filtrelenir)
    let requiredStars: Int  // ana menüde kilidi açmak için gereken toplam yıldız

    init(id: Int, title: String, subtitle: String, icon: String,
         difficulty: Difficulty, wordCount: Int, color: String,
         category: String? = nil, requiredStars: Int = 0) {
        self.id = id; self.title = title; self.subtitle = subtitle
        self.icon = icon; self.difficulty = difficulty; self.wordCount = wordCount
        self.color = color; self.category = category; self.requiredStars = requiredStars
    }
}

class ChapterManager: ObservableObject {
    static let shared = ChapterManager()
    private init() { load() }

    // MARK: - 20 Bölüm

    let chapters: [Chapter] = [
        // ── Kolay ────────────────────────────────────────────────────────
        Chapter(id:  0, title: "Hayvanlar",   subtitle: "Doğanın canlıları",      icon: "🦁", difficulty: .easy,   wordCount: 6,  color: "green",   category: "Hayvanlar",  requiredStars: 0),
        Chapter(id:  1, title: "Meyveler",    subtitle: "Tatlı ve sulu",           icon: "🍎", difficulty: .easy,   wordCount: 6,  color: "red",     category: "Meyveler",   requiredStars: 0),
        Chapter(id:  2, title: "Yiyecekler",  subtitle: "Türk mutfağından",        icon: "🥗", difficulty: .easy,   wordCount: 6,  color: "orange",  category: "Yiyecekler", requiredStars: 2),
        Chapter(id:  3, title: "Taşıtlar",    subtitle: "Hızlı ve yavaş",          icon: "🚗", difficulty: .easy,   wordCount: 6,  color: "blue",    category: "Taşıtlar",   requiredStars: 4),
        Chapter(id:  4, title: "Şehirler",    subtitle: "Türkiye'nin şehirleri",   icon: "🏙️", difficulty: .easy,   wordCount: 6,  color: "teal",    category: "Şehirler",   requiredStars: 6),

        // ── Normal ───────────────────────────────────────────────────────
        Chapter(id:  5, title: "Meslekler",   subtitle: "Kim ne iş yapar?",        icon: "👷", difficulty: .normal, wordCount: 7,  color: "purple",  category: "Meslekler",  requiredStars: 8),
        Chapter(id:  6, title: "Bitkiler",    subtitle: "Çiçekler ve ağaçlar",     icon: "🌿", difficulty: .normal, wordCount: 7,  color: "green",   category: "Bitkiler",   requiredStars: 10),
        Chapter(id:  7, title: "Spor",        subtitle: "Sahaya çık!",             icon: "⚽", difficulty: .normal, wordCount: 7,  color: "yellow",  category: "Spor",       requiredStars: 12),
        Chapter(id:  8, title: "Müzik",       subtitle: "Nota ve ritim",           icon: "🎵", difficulty: .normal, wordCount: 7,  color: "pink",    category: "Müzik",      requiredStars: 14),
        Chapter(id:  9, title: "Coğrafya",    subtitle: "Dünyayı keşfet",          icon: "🌍", difficulty: .normal, wordCount: 7,  color: "blue",    category: "Coğrafya",   requiredStars: 16),
        Chapter(id: 10, title: "Teknoloji",   subtitle: "Dijital dünya",           icon: "💻", difficulty: .normal, wordCount: 7,  color: "indigo",  category: "Teknoloji",  requiredStars: 18),
        Chapter(id: 11, title: "Karışık I",   subtitle: "Her şeyden biraz",        icon: "🎲", difficulty: .normal, wordCount: 8,  color: "orange",  category: nil,          requiredStars: 20),

        // ── Zor ──────────────────────────────────────────────────────────
        Chapter(id: 12, title: "Sanat",       subtitle: "Yaratıcı dünya",          icon: "🎨", difficulty: .hard,   wordCount: 8,  color: "rose",    category: "Sanat",      requiredStars: 24),
        Chapter(id: 13, title: "Tarih",       subtitle: "Geçmişe yolculuk",        icon: "🏛️", difficulty: .hard,   wordCount: 8,  color: "brown",   category: "Tarih",      requiredStars: 28),
        Chapter(id: 14, title: "Mitoloji",    subtitle: "Tanrılar ve kahramanlar", icon: "⚡", difficulty: .hard,   wordCount: 8,  color: "purple",  category: "Mitoloji",   requiredStars: 32),
        Chapter(id: 15, title: "Gezegenler",  subtitle: "Uzayın derinlikleri",     icon: "🪐", difficulty: .hard,   wordCount: 8,  color: "indigo",  category: "Gezegenler", requiredStars: 36),
        Chapter(id: 16, title: "Karışık II",  subtitle: "Zor kelimeler",           icon: "🔥", difficulty: .hard,   wordCount: 9,  color: "red",     category: nil,          requiredStars: 40),

        // ── Uzman ────────────────────────────────────────────────────────
        Chapter(id: 17, title: "Usta",        subtitle: "Zorlu kelimeler",         icon: "🏆", difficulty: .hard,   wordCount: 10, color: "gold",    category: nil,          requiredStars: 45),
        Chapter(id: 18, title: "Efsane",      subtitle: "Sınırlarını zorla",       icon: "💎", difficulty: .hard,   wordCount: 10, color: "diamond", category: nil,          requiredStars: 51),
        Chapter(id: 19, title: "İmparator",   subtitle: "Sadece gerçek ustalar",   icon: "👑", difficulty: .hard,   wordCount: 12, color: "rainbow", category: nil,          requiredStars: 57),
    ]

    // MARK: - State

    @Published var stars: [Int: Int] = [:]           // chapterId → 0..3
    @Published var playCounts: [Int: Int] = [:]       // chapterId → kaç kez başlandı (seed rotasyonu için)

    // MARK: - Word selection (rotating seed!)

    /// Her oynamada farklı kelimeler gelir — playCount seed'e dahil edilir.
    func words(for chapter: Chapter) -> [WordEntry] {
        let playCount = playCounts[chapter.id] ?? 0

        // Seed: chapterId * 9999 + playCount * 1337 + 42
        let seed = UInt64(chapter.id * 9999 + playCount * 1337 + 42)
        var rng = SeededRNG(seed: seed)

        // Kategori filtresi
        let base = chapter.category != nil
            ? WordList.words.filter { $0.category == chapter.category }
            : WordList.words

        // Zorluk filtresi (min/max harf)
        let pool = base.filter {
            $0.word.count >= chapter.difficulty.minWordLength &&
            $0.word.count <= chapter.difficulty.maxWordLength
        }

        var available = pool.isEmpty ? base : pool
        if available.isEmpty { available = WordList.words }

        var result: [WordEntry] = []
        for _ in 0..<chapter.wordCount {
            guard !available.isEmpty else { break }
            let idx = Int(rng.next() % UInt64(available.count))
            result.append(available[idx])
            available.remove(at: idx)
        }
        return result
    }

    /// Bölüm başlandığında çağır — seed rotasyonu için.
    func incrementPlayCount(for chapterId: Int) {
        playCounts[chapterId, default: 0] += 1
        savePlayCounts()
    }

    // MARK: - Results

    func recordResult(chapterId: Int, wins: Int, total: Int) {
        let s: Int
        switch wins {
        case total:      s = 3
        case total - 1: s = 2
        default:         s = wins > 0 ? 1 : 0
        }
        let current = stars[chapterId] ?? 0
        if s > current {
            stars[chapterId] = s
            saveStars()
        }
    }

    // MARK: - Unlocking

    func isUnlocked(_ chapter: Chapter) -> Bool {
        if chapter.requiredStars == 0 { return true }
        return totalStars >= chapter.requiredStars
    }

    var totalStars: Int {
        stars.values.reduce(0, +)
    }

    // MARK: - Persistence

    private func load() {
        if let d = UserDefaults.standard.data(forKey: "chapterStars"),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: d) {
            stars = decoded
        }
        if let d = UserDefaults.standard.data(forKey: "chapterPlayCounts"),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: d) {
            playCounts = decoded
        }
    }

    private func saveStars() {
        if let d = try? JSONEncoder().encode(stars) {
            UserDefaults.standard.set(d, forKey: "chapterStars")
        }
    }

    private func savePlayCounts() {
        if let d = try? JSONEncoder().encode(playCounts) {
            UserDefaults.standard.set(d, forKey: "chapterPlayCounts")
        }
    }
}
