import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Wordle-style emoji grid generator

func buildEmojiGrid(
    history: [(letter: Character, wasCorrect: Bool)],
    won: Bool,
    wrongCount: Int,
    maxWrong: Int,
    modeLabel: String,
    streak: Int = 0
) -> String {
    // Convert each guess to emoji
    let emojis = history.map { $0.wasCorrect ? "🟩" : "⬛" }
    // Group into rows of 7
    let rowSize = 7
    var rows: [String] = []
    var i = 0
    while i < emojis.count {
        let end = min(i + rowSize, emojis.count)
        rows.append(emojis[i..<end].joined())
        i += rowSize
    }
    if rows.isEmpty { rows.append("⬛".repeating(wrongCount)) }

    let resultEmoji = won ? "✅" : "💀"
    let resultText  = won
        ? "\(resultEmoji) \(wrongCount) yanlış tahminle kazandım!"
        : "\(resultEmoji) \(maxWrong) yanlışta kaybettim"
    let streakLine  = won && streak > 1 ? "\n🔥 \(streak) günlük seri!" : ""
    let grid        = rows.joined(separator: "\n")

    return """
Keligo • \(modeLabel)
\(grid)
\(resultText)\(streakLine)
#Keligo
"""
}

private extension String {
    func repeating(_ count: Int) -> String { String(repeating: self, count: max(0, count)) }
}

// MARK: - Global share helper (bypasses nested-sheet white-screen bug)

func presentShareSheet(_ items: [Any]) {
    guard
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
        let window = windowScene.windows.first(where: { $0.isKeyWindow }),
        let rootVC = window.rootViewController
    else { return }

    var top = rootVC
    while let presented = top.presentedViewController { top = presented }

    let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
    avc.popoverPresentationController?.sourceView = top.view
    avc.popoverPresentationController?.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0
    )
    top.present(avc, animated: true)
}

// MARK: - Daily game view

struct DailyGameView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var vm: GameViewModel

    let date: Date
    let onBack: () -> Void

    private let daily = DailyWordManager.shared

    /// True when the view is first created and the date is already played.
    @State private var initiallyPlayed: Bool

    init(settings: SettingsViewModel,
         stats: StatsManager,
         date: Date = Date(),
         onBack: @escaping () -> Void) {
        self.date   = date
        self.onBack = onBack

        let entry = DailyWordManager.shared.word(for: date)
        _vm = StateObject(wrappedValue: GameViewModel(
            settings: settings,
            stats: stats,
            fixedEntry: entry
        ))
        _initiallyPlayed = State(initialValue: DailyWordManager.shared.hasPlayed(date))

        if Calendar.current.isDateInToday(date) {
            DailyWordManager.shared.syncWidget(entry: entry, streak: stats.currentStreak)
        }
    }

    var t: AppTheme { settings.theme }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            if initiallyPlayed {
                // ── Already played: show result without allowing replay ──
                AlreadyPlayedView(date: date, theme: t, onBack: onBack)
                    .environmentObject(stats)
            } else {
                GameBoardView(vm: vm, theme: t, modeLabel: modeLabel, onBack: onBack) {
                    DailyGameOverView(vm: vm, theme: t, onShare: {
                        buildShareAndPresent()
                    }, onBack: onBack)
                }
                .onAppear {
                    // Live Activity: sadece bugün için başlat
                    if #available(iOS 16.1, *), daily.isToday(date) {
                        let masked = vm.displayWord.map { String($0) }.joined()
                        let total  = vm.currentWord.filter { $0 != " " }.count
                        KeligoLiveActivityManager.shared.start(
                            maskedWord: masked,
                            category: vm.category,
                            totalLetters: total,
                            maxWrong: vm.maxWrongGuesses
                        )
                    }
                }
                .onChange(of: vm.gameState) { _, state in
                    if state != .playing {
                        daily.markPlayed(date: date, won: state == .won, wrongCount: vm.wrongGuesses)
                        // Widget'ı kazanma durumu ve güncel streak ile güncelle
                        if daily.isToday(date) {
                            daily.syncWidget(entry: daily.word(for: date), streak: stats.currentStreak)
                        }
                        if #available(iOS 16.1, *), daily.isToday(date) {
                            KeligoLiveActivityManager.shared.end(won: state == .won)
                        }
                    }
                }
                .onChange(of: vm.displayWord) { _, _ in
                    if #available(iOS 16.1, *), daily.isToday(date), vm.gameState == .playing {
                        let masked = vm.displayWord.map { String($0) }.joined()
                        let total = vm.currentWord.filter { $0 != " " }.count
                        let revealed = vm.displayWord.filter { $0 != "_" && $0 != " " }.count
                        let remaining = vm.maxWrongGuesses - vm.wrongGuesses
                        KeligoLiveActivityManager.shared.update(
                            maskedWord: masked, revealed: revealed,
                            total: total, wrongRemaining: remaining
                        )
                    }
                }
            }
        }
    }

    private var modeLabel: String {
        if daily.isToday(date) { return "📅 Günlük Kelime" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "tr_TR")
        return "📅 \(f.string(from: date))"
    }

    private func buildShareAndPresent() {
        Task { @MainActor in
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            f.locale = Locale(identifier: "tr_TR")
            let data = GameShareData(
                modeName: "Günlük Kelime",
                word: vm.currentWord,
                category: vm.category,
                wrongGuesses: vm.wrongGuesses,
                maxWrong: vm.maxWrongGuesses,
                won: vm.gameState == .won,
                streak: stats.currentStreak,
                dateString: f.string(from: date)
            )

            // Emoji grid (Wordle-style) + optional rendered card image
            let emojiGrid = buildEmojiGrid(
                history: vm.guessHistory,
                won: vm.gameState == .won,
                wrongCount: vm.wrongGuesses,
                maxWrong: vm.maxWrongGuesses,
                modeLabel: "Günlük Kelime",
                streak: stats.currentStreak
            )

            var items: [Any] = [emojiGrid]
            if let img = renderShareImage(GameShareCard(data: data)) {
                items.insert(img, at: 0)
            }
            presentShareSheet(items)
        }
    }
}

// MARK: - Already-played banner (no replay allowed)

private struct AlreadyPlayedView: View {
    let date: Date
    let theme: AppTheme
    let onBack: () -> Void

    @EnvironmentObject var stats: StatsManager

    private let daily = DailyWordManager.shared

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            if let result = daily.result(for: date) {
                Text(result.won ? "🎉" : "💀")
                    .font(.system(size: 80))

                VStack(spacing: 6) {
                    Text(result.won ? "Bugün kazandın!" : "Bugün kaybettin")
                        .font(.title2.bold())
                        .foregroundColor(theme.primaryText)

                    if !result.won {
                        let w = daily.word(for: date)
                        Text("Doğru kelime: \(w.word)")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }

                let boxes = (0..<6).map { i in i < result.wrongCount ? "🟥" : "⬜️" }.joined()
                Text(boxes)
                    .font(.title2)
                    .padding(.vertical, 4)

                if stats.currentStreak > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(stats.currentStreak) gün serisi")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.primaryText)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.orange.opacity(0.18), in: Capsule())
                }

                Text("Yarın yeni kelime!")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)

                // Share result
                Button {
                    let text = daily.shareText(
                        word: daily.word(for: date).word,
                        wrongCount: result.wrongCount,
                        won: result.won
                    )
                    presentShareSheet([text])
                } label: {
                    Label("Sonucu Paylaş", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()

            Button(action: onBack) {
                Label("Ana Menü", systemImage: "house.fill")
                    .font(.headline)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(theme.primaryText)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Daily game-over overlay

struct DailyGameOverView: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let onShare: () -> Void
    let onBack: () -> Void

    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var jetons: JetonManager
    @State private var streakProtected = false
    @State private var showAdStreakConfirm = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.70).ignoresSafeArea()
            VStack(spacing: 20) {
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

                Text("Yarın yeni kelime!")
                    .font(.subheadline).foregroundColor(.white.opacity(0.75))

                // Streak protection offer
                if vm.gameState == .lost && stats.canUseStreakProtection && !streakProtected {
                    Button {
                        if stats.useStreakProtection() {
                            withAnimation { streakProtected = true }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.fill").foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Seriyi Koru! (\(stats.streakBeforeLoss) gün)")
                                    .font(.subheadline.weight(.bold)).foregroundColor(.white)
                                HStack(spacing: 3) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8)).foregroundColor(.yellow)
                                    Text("\(JetonManager.costStreakProtection) jeton")
                                        .font(.caption).foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(Color.orange.opacity(0.25))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.55), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!jetons.canAfford(JetonManager.costStreakProtection))
                    .opacity(jetons.canAfford(JetonManager.costStreakProtection) ? 1 : 0.45)
                }

                // Reklam ile seri kurtarma (jeton yetmiyorsa veya alternatif)
                if vm.gameState == .lost && stats.canUseStreakProtection && !streakProtected
                    && AdManager.shared.canShowRewarded(.streakSave) {
                    Button {
                        showAdStreakConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.rectangle.fill").foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reklamla Seriyi Koru")
                                    .font(.subheadline.weight(.bold)).foregroundColor(.white)
                                Text("Bugünlük 1 hak — ücretsiz")
                                    .font(.caption).foregroundColor(.white.opacity(0.75))
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(Color.purple.opacity(0.25))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.55), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                if streakProtected {
                    Label("Seri korundu! 🛡️", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold)).foregroundColor(.green)
                }

                HStack(spacing: 12) {
                    Button(action: onShare) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .padding(.horizontal, 22).padding(.vertical, 13)
                            .background(.white)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: onBack) {
                        Label("Ana Menü", systemImage: "house.fill")
                            .font(.headline)
                            .padding(.horizontal, 22).padding(.vertical, 13)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(32)
        }
        .alert("Reklam izle, seriyi koru", isPresented: $showAdStreakConfirm) {
            Button("İzle") {
                Task {
                    let ok = await AdManager.shared.presentRewarded(.streakSave)
                    if ok && stats.restoreStreakFromAd() {
                        withAnimation { streakProtected = true }
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("📺 Kısa bir reklam sonrası \(stats.streakBeforeLoss) günlük serin geri gelir. Günde 1 kez kullanılabilir.")
        }
    }
}

// MARK: - Rich share item: app icon + title in share sheet preview

final class KeligoShareItem: NSObject, UIActivityItemSource {
    let text: String
    let title: String

    init(_ text: String, title: String = "Keligo") {
        self.text  = text
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ vc: UIActivityViewController) -> Any { text }

    func activityViewController(_ vc: UIActivityViewController,
                                itemForActivityType type: UIActivity.ActivityType?) -> Any? { text }

    func activityViewControllerLinkMetadata(_ vc: UIActivityViewController) -> LPLinkMetadata? {
        let meta = LPLinkMetadata()
        meta.title = title
        if let icon = appIcon() {
            meta.iconProvider = NSItemProvider(object: icon)
        }
        return meta
    }

    private func appIcon() -> UIImage? {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files   = primary["CFBundleIconFiles"] as? [String],
            let name    = files.last
        else { return nil }
        return UIImage(named: name)
    }
}

// MARK: - Share sheet (kept for legacy use in InfiniteGameOverView etc.)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    DailyGameView(settings: SettingsViewModel(), stats: StatsManager(), onBack: {})
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(AchievementManager.shared)
        .environmentObject(JetonManager.shared)
}
