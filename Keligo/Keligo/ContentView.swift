import SwiftUI
import Combine

// MARK: - Root

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager

    // Splash phases: fozzy → keligo → nil (main app)
    private enum SplashPhase { case fozzy, keligo, none }
    @State private var splashPhase: SplashPhase = .fozzy
    @StateObject private var dailyReward = DailyRewardManager.shared

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                MainMenuView()
            } else {
                OnboardingView { hasSeenOnboarding = true }
            }

            // Kalıcı karartma — her iki splash boyunca ana menüyü gizler
            if splashPhase != .none {
                Color(red: 0.04, green: 0.06, blue: 0.10)
                    .ignoresSafeArea()
                    .zIndex(997)
            }

            // Phase 1 — FozzyLabs publisher intro (~1.2s)
            if splashPhase == .fozzy {
                FozzyLabsIntroView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        splashPhase = .keligo
                    }
                }
                .zIndex(1000)
                .transition(.opacity)
            }

            // Phase 2 — Keligo game splash (~2.1s)
            if splashPhase == .keligo {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        splashPhase = .none
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dailyReward.checkAndClaim()
                    }
                }
                .zIndex(999)
                .transition(.opacity)
            }

            // Daily login reward toast — sadece her iki splash bittikten sonra göster
            if splashPhase == .none, let reward = dailyReward.pendingReward {
                DailyRewardToast(streak: reward.streak, jetons: reward.jetons) {
                    withAnimation(.spring()) { dailyReward.dismissReward() }
                }
                .zIndex(998)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: dailyReward.pendingReward != nil)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: splashPhase == .none)
    }
}

// MARK: - Daily Reward Toast

private struct DailyRewardToast: View {
    let streak: Int
    let jetons: Int
    let onDismiss: () -> Void

    private let dayRewards = [10, 20, 30, 50, 75, 100, 150]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 10) {
                    Text("🎁").font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Günlük Giriş Ödülü")
                            .font(.headline.weight(.black))
                            .foregroundColor(.white)
                        Text("\(streak). gün • Seri devam ediyor 🔥")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // 7-day strip
                HStack(spacing: 4) {
                    ForEach(0..<7) { day in
                        let dayNum   = day + 1
                        let claimed  = dayNum <= streak
                        let isToday  = dayNum == ((streak - 1) % 7 + 1)
                        VStack(spacing: 4) {
                            Text(claimed ? "✓" : "\(dayRewards[day])J")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(claimed ? .white : .white.opacity(0.6))
                            Text("G\(dayNum)")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            claimed
                                ? (isToday ? Color.yellow.opacity(0.35) : Color.white.opacity(0.18))
                                : Color.white.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isToday ? Color.yellow.opacity(0.8) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }

                // Reward amount
                HStack(spacing: 6) {
                    Text("+\(jetons) 🪙")
                        .font(.title2.weight(.black))
                        .foregroundColor(.yellow)
                    Text("jeton kazandın!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }

                Button(action: onDismiss) {
                    Text("Harika! 🎉")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.65, green: 0.15, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.15, blue: 0.95), Color(red: 0.35, green: 0.10, blue: 0.75)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { onDismiss() }
        }
    }
}

// MARK: - Shake modifier

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let shake = sin(animatableData * .pi * 6) * amount * max(0, 1 - animatableData)
        return ProjectionTransform(CGAffineTransform(translationX: shake, y: 0))
    }
}

// MARK: - Scale button style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Shared keyboard rows

private let turkishRows: [[Character]] = [
    ["A","B","C","Ç","D","E","F","G","Ğ"],
    ["H","I","İ","J","K","L","M","N","O"],
    ["Ö","P","R","S","Ş","T","U","Ü","V"],
    ["Y","Z"]
]

// MARK: - GameBoardView (shared by all modes)

struct GameBoardView<Overlay: View>: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let modeLabel: String
    let onBack: () -> Void
    @ViewBuilder var gameOverOverlay: () -> Overlay

    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var jetons: JetonManager
    @StateObject private var lives = LivesManager.shared
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var shakeCount: CGFloat = 0
    @State private var bouncingIndices: Set<Int> = []
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showRewardedAdSimulation = false
    @State private var nearMissPulse = false   // red glow on last life
    @State private var showNearSolvedBanner = false  // "Neredeyse!" banner
    @State private var showWordReport = false  // word error report sheet
    @State private var showRewardedCapAlert = false  // günlük cap dolduğunda
    @State private var rewardToastText: String? = nil  // "+1 harf" gibi geri bildirim
    @State private var showInsufficientJetonAlert = false  // jeton yetersiz uyarısı
    @State private var now = Date()  // lives countdown timer tick
    private let regenTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 2026: Continue after loss
    @State private var showContinueAfterLoss = false
    @State private var hasUsedContinue = false
    
    // 2026: Word Lore sheet
    @State private var showWordLore = false

    var isIPad: Bool { sizeClass == .regular }

    // True when 1 wrong guess remaining
    private var isLastChance: Bool {
        vm.gameState == .playing && vm.wrongGuesses == vm.maxWrongGuesses - 1
    }
    // True when exactly 1 letter left unrevealed
    private var isAlmostSolved: Bool {
        guard vm.gameState == .playing else { return false }
        return vm.displayWord.filter({ $0 == "_" }).count == 1
    }

    @StateObject private var ai = AIPersonalizationEngine.shared
    
    var body: some View {
        ZStack {
            // Opaque base — prevents main menu from bleeding through the game view
            settings.theme.background
                .ignoresSafeArea()

            // 2026: Reactive generative ambient background (overlay on opaque base)
            ReactiveGameBackground(vm: vm)
                .animation(.easeInOut(duration: 1.2), value: vm.gameState)

            // Near-miss glow overlay (last life) — lightweight pulse only
            if isLastChance && nearMissPulse {
                Color.red.opacity(0.10)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if isIPad {
                iPadLayout
            } else {
                iPhoneLayout
            }

            // 2026: Continue after loss overlay (shown before game over)
            if vm.gameState == .lost && showContinueAfterLoss && !hasUsedContinue {
                ContinueAfterLossView(
                    theme: theme,
                    canAffordJetons: jetons.canAfford(JetonManager.costContinueAfterLoss)
                ) {
                    // Watch ad
                    if AdManager.shared.canShowRewarded(.letter) {
                        Task {
                            let ok = await AdManager.shared.presentRewarded(.letter)
                            if ok {
                                vm.continueAfterLoss()
                                hasUsedContinue = true
                                showContinueAfterLoss = false
                            }
                        }
                    } else {
                        showRewardedCapAlert = true
                    }
                } onSpendJetons: {
                    if jetons.spend(JetonManager.costContinueAfterLoss) {
                        vm.continueAfterLoss()
                        hasUsedContinue = true
                        showContinueAfterLoss = false
                        withAnimation(.spring()) {
                            rewardToastText = "❤️ Oyun kurtarıldı!"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation { rewardToastText = nil }
                        }
                    } else {
                        showInsufficientJetonAlert = true
                    }
                } onDecline: {
                    showContinueAfterLoss = false
                }
            }

            if vm.gameState != .playing && !(vm.gameState == .lost && showContinueAfterLoss && !hasUsedContinue) {
                gameOverOverlay()
                if vm.gameState == .won { ConfettiView() }
            }

            // Reward toast (rewarded ad sonrası)
            if let text = rewardToastText {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Text(text)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.purple, .indigo],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 14, y: 4)
                    .padding(.bottom, 220)
                }
                .zIndex(50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: rewardToastText)
            }
        }
        .onReceive(regenTimer) { now = $0 }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showHistory) {
            GuessHistoryView(history: vm.guessHistory, theme: theme)
                .presentationDetents([.fraction(0.4)])
        }
        .sheet(isPresented: $showWordReport) {
            WordReportSheet(word: vm.currentWord, category: vm.category)
                .environmentObject(settings)
        }
        .sheet(isPresented: $showWordLore) {
            WordLoreSheet(word: vm.currentWord, category: vm.category, theme: theme)
        }
        .alert("Reklam izlendi!", isPresented: $showRewardedAdSimulation) {
            Button("Tamam") {
                Task {
                    let ok = await AdManager.shared.presentRewarded(.letter)
                    if ok {
                        vm.watchRewardedAdReward()
                        withAnimation(.spring()) { rewardToastText = "🎯 +1 doğru harf açıldı!" }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation { rewardToastText = nil }
                        }
                    }
                }
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("📺 Reklamı izle, kelimeden 1 doğru harf açılsın.\nBugünkü hak: \(AdManager.shared.remaining(.letter))/\(AdManager.RewardKind.letter.dailyCap)")
        }
        .alert("Bugünkü hak doldu", isPresented: $showRewardedCapAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Reklamla harf açma hakkın bugün için doldu. Yarın tekrar gel.")
        }
        .alert("Yeterli jeton yok", isPresented: $showInsufficientJetonAlert) {
            Button("Mağazaya Git") { showSettings = true }
            Button("Reklam İzle") {
                if AdManager.shared.canShowRewarded(.letter) {
                    showRewardedAdSimulation = true
                } else {
                    showRewardedCapAlert = true
                }
            }
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bu aksiyon için yeterli jetonun yok. Jeton kazanmak için reklam izleyebilir veya mağazadan satın alabilirsin.")
        }
        .onChange(of: vm.wrongGuesses) {
            withAnimation(.linear(duration: 0.5)) { shakeCount += 1 }
            // 2026: Rich cinematic haptics
            if settings.hapticEnabled {
                CinematicHaptics.shared.play(isLastChance ? .lastChance : .wrong)
            }
            // Last-chance pulse
            if isLastChance {
                withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                    nearMissPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    nearMissPulse = false
                }
            }
        }
        .onChange(of: vm.guessedLetters) { old, new in
            // 2026: AI gesture heatmap tracking
            let diff = new.subtracting(old)
            if let letter = diff.first {
                ai.recordLetterTap(letter)
            }
        }
        .onChange(of: vm.displayWord) {
            // Show "Neredeyse!" when 1 letter left, hide when solved
            withAnimation(.spring(response: 0.3)) {
                showNearSolvedBanner = isAlmostSolved
            }
        }
        .onChange(of: vm.lastCorrectLetter) { _, letter in
            guard let letter else { return }
            let indices = Set(vm.displayWord.enumerated().compactMap { $0.element == letter ? $0.offset : nil })
            bouncingIndices.formUnion(indices)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { bouncingIndices.subtract(indices) }
            // Doğru harf haptic'i
            if settings.hapticEnabled {
                CinematicHaptics.shared.play(.correct)
            }
        }
        .onChange(of: vm.gameState) { _, state in
            // Reset continue flag on new game
            if state == .playing {
                showContinueAfterLoss = false
                hasUsedContinue = false
                return
            }
            
            // Show continue prompt on loss (before game over)
            if state == .lost && !hasUsedContinue {
                showContinueAfterLoss = true
                return
            }
            
            guard state != .playing else { return }
            
            // 2026: AI session recording
            ai.recordGame(
                word: vm.currentWord,
                won: state == .won,
                wrongGuesses: vm.wrongGuesses,
                duration: 0, // Could be tracked with a timer
                category: vm.category
            )
            
            achievements.check(
                stats: vm.stats,
                chapters: ChapterManager.shared,
                wrongCount: vm.wrongGuesses,
                hintUsed: vm.hintUsed,
                won: state == .won
            )
            // Ad cadence — interstitial Sonsuz/Çocuk için tetikle (Daily/Chapter/Speed dışı)
            if !modeLabel.contains("Günlük") && !modeLabel.contains("Bölüm") && !modeLabel.contains("Hız") {
                AdManager.shared.notifyGameEnded()
                if AdManager.shared.shouldShowInterstitial() {
                    Task { await AdManager.shared.presentInterstitial() }
                }
            }
            // Prompt manager — ardışık kayıp tetiği
            AppPromptManager.shared.notifyGameEnded(won: state == .won)
            
            // 2026: Cinematic haptics on game end
            if settings.hapticEnabled {
                CinematicHaptics.shared.play(state == .won ? .win : .loss)
            }
            
            // 2026: Show Word Lore on win
            if state == .won {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showWordLore = true
                }
            }
        }
    }

    // MARK: - iPad layout

    private var iPadLayout: some View {
        VStack(spacing: 0) {
            topBar
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    categoryBadge
                    SpectralHangmanView(wrongGuesses: vm.wrongGuesses, maxWrong: vm.maxWrongGuesses, theme: theme, isLastChance: isLastChance)
                    wrongDots
                    wordDisplay
                    wordHintCard
                    wrongLettersRow
                    jetonActionsRow
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(theme.secondaryText.opacity(0.2))
                    .padding(.vertical, 16)

                VStack(spacing: 0) {
                    Spacer()
                    keyboard
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - iPhone layout

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            topBar
            categoryBadge
            KeligoDrawing(wrongGuesses: vm.wrongGuesses, maxWrong: vm.maxWrongGuesses, theme: theme)
            wrongDots
            wordDisplay
            wordHintCard

            // "Neredeyse!" — inline, just below word, above wrong letters
            if showNearSolvedBanner {
                HStack(spacing: 6) {
                    Text("🔥")
                    Text("Neredeyse!")
                        .font(.subheadline.weight(.black))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 18).padding(.vertical, 7)
                .background(Color.orange.opacity(0.88), in: Capsule())
                .shadow(color: .orange.opacity(0.35), radius: 8, y: 3)
                .padding(.top, 6)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            wrongLettersRow
            jetonActionsRow

            // "Son şansın!" — inline, sits above keyboard
            if isLastChance {
                HStack(spacing: 6) {
                    Text("⚠️")
                    Text("Son şansın!")
                        .font(.subheadline.weight(.black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.88))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 0)
            keyboard
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title2)
                    .foregroundStyle(theme.accentGradient)
            }
            Spacer()
            Text(modeLabel)
                .font(.caption.weight(.bold))
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(theme.cardFill, in: Capsule())
            Spacer()
            HStack(spacing: 6) {
                // Lives pill (can sayısı + yenilenme sayacı)
                HStack(spacing: 3) {
                    Image(systemName: lives.hasInfinite ? "infinity" : "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text(lives.hasInfinite ? "∞" : "\(lives.current)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.red)
                    if !lives.hasInfinite, let next = lives.nextRegenAt {
                        let remaining = max(0, next.timeIntervalSince(now))
                        let mins = Int(remaining) / 60
                        let secs = Int(remaining) % 60
                        Text("·\(mins):\(String(format: "%02d", secs))")
                            .font(.system(size: 8, weight: .semibold).monospacedDigit())
                            .foregroundColor(.red.opacity(0.75))
                    }
                }
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(Color.red.opacity(0.14), in: Capsule())

                // Jeton balance pill
                HStack(spacing: 3) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text("\(jetons.balance)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.yellow.opacity(0.14), in: Capsule())

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                        .foregroundStyle(theme.accentGradient)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Category badge + letter count

    private var categoryBadge: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(vm.category)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.accent)
                Circle()
                    .fill(theme.secondaryText.opacity(0.35))
                    .frame(width: 3, height: 3)
                Text("\(vm.currentWord.filter { $0 != " " }.count) harf")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(theme.cardFill, in: Capsule())

            // Flag button — report word error
            Button {
                showWordReport = true
            } label: {
                Image(systemName: "flag.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
                    .padding(6)
                    .background(theme.cardFill, in: Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.bottom, 6)
    }

    // MARK: - Wrong attempt dots

    private var wrongDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<vm.maxWrongGuesses, id: \.self) { i in
                Circle()
                    .fill(i < vm.wrongGuesses ? theme.wrong : theme.surface)
                    .frame(width: 10, height: 10)
                    .scaleEffect(i == vm.wrongGuesses - 1 ? 1.3 : 1.0)
                    .animation(.spring(response: 0.25), value: vm.wrongGuesses)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Word display (centered)

    // MARK: - Word hint card

    /// Kelime ipucu — 50 🪙 ile açılır, açıldıktan sonra gösterilir.
    @ViewBuilder
    private var wordHintCard: some View {
        if vm.wordHintRevealed, let hint = vm.wordHintText {
            // Revealed: show hint text
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                Text(hint)
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.30), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        } else if vm.canBuyHint {
            // Not revealed: show buy button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    _ = vm.buyHint()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.subheadline.weight(.semibold))
                    Text("İpucu Al")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.yellow)
                        Text("\(JetonManager.costHint)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(
                        jetons.canAfford(JetonManager.costHint)
                            ? AnyShapeStyle(Color.yellow.opacity(0.20))
                            : AnyShapeStyle(theme.cardFill),
                        in: Capsule()
                    )
                }
                .foregroundColor(jetons.canAfford(JetonManager.costHint)
                    ? theme.primaryText : theme.secondaryText)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                    Color.yellow.opacity(jetons.canAfford(JetonManager.costHint) ? 0.30 : 0.10),
                    lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!jetons.canAfford(JetonManager.costHint))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    private var wordDisplay: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                wordLetterTiles
                    .frame(minWidth: geo.size.width, alignment: .center)
            }
        }
        .frame(height: isIPad ? 72 : 58)
        .modifier(ShakeEffect(animatableData: shakeCount))
        .padding(.bottom, 10)
    }

    private var wordLetterTiles: some View {
        HStack(spacing: 0) {
            ForEach(Array(vm.displayWord.enumerated()), id: \.offset) { idx, char in
                if char == " " {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 40)
                } else {
                    CrystalLetterTile(
                        letter: char,
                        isRevealed: char != "_",
                        isSpace: false,
                        theme: theme,
                        accent: theme.correct,
                        isBouncing: bouncingIndices.contains(idx),
                        index: idx
                    )
                    .padding(.horizontal, 3)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Wrong letters + hint

    private var wrongLettersRow: some View {
        HStack {
            if settings.showWrongLetters && !vm.wrongLetters.isEmpty {
                HStack(spacing: 4) {
                    Text("Yanlış:")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    Text(vm.wrongLetters.map { String($0) }.joined(separator: " "))
                        .font(.caption.bold())
                        .foregroundColor(theme.wrong)
                }
            }
            Spacer()
            if !vm.guessHistory.isEmpty {
                Button { showHistory.toggle() } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption.weight(.bold))
                        .foregroundColor(theme.secondaryText)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(theme.cardFill, in: Capsule())
                }
            }
            Button { vm.useHint() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill")
                    Text("\(vm.hintsRemaining)")
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    vm.hintsRemaining > 0 && vm.gameState == .playing
                        ? AnyShapeStyle(theme.accent.opacity(0.2))
                        : AnyShapeStyle(theme.cardFill),
                    in: Capsule()
                )
                .foregroundColor(vm.hintsRemaining > 0 && vm.gameState == .playing
                    ? theme.accent : theme.secondaryText)
            }
            .disabled(vm.hintsRemaining == 0 || vm.gameState != .playing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Jeton action buttons

    private var jetonActionsRow: some View {
        HStack(spacing: 7) {
            // ── Sol grup: jeton harcama butonları ──
            JetonActionButton(
                icon: "character.textbox",
                title: "Sesli Harf",
                cost: JetonManager.costVowel,
                canAct: vm.hasUnrevealedVowels && vm.gameState == .playing,
                canAfford: jetons.canAfford(JetonManager.costVowel),
                theme: theme,
                onInsufficientFunds: { showInsufficientJetonAlert = true }
            ) { vm.buyVowel() }

            JetonActionButton(
                icon: "lightbulb",
                title: "Harf Al",
                cost: JetonManager.costLetter,
                canAct: vm.gameState == .playing,
                canAfford: jetons.canAfford(JetonManager.costLetter),
                theme: theme,
                onInsufficientFunds: { showInsufficientJetonAlert = true }
            ) { vm.buyLetter() }

            if vm.canSkip {
                JetonActionButton(
                    icon: "forward.fill",
                    title: "Pas",
                    cost: JetonManager.costSkip,
                    canAct: vm.gameState == .playing,
                    canAfford: jetons.canAfford(JetonManager.costSkip),
                    theme: theme,
                    onInsufficientFunds: { showInsufficientJetonAlert = true }
                ) { vm.skipWord() }
            }

            // Geri Al — always in layout (opacity hides it) so width stays stable
            JetonActionButton(
                icon: "arrow.uturn.backward",
                title: "Geri Al",
                cost: JetonManager.costUndo,
                canAct: vm.canUndo && vm.gameState == .playing,
                canAfford: jetons.canAfford(JetonManager.costUndo),
                theme: theme,
                onInsufficientFunds: { showInsufficientJetonAlert = true }
            ) { vm.undo() }
            .opacity(vm.canUndo ? 1 : 0)
            .allowsHitTesting(vm.canUndo)

            Spacer()

            // ── Sağ: Jeton Kazan (rewarded ad) — her zaman sağda, boşluğa gömülmez ──
            if vm.canWatchRewardedAd {
                JetonActionButton(
                    icon: "play.rectangle.fill",
                    title: "Jeton Kazan",
                    cost: 0,
                    canAct: true,
                    canAfford: true,
                    theme: theme,
                    accentColor: .yellow,
                    onInsufficientFunds: {}
                ) {
                    if AdManager.shared.canShowRewarded(.letter) {
                        showRewardedAdSimulation = true
                    } else {
                        showRewardedCapAlert = true
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Keyboard panel

    private var keyboard: some View {
        keyboardKeys
            .background(keyboardPanel)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 20, y: -4)
            .padding(.horizontal, isIPad ? 12 : -8)
            .ignoresSafeArea(edges: isIPad ? [] : .bottom)
    }

    private var keyboardKeys: some View {
        VStack(spacing: 0) {
            if !isIPad {
                Capsule()
                    .fill(Color.white.opacity(theme.isDark ? 0.20 : 0.50))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }
            VStack(spacing: 7) {
                ForEach(turkishRows, id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach(row, id: \.self) { letter in
                            if settings.spatialUIEnabled {
                                FloatingKeyOrb(letter: letter, vm: vm, theme: theme)
                            } else {
                                KeyButton(letter: letter, vm: vm, theme: theme)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 7)
            .padding(.top, isIPad ? 14 : 4)
            .padding(.bottom, isIPad ? 14 : 22)
        }
        .frame(maxWidth: .infinity)
    }

    private var keyboardPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(settings.keyboardStyle == .minimal
                      ? AnyShapeStyle(Color.clear)
                      : AnyShapeStyle(theme.cardFill))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(panelTopOpacity),
                        Color.white.opacity(panelBottomOpacity)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
            VStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(theme.isDark ? 0.20 : 0.65))
                    .frame(height: 1).padding(.horizontal, 1)
                Spacer()
            }
        }
    }

    private var panelTopOpacity: Double {
        switch settings.keyboardStyle {
        case .glass:    return theme.isDark ? 0.07 : 0.55
        case .flat:     return 0
        case .minimal:  return 0
        case .colorful: return theme.isDark ? 0.12 : 0.30
        }
    }

    private var panelBottomOpacity: Double {
        switch settings.keyboardStyle {
        case .glass:    return theme.isDark ? 0.02 : 0.18
        default:        return 0
        }
    }
}

// MARK: - Infinite mode container

struct GameContainerView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var vm: GameViewModel
    let kidsMode: Bool
    let onBack: () -> Void

    init(settings: SettingsViewModel, stats: StatsManager,
         categoryFilter: String? = nil, kidsMode: Bool = false, onBack: @escaping () -> Void) {
        self.kidsMode = kidsMode
        self.onBack = onBack
        _vm = StateObject(wrappedValue: GameViewModel(
            settings: settings, stats: stats, categoryFilter: categoryFilter,
            kidsMode: kidsMode, countsAgainstLives: true))
    }

    var body: some View {
        GameBoardView(vm: vm, theme: settings.theme,
                      modeLabel: kidsMode ? "🧒 Çocuk Modu" : "∞ Sonsuz Mod",
                      onBack: onBack) {
            InfiniteGameOverView(vm: vm, theme: settings.theme, onBack: onBack)
        }
    }
}

// MARK: - Infinite game-over overlay

struct InfiniteGameOverView: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let onBack: () -> Void
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager
    @StateObject private var lives = LivesManager.shared

    @State private var showShare     = false
    @State private var shareItems: [Any] = []
    @State private var showOutOfLives  = false
    @State private var showWordReport  = false

    private var isWon: Bool { vm.gameState == .won }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 20) {
                // Sonuç başlığı
                Text(isWon ? "🎉 Kazandın!" : "💀 Kaybettin!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                // Kaybedince doğru kelimeyi göster
                if !isWon {
                    VStack(spacing: 4) {
                        Text("Doğru kelime:")
                            .font(.subheadline).foregroundColor(.white.opacity(0.7))
                        Text(vm.currentWord)
                            .font(.title2.bold()).foregroundColor(.yellow)
                            .tracking(2)
                    }
                }

                // Ana buton: Kazanınca "Devam Et", kaybedince "Yeni Oyun"
                Button {
                    lives.recomputeRegen()
                    if lives.current > 0 || lives.hasInfinite {
                        vm.startNewGame()
                    } else {
                        showOutOfLives = true
                    }
                } label: {
                    Label(
                        isWon ? "Devam Et" : "Yeni Oyun",
                        systemImage: isWon ? "arrow.right.circle.fill" : "arrow.clockwise"
                    )
                    .font(.headline)
                    .padding(.horizontal, 32).padding(.vertical, 14)
                    .background(isWon ? Color(red: 0.15, green: 0.75, blue: 0.40) : .white)
                    .foregroundColor(isWon ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())

                // İkincil butonlar: Paylaş | Hata Bildir | Ana Menü
                HStack(spacing: 12) {
                    // Paylaş
                    Button {
                        Task { @MainActor in
                            let data = GameShareData(
                                modeName: "Sonsuz Mod",
                                word: vm.currentWord,
                                category: vm.category,
                                wrongGuesses: vm.wrongGuesses,
                                maxWrong: vm.maxWrongGuesses,
                                won: isWon,
                                streak: stats.currentStreak
                            )
                            if let img = renderShareImage(GameShareCard(data: data)) {
                                shareItems = [img]
                            } else {
                                shareItems = ["Keligo'da \(isWon ? "kazandım" : "kaybettim")! #Keligo"]
                            }
                            showShare = true
                        }
                    } label: {
                        iconButton("square.and.arrow.up")
                    }

                    // Hata Bildir
                    Button { showWordReport = true } label: {
                        iconButton("flag.fill", tint: .orange)
                    }

                    // Ana Menü
                    Button(action: onBack) {
                        iconButton("house.fill")
                    }
                }
            }
            .padding(32)
        }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showOutOfLives) {
            OutOfLivesSheet()
                .environmentObject(settings)
                .environmentObject(jetons)
        }
        .sheet(isPresented: $showWordReport) {
            WordReportSheet(word: vm.currentWord, category: vm.category)
                .environmentObject(settings)
        }
    }

    @ViewBuilder
    private func iconButton(_ icon: String, tint: Color = .white) -> some View {
        Image(systemName: icon)
            .font(.headline)
            .padding(14)
            .background(settings.theme.cardFill)
            .foregroundColor(tint)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Key press button style

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}

// MARK: - Key button

struct KeyButton: View {
    let letter: Character
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    private var isIPad: Bool { sizeClass == .regular }
    private var isGuessed: Bool { vm.guessedLetters.contains(letter) }
    private var isWrong:   Bool { isGuessed && !vm.currentWord.contains(letter) }
    private var isCorrect: Bool { isGuessed && vm.currentWord.contains(letter) }

    var body: some View {
        Button {
            if settings.hapticEnabled && !isGuessed {
                CinematicHaptics.shared.play(.keyPress)
            }
            vm.guess(letter)
        } label: {
            keyFace.frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 46)
        }
        .disabled(isGuessed || vm.gameState != .playing)
        .buttonStyle(KeyPressStyle())
    }

    @ViewBuilder
    private var keyFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(baseFill)
                .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)

            if !isGuessed {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                        startPoint: .top,
                        endPoint: .init(x: 0.5, y: 0.55)
                    ))
            }

            if isWrong {
                ZStack {
                    // Letter small at top-left so it doesn't clash with the X
                    Text(String(letter))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(theme.wrong.opacity(0.40))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, 3).padding(.leading, 4)
                    // X centered and prominent
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(theme.wrong.opacity(0.70))
                }
            } else {
                Text(String(letter))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isCorrect ? .white : theme.primaryText)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: 0.75)
        )
        .shadow(color: isCorrect ? theme.correct.opacity(0.55) : .clear, radius: 8, y: 0)
    }

    private var baseFill: AnyShapeStyle {
        if isCorrect {
            return AnyShapeStyle(LinearGradient(
                colors: [theme.correct, theme.correct.opacity(0.72)],
                startPoint: .top, endPoint: .bottom))
        }
        if isWrong { return AnyShapeStyle(theme.wrong.opacity(0.13)) }

        switch settings.keyboardStyle {
        case .glass:
            return AnyShapeStyle(theme.cardFill)
        case .flat:
            return AnyShapeStyle(theme.surface)
        case .minimal:
            return AnyShapeStyle(Color.clear)
        case .colorful:
            return AnyShapeStyle(theme.accent.opacity(0.18))
        }
    }

    private var shadowColor: Color {
        if isCorrect { return theme.correct.opacity(0.30) }
        if isWrong   { return .clear }
        return Color.black.opacity(theme.isDark ? 0.40 : 0.14)
    }
    private var shadowRadius: CGFloat { isCorrect ? 6 : 2 }
    private var shadowY: CGFloat      { isCorrect ? 0 : 2 }

    private var strokeColor: Color {
        if isCorrect { return Color.white.opacity(0.28) }
        if isWrong   { return theme.wrong.opacity(0.28) }
        switch settings.keyboardStyle {
        case .minimal:  return theme.accent.opacity(0.45)
        case .colorful: return theme.accent.opacity(0.35)
        default:        return Color.white.opacity(theme.isDark ? 0.10 : 0.50)
        }
    }
}

// MARK: - Jeton action button

struct JetonActionButton: View {
    let icon: String
    let title: String
    let cost: Int
    let canAct: Bool           // oyun durumu bu aksiyona izin veriyor mu?
    let canAfford: Bool        // jeton yeterli mi?
    let theme: AppTheme
    let accentColor: Color     // buton vurgu rengi (maliyet 0 ise kullanılır)
    let onInsufficientFunds: () -> Void
    let action: () -> Void

    init(icon: String, title: String, cost: Int, canAct: Bool, canAfford: Bool,
         theme: AppTheme, accentColor: Color = .white,
         onInsufficientFunds: @escaping () -> Void, action: @escaping () -> Void) {
        self.icon = icon; self.title = title; self.cost = cost
        self.canAct = canAct; self.canAfford = canAfford
        self.theme = theme; self.accentColor = accentColor
        self.onInsufficientFunds = onInsufficientFunds; self.action = action
    }

    var body: some View {
        Button {
            guard canAct else { return }
            if canAfford { action() } else { onInsufficientFunds() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(cost == 0 ? accentColor : (canAct ? theme.primaryText : theme.secondaryText))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(cost == 0 ? accentColor : (canAct ? theme.primaryText : theme.secondaryText))
                    if cost > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.yellow)
                            Text("\(cost)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(canAfford ? .yellow : .orange)
                        }
                    } else {
                        Text("İzle")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(accentColor.opacity(0.85))
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                cost == 0 ? AnyShapeStyle(accentColor.opacity(0.12)) : AnyShapeStyle(theme.cardFill),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cost == 0 ? accentColor.opacity(0.25) : Color.clear, lineWidth: 1)
            )
            .opacity(canAct ? 1.0 : 0.38)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Guess History View

struct GuessHistoryView: View {
    let history: [(letter: Character, wasCorrect: Bool)]
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tahmin Geçmişi")
                    .font(.headline.weight(.bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text("\(history.count) tahmin")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(history.enumerated()), id: \.offset) { idx, guess in
                        VStack(spacing: 4) {
                            Text(String(guess.letter))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(
                                    guess.wasCorrect
                                        ? theme.correct.opacity(0.9)
                                        : theme.wrong.opacity(0.75),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            Text("\(idx + 1)")
                                .font(.system(size: 8))
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(theme.correct).frame(width: 8, height: 8)
                    Text("Doğru: \(history.filter { $0.wasCorrect }.count)").font(.caption).foregroundColor(theme.secondaryText)
                }
                HStack(spacing: 6) {
                    Circle().fill(theme.wrong).frame(width: 8, height: 8)
                    Text("Yanlış: \(history.filter { !$0.wasCorrect }.count)").font(.caption).foregroundColor(theme.secondaryText)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(theme.background)
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(AchievementManager.shared)
        .environmentObject(JetonManager.shared)
}
