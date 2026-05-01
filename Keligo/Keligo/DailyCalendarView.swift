import SwiftUI

// MARK: - Wrapper so Date can be used with sheet(item:)

struct CalendarDayItem: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - Monthly calendar

struct DailyCalendarView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayMonth: Date = Date()
    @State private var showGameForDate: Date? = nil
    @State private var resultItem: CalendarDayItem? = nil
    @State private var pendingDate: Date? = nil
    @State private var showJetonAlert = false
    @State private var showRetryLossAlert = false   // replay a lost day
    @State private var notEnoughJetons = false
    @State private var refreshToken = UUID()   // forces grid re-render after game

    private let daily = DailyWordManager.shared
    private let weekLabels = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]

    var t: AppTheme { settings.theme }

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    t.background.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            todayBanner
                            monthHeader
                            monthTrophyBanner
                            weekdayRow
                            calendarGrid
                                .id(refreshToken) // re-render when token changes
                            legend
                            Spacer(minLength: 24)
                        }
                        .padding(.top, 4)
                    }
                }
                .navigationTitle("Günlük Takvim")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                    }
                }
                .alert("Geçmiş Gün Oyna", isPresented: $showJetonAlert, presenting: pendingDate) { date in
                    Button("Oyna (\(DailyWordManager.costPastDay) 🪙)") {
                        if jetons.spend(DailyWordManager.costPastDay) {
                            withAnimation(.easeInOut) { showGameForDate = date }
                        }
                        pendingDate = nil
                    }
                    Button("İptal", role: .cancel) { pendingDate = nil }
                } message: { date in
                    Text("\(dateLabel(date)) tarihini oynamak \(DailyWordManager.costPastDay) jeton harcar.\nBakiye: \(jetons.balance) jeton")
                }
                .alert("Tekrar Dene!", isPresented: $showRetryLossAlert, presenting: pendingDate) { date in
                    Button("Tekrar Oyna (\(DailyWordManager.costPastDay) 🪙)") {
                        if jetons.spend(DailyWordManager.costPastDay) {
                            withAnimation(.easeInOut) { showGameForDate = date }
                        }
                        pendingDate = nil
                    }
                    Button("Sonucu Gör") {
                        resultItem = CalendarDayItem(date: date)
                        pendingDate = nil
                    }
                    Button("İptal", role: .cancel) { pendingDate = nil }
                } message: { date in
                    Text("❌ \(dateLabel(date)) gününde kaybettin.\nTekrar denemek \(DailyWordManager.costPastDay) jeton harcar.\nBakiye: \(jetons.balance) jeton")
                }
                .alert("Yetersiz Jeton", isPresented: $notEnoughJetons) {
                    Button("Tamam", role: .cancel) {}
                } message: {
                    Text("Bu günü oynamak için \(DailyWordManager.costPastDay) jetona ihtiyacın var.\nMağazadan jeton satın alabilirsin.")
                }
                .sheet(item: $resultItem) { item in
                    DayResultSheet(date: item.date, theme: t)
                }
            }

            // Full-screen game overlay (slides over the calendar sheet)
            if let date = showGameForDate {
                DailyGameView(
                    settings: settings,
                    stats: stats,
                    date: date,
                    onBack: {
                        withAnimation(.easeInOut) { showGameForDate = nil }
                        refreshToken = UUID()
                    }
                )
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(AchievementManager.shared)
                .environmentObject(jetons)
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showGameForDate != nil)
    }

    // MARK: - Today banner

    private var todayBanner: some View {
        let played = daily.hasPlayedToday
        let result = daily.todayResult
        let entry  = daily.todayWord

        return Button {
            if !played { withAnimation(.easeInOut) { showGameForDate = Date() } }
            else { resultItem = CalendarDayItem(date: Date()) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(played
                            ? (result?.won == true
                                ? LinearGradient(colors: [.green, Color(red: 0.1, green: 0.75, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.red.opacity(0.8), .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : LinearGradient(colors: [t.accent, t.accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text(played ? (result?.won == true ? "✅" : "❌") : "📅")
                        .font(.title2)
                }
                .shadow(color: played ? (result?.won == true ? Color.green.opacity(0.4) : Color.red.opacity(0.4)) : t.accent.opacity(0.4),
                        radius: 8, y: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(played ? (result?.won == true ? "Bugün Kazandın! 🎉" : "Bugün Kaybettin") : "Bugünü Oyna!")
                        .font(.headline.weight(.bold))
                        .foregroundColor(played ? (result?.won == true ? .green : .red) : t.primaryText)
                    Text(played
                        ? "\(entry.category) · \(entry.word.filter { $0 != " " }.count) harf"
                        : "\(entry.category) · \(entry.word.filter { $0 != " " }.count) harf · Dokunarak başla")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }

                Spacer()

                Image(systemName: played ? "chevron.right" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(played ? t.secondaryText : t.accent)
            }
            .padding(14)
            .background(
                played
                    ? AnyShapeStyle(t.cardMaterial)
                    : AnyShapeStyle(t.accent.opacity(0.12)),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(played ? Color.clear : t.accent.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Monthly trophy banner

    private var monthTrophyBanner: some View {
        let (won, total, allWon) = monthProgress

        // Different trophy emoji per month
        let monthTrophies = ["🏆","🥇","🎖️","💎","🌟","🏅","✨","🎯","🪄","🎪","🔮","🎁"]
        let monthIndex = Calendar.current.component(.month, from: displayMonth) - 1
        let trophy = monthTrophies[monthIndex % monthTrophies.count]

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(allWon && total > 0
                        ? AnyShapeStyle(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(t.surface))
                    .frame(width: 46, height: 46)
                Text(trophy)
                    .font(.system(size: 24))
                    .opacity(total == 0 ? 0.3 : 1.0)
                    .scaleEffect(allWon && total > 0 ? 1.1 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: allWon)
            }
            .shadow(color: allWon && total > 0 ? Color.yellow.opacity(0.55) : .clear, radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(allWon && total > 0 ? "Mükemmel Ay! 🎉" : "Aylık İlerleme")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(allWon && total > 0 ? .yellow : t.primaryText)
                Text(total == 0
                    ? "Henüz oynanmadı"
                    : "\(won) galibiyet / \(total) oynanan gün")
                    .font(.caption)
                    .foregroundColor(t.secondaryText)
            }

            Spacer()

            // Circular progress
            ZStack {
                Circle()
                    .stroke(t.surface, lineWidth: 5)
                    .frame(width: 38, height: 38)
                Circle()
                    .trim(from: 0, to: total > 0 ? CGFloat(won) / CGFloat(total) : 0)
                    .stroke(
                        allWon ? Color.yellow : t.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: won)
                Text(total > 0 ? "\(Int(Double(won)/Double(total)*100))%" : "—")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(t.primaryText)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            allWon && total > 0
                ? AnyShapeStyle(LinearGradient(
                    colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.08)],
                    startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(t.cardMaterial),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(allWon && total > 0 ? Color.yellow.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
    }

    private var monthProgress: (won: Int, total: Int, allWon: Bool) {
        let dates = daily.calendarDates(for: displayMonth).compactMap { $0 }
        // Only consider days up to today (not future)
        let playable = dates.filter { !daily.isFuture($0) }
        let results = playable.compactMap { daily.result(for: $0) }
        let wonCount = results.filter { $0.won }.count
        let totalPlayed = results.count
        // "all won" = every non-future day has been played AND won
        let allWon = !playable.isEmpty && playable.allSatisfy { daily.result(for: $0)?.won == true }
        return (wonCount, totalPlayed, allWon)
    }

    // MARK: - Month header

    private var monthHeader: some View {
        HStack {
            Button {
                displayMonth = daily.cal.date(byAdding: .month, value: -1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(canGoBack ? t.accent : t.secondaryText.opacity(0.25))
            }
            .disabled(!canGoBack)

            Spacer()

            Text(monthTitle)
                .font(.title3.weight(.bold))
                .foregroundColor(t.primaryText)

            Spacer()

            Button {
                displayMonth = daily.cal.date(byAdding: .month, value: 1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(canGoForward ? t.accent : t.secondaryText.opacity(0.25))
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
    }

    // MARK: - Weekday labels

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekLabels, id: \.self) { label in
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(t.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        let dates = daily.calendarDates(for: displayMonth)
        let rows  = (dates.count + 6) / 7

        return VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<7) { col in
                        let idx = row * 7 + col
                        if idx < dates.count, let date = dates[idx] {
                            DayCell(date: date, theme: t) { handleTap(date) }
                        } else {
                            Color.clear
                                .frame(height: 58)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 20) {
            legendItem("✅", "Kazandın")
            legendItem("❌", "Kaybettin")
            legendItem("🔒", "Kilitli")
            legendItem("🪙", "Ücretli")
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func legendItem(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(icon).font(.caption)
            Text(label).font(.caption2).foregroundColor(t.secondaryText)
        }
    }

    // MARK: - Tap handler

    private func handleTap(_ date: Date) {
        guard !daily.isFuture(date) else { return }

        if daily.hasPlayed(date) {
            // If lost on a past day → offer retry for jetons
            if let result = daily.result(for: date), !result.won, daily.isPast(date) {
                pendingDate = date
                if jetons.canAfford(DailyWordManager.costPastDay) {
                    showRetryLossAlert = true
                } else {
                    // Not enough jetons — just show result
                    resultItem = CalendarDayItem(date: date)
                }
            } else {
                resultItem = CalendarDayItem(date: date)
            }
            return
        }

        if daily.isToday(date) {
            withAnimation(.easeInOut) { showGameForDate = date }
            return
        }

        // Past unplayed: costs jetons
        if jetons.canAfford(DailyWordManager.costPastDay) {
            pendingDate    = date
            showJetonAlert = true
        } else {
            notEnoughJetons = true
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: displayMonth).capitalized
    }

    private var canGoBack: Bool {
        guard let twoMonthsAgo = daily.cal.date(byAdding: .month, value: -2, to: Date()) else { return false }
        let shownStart = daily.cal.date(from: daily.cal.dateComponents([.year, .month], from: displayMonth))!
        let limitStart = daily.cal.date(from: daily.cal.dateComponents([.year, .month], from: twoMonthsAgo))!
        return shownStart > limitStart
    }

    private var canGoForward: Bool {
        let thisStart  = daily.cal.date(from: daily.cal.dateComponents([.year, .month], from: Date()))!
        let shownStart = daily.cal.date(from: daily.cal.dateComponents([.year, .month], from: displayMonth))!
        return shownStart < thisStart
    }

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }
}

// MARK: - Single day cell

private struct DayCell: View {
    let date: Date
    let theme: AppTheme
    let onTap: () -> Void

    private let daily = DailyWordManager.shared

    var body: some View {
        let isToday  = daily.isToday(date)
        let isFuture = daily.isFuture(date)
        let result   = daily.result(for: date)
        let day      = Calendar.current.component(.day, from: date)

        Button(action: { if !isFuture { onTap() } }) {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.system(size: 15, weight: isToday ? .black : .medium))
                    .foregroundColor(
                        isFuture ? theme.secondaryText.opacity(0.3) :
                        isToday  ? theme.accent :
                        theme.primaryText
                    )

                if isFuture {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(theme.secondaryText.opacity(0.3))
                } else if let r = result {
                    Text(r.won ? "✅" : "❌")
                        .font(.system(size: 12))
                } else if daily.isPast(date) {
                    Text("\(DailyWordManager.costPastDay)🪙")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                } else {
                    // Today, unplayed
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(
                isToday
                    ? AnyShapeStyle(theme.accent.opacity(0.15))
                    : AnyShapeStyle(theme.surface.opacity(isFuture ? 0.4 : 1.0)),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday ? theme.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .disabled(isFuture)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Day result sheet (shown when tapping a played day)

struct DayResultSheet: View {
    let date: Date
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    private let daily = DailyWordManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    if let result = daily.result(for: date) {
                        Text(result.won ? "🎉" : "💀")
                            .font(.system(size: 72))

                        Text(result.won ? "Kazandın!" : "Kaybettin")
                            .font(.title2.bold())
                            .foregroundColor(theme.primaryText)

                        let entry = daily.word(for: date)

                        if !result.won {
                            VStack(spacing: 4) {
                                Text("Doğru kelime:")
                                    .font(.subheadline).foregroundColor(theme.secondaryText)
                                Text(entry.word)
                                    .font(.title2.bold()).foregroundColor(.yellow)
                            }
                        }

                        VStack(spacing: 6) {
                            Text(fullDateLabel)
                                .font(.headline).foregroundColor(theme.primaryText)
                            Text(entry.category)
                                .font(.subheadline).foregroundColor(theme.secondaryText)
                        }
                        .padding(16)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))

                        let boxes = (0..<6).map { i in i < result.wrongCount ? "🟥" : "⬜️" }.joined()
                        Text(boxes).font(.title2)

                        // Share
                        Button {
                            let text = daily.shareText(
                                word: entry.word,
                                wrongCount: result.wrongCount,
                                won: result.won
                            )
                            presentShareSheet([text])
                        } label: {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .padding(.horizontal, 28).padding(.vertical, 14)
                                .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(theme.accent)
                }
            }
        }
    }

    private var fullDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy, EEEE"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date).capitalized
    }
}
