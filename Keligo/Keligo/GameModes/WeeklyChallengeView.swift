import SwiftUI

// MARK: - Weekly Challenge View (sheet)

struct WeeklyChallengeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var weekly = WeeklyChallengeManager.shared

    /// When set, opens the full-screen game overlay for today.
    @State private var showGameForToday = false
    @State private var refreshToken     = UUID()

    var t: AppTheme { settings.theme }

    private let turkishDayNames = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    // MARK: - Body

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    t.background.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            dateRangeHeader
                            progressSection
                            dayList
                                .id(refreshToken)
                            bonusSection
                            Spacer(minLength: 32)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                .navigationTitle("⚡️ Haftalık Meydan Okuma")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Kapat") { dismiss() }
                            .foregroundColor(t.accent)
                    }
                }
            }

            // Full-screen game overlay for today
            if showGameForToday {
                WeeklyGameWrapper(
                    settings: settings,
                    stats: stats,
                    onBack: {
                        withAnimation(.easeInOut) { showGameForToday = false }
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
        .animation(.easeInOut(duration: 0.3), value: showGameForToday)
    }

    // MARK: - Date range header

    private var dateRangeHeader: some View {
        let dates = weekly.weekDates()
        let label = weekRangeLabel(dates: dates)
        return Text(label)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(t.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func weekRangeLabel(dates: [Date]) -> String {
        guard let first = dates.first, let last = dates.last else { return "" }
        let f1 = DateFormatter()
        f1.dateFormat = "d"
        f1.locale = Locale(identifier: "tr_TR")
        let f2 = DateFormatter()
        f2.dateFormat = "d MMMM yyyy"
        f2.locale = Locale(identifier: "tr_TR")
        return "\(f1.string(from: first))-\(f2.string(from: last))"
    }

    // MARK: - Progress bar

    private var progressSection: some View {
        let progress = weekly.weekProgress()
        return VStack(spacing: 10) {
            HStack {
                Text("İlerleme")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(t.primaryText)
                Spacer()
                Text("\(progress)/7 tamamlandı")
                    .font(.caption.weight(.bold))
                    .foregroundColor(t.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(t.surface)
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.10, green: 0.75, blue: 0.55),
                                         Color(red: 0.20, green: 0.95, blue: 0.70)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progress > 0
                                ? geo.size.width * CGFloat(progress) / 7.0
                                : 0,
                            height: 12
                        )
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Day list

    private var dayList: some View {
        VStack(spacing: 10) {
            ForEach(Array(weekly.weekDates().enumerated()), id: \.offset) { idx, date in
                WeeklyDayRow(
                    date: date,
                    dayName: turkishDayNames[idx],
                    weekly: weekly,
                    theme: t,
                    onPlay: {
                        withAnimation(.easeInOut) { showGameForToday = true }
                    }
                )
            }
        }
    }

    // MARK: - Bonus section

    private var bonusSection: some View {
        let complete  = weekly.isWeekComplete()
        let claimed   = weekly.weekBonusClaimed()

        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(complete ? .white : t.secondaryText)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Haftalık Ödül")
                        .font(.headline.weight(.bold))
                        .foregroundColor(complete ? .white : t.primaryText)
                    Text("Tüm 7 günü tamamla, \(WeeklyChallengeManager.bonusJetons) 🟡 kazan!")
                        .font(.caption)
                        .foregroundColor(complete ? .white.opacity(0.82) : t.secondaryText)
                }

                Spacer()

                Text("\(WeeklyChallengeManager.bonusJetons) 🟡")
                    .font(.subheadline.weight(.black))
                    .foregroundColor(complete ? .white : t.secondaryText)
            }

            if complete && !claimed {
                Button {
                    weekly.claimBonus()
                    refreshToken = UUID()
                } label: {
                    Text("🎉 Ödülünü Al!")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
            } else if claimed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Bu hafta ödülün alındı ✓")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            complete
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.75, blue: 0.55),
                                 Color(red: 0.20, green: 0.95, blue: 0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                  )
                : AnyShapeStyle(t.cardMaterial),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    complete
                        ? Color.white.opacity(0.20)
                        : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Weekly Day Row

private struct WeeklyDayRow: View {
    let date: Date
    let dayName: String
    @ObservedObject var weekly: WeeklyChallengeManager
    let theme: AppTheme
    let onPlay: () -> Void

    private var isToday:  Bool { weekly.isToday(date) }
    private var isFuture: Bool { weekly.isFuture(date) }
    private var isPast:   Bool { weekly.isPast(date) }
    private var played:   Bool { weekly.hasPlayed(date) }
    private var result:   Bool? { weekly.result(for: date) }

    var body: some View {
        HStack(spacing: 14) {
            // Day label
            Text(dayName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(
                    isFuture ? theme.secondaryText.opacity(0.45) :
                    isToday  ? theme.accent :
                    theme.primaryText
                )
                .frame(width: 90, alignment: .leading)

            Spacer()

            // Right side
            if isFuture {
                // Locked future day
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText.opacity(0.45))
                    Text(dayName)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText.opacity(0.35))
                }
            } else if played, let r = result {
                // Played — show win/loss + word if lost
                HStack(spacing: 8) {
                    if !r {
                        Text(weekly.weekWord(for: date).word)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                    }
                    Text(r ? "✅" : "❌")
                        .font(.body)
                }
            } else if isToday {
                // Today, unplayed — play button
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Text("Bugün Oyna")
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.10, green: 0.75, blue: 0.55),
                                     Color(red: 0.20, green: 0.95, blue: 0.70)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                // Past, unplayed (missed)
                Text("Oynanmadı")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText.opacity(0.55))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            isToday
                ? AnyShapeStyle(theme.accent.opacity(0.10))
                : AnyShapeStyle(theme.cardMaterial),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isToday ? theme.accent.opacity(0.40) : Color.white.opacity(0.06),
                    lineWidth: isToday ? 1.5 : 1
                )
        )
    }
}

// MARK: - Weekly Game Wrapper

/// Wraps GameBoardView for the weekly challenge, using today's weekly word as fixedEntry.
struct WeeklyGameWrapper: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var jetons: JetonManager

    @StateObject private var vm: GameViewModel
    private let weekly = WeeklyChallengeManager.shared

    let onBack: () -> Void

    init(settings: SettingsViewModel, stats: StatsManager, onBack: @escaping () -> Void) {
        self.onBack = onBack
        let entry = WeeklyChallengeManager.shared.weekWord(for: Date())
        let fixedEntry = WordEntry(word: entry.word, category: "Haftalık Meydan Okuma")
        _vm = StateObject(wrappedValue: GameViewModel(
            settings: settings,
            stats: stats,
            fixedEntry: fixedEntry
        ))
    }

    var body: some View {
        GameBoardView(
            vm: vm,
            theme: settings.theme,
            modeLabel: "⚡️ Haftalık Meydan Okuma",
            onBack: onBack
        ) {
            WeeklyGameOverView(vm: vm, theme: settings.theme, onBack: onBack)
        }
        .onChange(of: vm.gameState) { _, state in
            guard state != .playing else { return }
            weekly.markPlayed(date: Date(), won: state == .won)
        }
    }
}

// MARK: - Weekly Game Over Overlay

private struct WeeklyGameOverView: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 22) {
                Text(vm.gameState == .won ? "🎉 Kazandın!" : "💀 Kaybettin!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                if vm.gameState == .lost {
                    VStack(spacing: 4) {
                        Text("Doğru kelime:")
                            .font(.subheadline).foregroundColor(.white.opacity(0.7))
                        Text(vm.currentWord)
                            .font(.title2.bold()).foregroundColor(.yellow)
                    }
                }

                Text("Yarın yeni haftalık kelime!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))

                Button(action: onBack) {
                    Label("Geri Dön", systemImage: "chevron.left")
                        .font(.headline)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(32)
        }
    }
}

#Preview {
    WeeklyChallengeView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(JetonManager.shared)
}
