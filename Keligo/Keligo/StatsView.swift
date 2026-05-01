import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showHistory = false
    @State private var showReports = false

    var t: AppTheme { settings.theme }

    // MARK: - Computed helpers

    var favoriteCategory: String? {
        stats.categoryWins.max(by: { $0.value < $1.value })?.key
    }

    var estimatedMinutes: Int { stats.totalGames * 3 }
    var timeLabel: String {
        if estimatedMinutes < 60 { return "\(estimatedMinutes) dk" }
        return "\(estimatedMinutes / 60) sa \(estimatedMinutes % 60) dk"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // XP & Level card
                        xpLevelCard

                        // Win rate ring + stat grid
                        winRateSection

                        // 30-day calendar
                        calendarSection

                        // Category breakdown
                        if !stats.categoryGames.isEmpty {
                            categorySection
                        }

                        // Quick fun facts strip
                        funFactsStrip

                        // Best word
                        if stats.bestWordWrong < 99 {
                            bestWordSection
                        }

                        // 7-day chart
                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle("Son 7 Gün")
                            WeekChart(days: stats.last7Days, theme: t).padding(.horizontal)
                        }

                        // Game history button
                        Button {
                            showHistory = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(t.accentGradient)
                                Text("Oyun Geçmişi")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(t.primaryText)
                                Spacer()
                                Text("\(stats.gameHistory.count) oyun")
                                    .font(.caption)
                                    .foregroundColor(t.secondaryText)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(t.secondaryText)
                            }
                            .padding(16)
                            .background(t.surface, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        // Leaderboard shortcut
                        Button {
                            GameCenterManager.shared.showXPLeaderboard()
                        } label: {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(t.accent)
                        }
                        // Pending word reports
                        Button {
                            showReports = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(t.accent)
                                let c = WordReportManager.shared.count
                                if c > 0 {
                                    Text("\(c)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(3)
                                        .background(Color.red, in: Circle())
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
            .sheet(isPresented: $showHistory) {
                GameHistoryView()
                    .environmentObject(stats)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showReports) {
                PendingReportsView()
                    .environmentObject(settings)
            }
        }
    }

    // MARK: - Section title helper

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(t.primaryText)
            .padding(.horizontal, 20)
    }

    // MARK: - XP / Level card

    private var xpLevelCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seviye \(stats.level)")
                        .font(.title2.bold())
                        .foregroundColor(t.primaryText)
                    Text(stats.levelTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(t.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.xp) XP")
                        .font(.title3.bold())
                        .foregroundColor(t.primaryText)
                    Text("Sonraki: \(stats.xpForNextLevel) XP")
                        .font(.caption2)
                        .foregroundColor(t.secondaryText)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(t.surface)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(t.accentGradient)
                        .frame(width: geo.size.width * CGFloat(stats.levelProgress), height: 10)
                        .animation(.easeInOut(duration: 0.8), value: stats.levelProgress)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(t.surface)
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Win-rate ring + stat grid

    private var winRateSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(t.surface, lineWidth: 16).frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: CGFloat(stats.winRate / 100))
                    .stroke(t.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.9), value: stats.winRate)
                VStack(spacing: 2) {
                    Text("\(Int(stats.winRate))%")
                        .font(.title2.bold()).foregroundColor(t.primaryText)
                    Text("Kazanma").font(.caption).foregroundColor(t.secondaryText)
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                StatCard(label: "Toplam Oyun",  value: "\(stats.totalGames)",    icon: "gamecontroller.fill", theme: t)
                StatCard(label: "Kazanılan",    value: "\(stats.wins)",           icon: "trophy.fill",         theme: t)
                StatCard(label: "Kaybedilen",   value: "\(stats.losses)",         icon: "xmark.circle.fill",   theme: t)
                StatCard(label: "Mevcut Seri",  value: "\(stats.currentStreak)",  icon: "flame.fill",          theme: t)
                // En İyi Seri — vurgulu gradient kart
                BestStreakCard(bestStreak: stats.bestStreak, theme: t)
                StatCard(label: "Hız Rekoru",   value: "\(stats.speedHighScore)", icon: "bolt.fill",           theme: t)
                // Tahmini oyun süresi
                StatCard(label: "Oyun Süresi",  value: timeLabel,                 icon: "clock.fill",          theme: t)
                // Favori kategori
                if let fav = favoriteCategory {
                    StatCard(label: "Favori",   value: fav,                       icon: "star.circle.fill",    theme: t)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 30-day activity calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("30 Günlük Aktivite")

            let days = stats.last30Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(calendarColor(day))
                        .frame(height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                calendarLegend(color: t.correct, label: "Kazandı")
                calendarLegend(color: t.wrong.opacity(0.7), label: "Kaybetti")
                calendarLegend(color: t.surface, label: "Oynamadı")
            }
            .padding(.horizontal, 20)
        }
    }

    private func calendarColor(_ day: CalendarDay) -> Color {
        if !day.played { return t.surface }
        return day.won ? t.correct.opacity(0.85) : t.wrong.opacity(0.55)
    }

    private func calendarLegend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(label).font(.caption2).foregroundColor(t.secondaryText)
        }
    }

    // MARK: - Category breakdown

    private var sortedCategories: [(key: String, value: Int)] {
        stats.categoryGames.sorted(by: { $0.value > $1.value })
    }

    private func categoryBadge(index: Int) -> String? {
        switch index { case 0: return "🥇"; case 1: return "🥈"; case 2: return "🥉"; default: return nil }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Kategori Başarısı")

            VStack(spacing: 8) {
                ForEach(Array(sortedCategories.prefix(6).enumerated()), id: \.element.key) { idx, pair in
                    let total = pair.value
                    let wins  = stats.categoryWins[pair.key] ?? 0
                    let rate  = total > 0 ? Double(wins) / Double(total) : 0

                    VStack(spacing: 4) {
                        HStack {
                            if let badge = categoryBadge(index: idx) {
                                Text(badge).font(.caption)
                            }
                            Text(pair.key)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.primaryText)
                            Spacer()
                            Text("\(wins)/\(total)")
                                .font(.caption2)
                                .foregroundColor(t.secondaryText)
                            Text("\(Int(rate * 100))%")
                                .font(.caption.weight(.bold))
                                .foregroundColor(rate >= 0.5 ? t.correct : t.wrong)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(t.surface).frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(rate >= 0.5 ? t.correct : t.wrong)
                                    .frame(width: geo.size.width * rate, height: 6)
                                    .animation(.easeInOut(duration: 0.6), value: rate)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(14)
            .background(t.surface)
            .cornerRadius(12)
            .padding(.horizontal)

            // Top category achievement badge
            if let top = sortedCategories.first {
                HStack(spacing: 10) {
                    Text("🏆").font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("En Güçlü Kategori")
                            .font(.caption2).foregroundColor(t.secondaryText)
                        Text(top.key)
                            .font(.subheadline.weight(.bold)).foregroundColor(t.primaryText)
                    }
                    Spacer()
                    let wr = top.value > 0 ? Double(stats.categoryWins[top.key] ?? 0) / Double(top.value) * 100 : 0
                    Text("\(Int(wr))% kazanma")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(t.accent)
                }
                .padding(12)
                .background(t.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Fun facts strip

    private var funFactsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Eğlenceli İstatistikler")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    funFact(icon: "clock.fill",       value: timeLabel,                     label: "Toplam Süre",    color: t.accent)
                    funFact(icon: "calendar",          value: "\(stats.totalDailyPlays)",    label: "Günlük Oynanan", color: .orange)
                    funFact(icon: "percent",           value: "\(Int(stats.winRate))%",      label: "Galibiyet Oranı", color: .green)
                    if stats.currentStreak > 0 {
                        funFact(icon: "flame.fill",   value: "\(stats.currentStreak) gün",  label: "Aktif Seri",     color: .orange)
                    }
                    funFact(icon: "star.fill",         value: "Sv. \(stats.level)",          label: stats.levelTitle,  color: .yellow)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func funFact(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(t.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(t.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 88)
        .padding(.vertical, 14)
        .background(t.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Best word section

    private var bestWordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("En İyi Başarı")
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("En az hatayla kazanılan")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                    Text("\(stats.bestWordWrong) yanlış tahminle")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                }
                Spacer()
            }
            .padding(14)
            .background(t.surface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - 7-day bar chart

struct WeekChart: View {
    let days: [ChartDay]
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Gün", day.label),
                        y: .value("Kazandı", day.wins)
                    )
                    .foregroundStyle(theme.correct.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Gün", day.label),
                        y: .value("Kaybetti", day.losses)
                    )
                    .foregroundStyle(theme.wrong.opacity(0.7).gradient)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s).font(.caption).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let n = value.as(Int.self) {
                            Text("\(n)").font(.caption2).foregroundColor(theme.secondaryText)
                        }
                    }
                    AxisGridLine().foregroundStyle(theme.surface)
                }
            }
            .frame(height: 150)
            .padding(12)
            .background(theme.surface)
            .cornerRadius(12)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(theme.correct).frame(width: 8, height: 8)
                    Text("Kazandı").font(.caption).foregroundColor(theme.secondaryText)
                }
                HStack(spacing: 6) {
                    Circle().fill(theme.wrong.opacity(0.7)).frame(width: 8, height: 8)
                    Text("Kaybetti").font(.caption).foregroundColor(theme.secondaryText)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Best streak highlight card

struct BestStreakCard: View {
    let bestStreak: Int
    let theme: AppTheme

    private var gradient: LinearGradient {
        if bestStreak >= 7 {
            return LinearGradient(colors: [Color(red: 1.0, green: 0.80, blue: 0.10), Color(red: 1.0, green: 0.55, blue: 0.05)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if bestStreak >= 3 {
            return LinearGradient(colors: [Color(red: 1.0, green: 0.50, blue: 0.10), Color(red: 1.0, green: 0.30, blue: 0.05)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [theme.surface, theme.surface],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var textColor: Color {
        bestStreak >= 3 ? .white : theme.primaryText
    }

    private var labelColor: Color {
        bestStreak >= 3 ? Color.white.opacity(0.80) : theme.secondaryText
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundColor(bestStreak >= 3 ? .white : theme.accent)
            Text("\(bestStreak)")
                .font(.title2.bold())
                .foregroundColor(textColor)
            Text("En İyi Seri")
                .font(.caption)
                .foregroundColor(labelColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(gradient, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: bestStreak >= 7
                    ? Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.4)
                    : (bestStreak >= 3 ? Color.orange.opacity(0.3) : .clear),
                radius: 8, y: 4)
    }
}

// MARK: - Stat card

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(theme.accent)
            Text(value).font(.title2.bold()).foregroundColor(theme.primaryText)
            Text(label).font(.caption).foregroundColor(theme.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(theme.surface).cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .environmentObject(StatsManager())
        .environmentObject(SettingsViewModel())
}
