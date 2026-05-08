import SwiftUI

// MARK: - WordStatsView

struct WordStatsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }

    // Sorted category stats
    private var sortedCategories: [(category: String, wins: Int, games: Int)] {
        let cats = Set(Array(stats.categoryWins.keys) + Array(stats.categoryGames.keys))
        return cats.map { cat in
            (category: cat,
             wins: stats.categoryWins[cat] ?? 0,
             games: stats.categoryGames[cat] ?? 0)
        }
        .filter { $0.games > 0 }
        .sorted { $0.games > $1.games }
    }

    // Recent history grouped by result
    private var historyWins: [GameHistoryEntry] {
        stats.gameHistory.filter { $0.won }
    }
    private var historyLosses: [GameHistoryEntry] {
        stats.gameHistory.filter { !$0.won }
    }

    // Best game: fewest wrong guesses among wins
    private var bestGame: GameHistoryEntry? {
        historyWins.min { $0.wrongCount < $1.wrongCount }
    }

    // Hardest category (lowest win rate)
    private var hardestCategory: String? {
        sortedCategories
            .filter { $0.games >= 3 }
            .min { winRate($0) < winRate($1) }?
            .category
    }

    // Easiest category (highest win rate)
    private var easiestCategory: String? {
        sortedCategories
            .filter { $0.games >= 3 }
            .max { winRate($0) < winRate($1) }?
            .category
    }

    private func winRate(_ item: (category: String, wins: Int, games: Int)) -> Double {
        item.games == 0 ? 0 : Double(item.wins) / Double(item.games)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // MARK: - Overview cards
                        overviewSection

                        // MARK: - Highlights
                        if bestGame != nil || hardestCategory != nil {
                            highlightsSection
                        }

                        // MARK: - Category breakdown
                        if !sortedCategories.isEmpty {
                            categorySection
                        }

                        // MARK: - Recent history
                        if !stats.gameHistory.isEmpty {
                            recentHistorySection
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Kelime İstatistikleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Genel Bakış")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile(icon: "gamecontroller.fill", label: "Toplam Oyun", value: "\(stats.totalGames)", color: t.accent)
                statTile(icon: "trophy.fill", label: "Galibiyet", value: "\(stats.wins)", color: .green)
                statTile(icon: "xmark.circle.fill", label: "Mağlubiyet", value: "\(stats.losses)", color: .red)
                statTile(icon: "percent", label: "Kazanma Oranı",
                         value: stats.totalGames > 0 ? "%\(Int(stats.winRate))" : "—",
                         color: stats.winRate >= 50 ? .green : .orange)
                statTile(icon: "flame.fill", label: "En İyi Seri", value: "\(stats.bestStreak)", color: .orange)
                statTile(icon: "bolt.fill", label: "Hız Rekoru", value: "\(stats.speedHighScore)", color: .purple)
                statTile(icon: "star.fill", label: "XP", value: "\(stats.xp)", color: .yellow)
                statTile(icon: "person.fill", label: "Seviye", value: "Sv.\(stats.level) · \(stats.levelTitle)", color: t.accent)
            }
        }
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Öne Çıkanlar")
            VStack(spacing: 10) {
                if let best = bestGame {
                    highlightRow(
                        icon: "star.fill",
                        color: .yellow,
                        title: "En İyi Kelime",
                        subtitle: "\(best.word) · \(best.wrongCount) hata · \(best.category)"
                    )
                }
                if let easy = easiestCategory,
                   let item = sortedCategories.first(where: { $0.category == easy }) {
                    highlightRow(
                        icon: "face.smiling.fill",
                        color: .green,
                        title: "En Kolay Kategori",
                        subtitle: "\(easy) · %\(Int(winRate(item) * 100)) kazanma"
                    )
                }
                if let hard = hardestCategory,
                   let item = sortedCategories.first(where: { $0.category == hard }) {
                    highlightRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        title: "En Zor Kategori",
                        subtitle: "\(hard) · %\(Int(winRate(item) * 100)) kazanma"
                    )
                }
                if stats.wonCategories.count > 0 {
                    highlightRow(
                        icon: "tag.fill",
                        color: .blue,
                        title: "Farklı Kategoriler",
                        subtitle: "\(stats.wonCategories.count) kategoride galibiyet var"
                    )
                }
            }
            .padding(14)
            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Categories

    private var categorySection: some View {
        VStack(spacing: 12) {
            sectionTitle("Kategori Dağılımı")
            VStack(spacing: 0) {
                ForEach(Array(sortedCategories.enumerated()), id: \.offset) { idx, item in
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(t.primaryText)
                            Spacer()
                            Text("\(item.wins)/\(item.games)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.secondaryText)
                            Text("%\(Int(winRate(item) * 100))")
                                .font(.caption.weight(.bold))
                                .foregroundColor(winRate(item) >= 0.5 ? .green : .red)
                                .frame(width: 36, alignment: .trailing)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(t.surface)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(winRate(item) >= 0.5 ? Color.green : Color.orange)
                                    .frame(width: geo.size.width * CGFloat(winRate(item)), height: 6)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: item.wins)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    if idx < sortedCategories.count - 1 {
                        Divider().background(t.secondaryText.opacity(0.15))
                    }
                }
            }
            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Recent history

    private var recentHistorySection: some View {
        VStack(spacing: 12) {
            sectionTitle("Son Oyunlar")
            VStack(spacing: 0) {
                ForEach(stats.gameHistory.prefix(10)) { entry in
                    HStack(spacing: 12) {
                        Text(entry.won ? "✅" : "❌")
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.word)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(t.primaryText)
                            Text("\(entry.category) · \(entry.mode)")
                                .font(.caption)
                                .foregroundColor(t.secondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(entry.wrongCount)/\(entry.maxWrong) hata")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(entry.wrongCount == 0 ? .yellow : t.secondaryText)
                            Text(relativeDate(entry.date))
                                .font(.caption2)
                                .foregroundColor(t.secondaryText)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    if entry.id != (stats.gameHistory.prefix(10).last?.id) {
                        Divider().background(t.secondaryText.opacity(0.15))
                    }
                }
            }
            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(t.secondaryText)
            Spacer()
        }
    }

    private func statTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(t.primaryText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundColor(t.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func highlightRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(t.secondaryText)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(t.primaryText)
            }
            Spacer()
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "Az önce" }
        if diff < 86400 { return "\(Int(diff / 3600)) saat önce" }
        if diff < 604800 { return "\(Int(diff / 86400)) gün önce" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }
}

#Preview {
    WordStatsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
}
