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

            // Daily login reward toast — sadece splash bitti VE onboarding görüldü ise göster
            if splashPhase == .none && hasSeenOnboarding, let reward = dailyReward.pendingReward {
                DailyRewardToast(streak: reward.streak, jetons: reward.jetons) {
                    withAnimation(.spring()) { dailyReward.dismissReward() }
                }
                .zIndex(50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: dailyReward.pendingReward != nil)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: splashPhase == .none)
        // İlk kez açılışta onboarding bittikten sonra ödül kontrolü yap
        .onChange(of: hasSeenOnboarding) { _, newValue in
            guard newValue && splashPhase == .none else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dailyReward.checkAndClaim()
            }
        }
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
                    Text("+\(jetons) 🟡")
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
    @EnvironmentObject var stats: StatsManager
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
    @State private var showInsufficientJetonSheet = false  // jeton yetersiz ekranı
    @State private var showLivesInfo = false               // oyun içi can bilgi ekranı
    @State private var showOutOfLivesGame = false          // oyun içi OutOfLives sheet
    @State private var now = Date()  // lives countdown timer tick
    private let regenTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 2026: Continue after loss
    @State private var showContinueAfterLoss = false
    @State private var hasUsedContinue = false

    // Back confirmation (oyun sırasında 1 can gider)
    @State private var showBackConfirm = false

    // 2026: Word Lore sheet
    @State private var showWordLore = false
    @State private var loreWord: String = ""
    @State private var loreCategory: String = ""

    // "Son şansın!" — oyun başına 1 kez göster
    @State private var showLastChanceBanner = false
    @State private var lastChanceBannerShown = false

    // Undo prompt — yanlış tahminden hemen sonra 3.5 sn görünür
    @State private var showUndoPrompt = false

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
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        let ok = await AdManager.shared.presentRewarded(.continueGame)
                        if ok {
                            vm.continueAfterLoss()
                            hasUsedContinue = true
                            showContinueAfterLoss = false
                        }
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
                        showInsufficientJetonSheet = true
                    }
                } onDecline: {
                    showContinueAfterLoss = false
                }
            }

            if vm.gameState != .playing && !(vm.gameState == .lost && showContinueAfterLoss && !hasUsedContinue) {
                gameOverOverlay()
                if vm.gameState == .won { ConfettiView() }
            }

            // Undo prompt — yanlış tahminden sonra 3.5s kayan pill
            if showUndoPrompt && vm.gameState == .playing {
                VStack {
                    Spacer()
                    Button {
                        withAnimation { showUndoPrompt = false }
                        vm.undo()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Geri Al?")
                                .font(.subheadline.weight(.black))
                                .foregroundColor(.white)
                            HStack(spacing: 3) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7)).foregroundColor(.yellow)
                                Text("\(JetonManager.costUndo)")
                                    .font(.caption.weight(.bold)).foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.black.opacity(0.25), in: Capsule())
                        }
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.20, blue: 0.20),
                                         Color(red: 0.65, green: 0.10, blue: 0.10)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: .red.opacity(0.45), radius: 12, y: 4)
                        .disabled(!jetons.canAfford(JetonManager.costUndo))
                        .opacity(jetons.canAfford(JetonManager.costUndo) ? 1.0 : 0.55)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.bottom, 230)
                }
                .zIndex(45)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showUndoPrompt)
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
        .alert("Oyundan Çık?", isPresented: $showBackConfirm) {
            Button("Çık", role: .destructive) {
                if !lives.hasInfinite { lives.loseOne() }
                // Oyun yarıda bırakıldı — istatistiklere kayıp olarak yaz
                if vm.gameState == .playing {
                    stats.recordLoss(category: vm.category)
                }
                onBack()
            }
            Button("Devam Et", role: .cancel) {}
        } message: {
            Text("Oyundan çıkarsan \(lives.hasInfinite ? "canın gitmez" : "1 canın gider"). Emin misin?")
        }
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
            WordLoreSheet(word: loreWord, category: loreCategory, theme: theme)
        }
        .sheet(isPresented: $showLivesInfo) {
            LivesInfoSheet(
                lives: lives,
                onRefill: { showOutOfLivesGame = true },
                onDismiss: { showLivesInfo = false }
            )
            .environmentObject(settings)
            .environmentObject(jetons)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showOutOfLivesGame) {
            OutOfLivesSheet()
                .environmentObject(settings)
                .environmentObject(jetons)
        }
        .sheet(isPresented: $showInsufficientJetonSheet) {
            InsufficientJetonSheet(
                onWatchAd: {
                    showInsufficientJetonSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        if AdManager.shared.canShowRewarded(.letter) {
                            showRewardedAdSimulation = true
                        } else {
                            showRewardedCapAlert = true
                        }
                    }
                },
                onGoStore: {
                    showInsufficientJetonSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showSettings = true }
                }
            )
            .environmentObject(settings)
            .environmentObject(jetons)
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
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
        .onChange(of: vm.wrongGuesses) {
            withAnimation(.linear(duration: 0.5)) { shakeCount += 1 }
            // 2026: Rich cinematic haptics
            if settings.hapticEnabled {
                CinematicHaptics.shared.play(isLastChance ? .lastChance : .wrong)
            }
            // Undo prompt: yanlış tahminden hemen sonra 3.5s göster
            if vm.gameState == .playing && vm.canUndo {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showUndoPrompt = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.4)) { showUndoPrompt = false }
                }
            }
            // Last-chance pulse
            if isLastChance {
                withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                    nearMissPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    nearMissPulse = false
                }
                // Banner: oyun başına sadece 1 kez
                if !lastChanceBannerShown {
                    lastChanceBannerShown = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        showLastChanceBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut) { showLastChanceBanner = false }
                    }
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
        .onChange(of: vm.gameState) { _, state in handleGameStateChange(state) }
        .onChange(of: vm.currentWord) {
            // Yeni kelimede son-şans bayrağını sıfırla
            lastChanceBannerShown = false
            showLastChanceBanner = false
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

            // "Neredeyse!" — sabit yükseklikte, görününce kayma olmaz
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
            .opacity(showNearSolvedBanner ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: showNearSolvedBanner)

            wrongLettersRow
            jetonActionsRow

            // "Son şansın!" — 1 kez göster, 2.5 saniye sonra kaybolur
            if showLastChanceBanner {
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

    // MARK: - Game state handler (extracted to avoid compiler type-check timeout)

    private func handleGameStateChange(_ state: GameState) {
        if state == .playing {
            showContinueAfterLoss = false
            hasUsedContinue = false
            return
        }
        if state == .lost && !hasUsedContinue {
            showContinueAfterLoss = true
            return
        }
        guard state != .playing else { return }

        ai.recordGame(
            word: vm.currentWord,
            won: state == .won,
            wrongGuesses: vm.wrongGuesses,
            duration: 0,
            category: vm.category
        )
        achievements.check(
            stats: vm.stats,
            chapters: ChapterManager.shared,
            wrongCount: vm.wrongGuesses,
            hintUsed: vm.hintUsed,
            won: state == .won
        )
        if !modeLabel.contains("Günlük") && !modeLabel.contains("Bölüm") && !modeLabel.contains("Hız") {
            AdManager.shared.notifyGameEnded()
            if AdManager.shared.shouldShowInterstitial() {
                Task { await AdManager.shared.presentInterstitial() }
            }
        }
        AppPromptManager.shared.notifyGameEnded(won: state == .won)
        if settings.hapticEnabled {
            CinematicHaptics.shared.play(state == .won ? .win : .loss)
        }
        if state == .won {
            // Kelimeyi şimdi yakala — 1.2s sonra vm.currentWord değişmiş olabilir
            loreWord = vm.currentWord
            loreCategory = vm.category
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showWordLore = true }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            // Gerçek ortalama: mod etiketi ZStack içinde tam ortada
            Text(modeLabel)
                .font(.caption.weight(.bold))
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(theme.cardFill, in: Capsule())
                .frame(maxWidth: .infinity)

            HStack {
            Button {
                if vm.gameState == .playing {
                    showBackConfirm = true
                } else {
                    onBack()
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title2)
                    .foregroundStyle(theme.accentGradient)
            }
            Spacer()
            HStack(spacing: 6) {
                // Lives pill — tıklanabilir, LivesInfoSheet açar
                Button { showLivesInfo = true } label: {
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
                }
                .buttonStyle(ScaleButtonStyle())

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                        .foregroundStyle(theme.accentGradient)
                }
            }
            }  // HStack kapanışı
            .padding(.horizontal, 20)
        }  // ZStack kapanışı
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

    /// Kademeli ipucu bölümü — 3 adım: ücretsiz metin → 1j 1 harf → 2j 2 harf daha.
    /// Kelimenin hint text'i yoksa gizlenir (eski useHint sistemi devreye girer).
    @ViewBuilder
    private var wordHintCard: some View {
        if vm.wordHintText != nil {
            VStack(spacing: 6) {
                // Tier 1 sonrası: hint metnini göster
                if vm.wordHintRevealed, let hint = vm.wordHintText {
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
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                // Kademeli ilerleme butonu
                if vm.canUseTieredHint {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            vm.useTieredHint()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: vm.tieredHintLevel == 0 ? "lightbulb" : "character.textbox")
                                .font(.subheadline.weight(.semibold))
                            Text(vm.tieredHintLevel == 0 ? "İpucu Al" :
                                 vm.tieredHintLevel == 1 ? "Bir Harf Aç" : "2 Harf Daha")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if vm.tieredHintLevel == 0 {
                                Text("ÜCRETSİZ")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.green.opacity(0.18), in: Capsule())
                            } else {
                                HStack(spacing: 2) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.yellow)
                                    Text("\(vm.tieredHintNextCost)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(
                                    jetons.canAfford(vm.tieredHintNextCost)
                                        ? AnyShapeStyle(Color.yellow.opacity(0.20))
                                        : AnyShapeStyle(theme.cardFill),
                                    in: Capsule()
                                )
                            }
                        }
                        .foregroundColor(vm.tieredHintLevel == 0 ? theme.primaryText :
                            jetons.canAfford(vm.tieredHintNextCost) ? theme.primaryText : theme.secondaryText)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                            vm.tieredHintLevel == 0
                                ? Color.green.opacity(0.35)
                                : Color.yellow.opacity(jetons.canAfford(vm.tieredHintNextCost) ? 0.30 : 0.10),
                            lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(vm.tieredHintLevel > 0 && !jetons.canAfford(vm.tieredHintNextCost))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.tieredHintLevel)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.wordHintRevealed)
        }
    }

    @ViewBuilder
    private var wordDisplay: some View {
        let chunks = wordChunks()
        if chunks.count > 1 {
            multiWordDisplay(chunks)
        } else {
            singleWordDisplay(chunks.first ?? [])
        }
    }

    private func multiWordDisplay(_ chunks: [[(offset: Int, char: Character)]]) -> some View {
        VStack(spacing: 8) {
            ForEach(chunks.indices, id: \.self) { row in
                wordTileRow(chunks[row])
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animatableData: shakeCount))
        .padding(.bottom, 10)
    }

    private func singleWordDisplay(_ items: [(offset: Int, char: Character)]) -> some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                wordTileRow(items)
                    .frame(minWidth: geo.size.width, alignment: .center)
            }
        }
        .frame(height: isIPad ? 72 : 58)
        .modifier(ShakeEffect(animatableData: shakeCount))
        .padding(.bottom, 10)
    }

    /// displayWord'ü boşluklarda bölerek (offset'i koruyan) chunk dizisi döner
    private func wordChunks() -> [[(offset: Int, char: Character)]] {
        var chunks: [[(offset: Int, char: Character)]] = []
        var current: [(offset: Int, char: Character)] = []
        for (idx, ch) in vm.displayWord.enumerated() {
            if ch == " " {
                if !current.isEmpty { chunks.append(current); current = [] }
            } else {
                current.append((offset: idx, char: ch))
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks.isEmpty ? [[]] : chunks
    }

    private func wordTileRow(_ items: [(offset: Int, char: Character)]) -> some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.offset) { item in
                CrystalLetterTile(
                    letter: item.char,
                    isRevealed: item.char != "_",
                    isSpace: false,
                    theme: theme,
                    accent: theme.correct,
                    isBouncing: bouncingIndices.contains(item.offset),
                    index: item.offset
                )
                .padding(.horizontal, 3)
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
            // Hint text'i olan kelimelerde kademeli sistem wordHintCard'da görünür;
            // hint text'i olmayan kelimelerde klasik "ücretsiz harf aç" butonu göster.
            if vm.wordHintText == nil {
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
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Jeton action buttons

    private var jetonActionsRow: some View {
        VStack(spacing: 4) {
            // Jeton bakiyesi — üst bar'dan kaldırıldı, bağlamsal olarak burada
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.yellow)
                Text("\(jetons.balance) jeton")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)

            // Tüm butonlar eşit genişlikte, buton sayısına göre otomatik sığar.
            HStack(spacing: 8) {
            // 1. Jeton Kazan — her zaman sol başta
            if vm.canWatchRewardedAd {
                JetonActionButton(
                    icon: "play.rectangle.fill",
                    title: "Harf Aç",
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

            // 2. Sesli Harf
            JetonActionButton(
                icon: "character.textbox",
                title: "Sesli Harf",
                cost: JetonManager.costVowel,
                canAct: vm.hasUnrevealedVowels && vm.gameState == .playing,
                canAfford: jetons.canAfford(JetonManager.costVowel),
                theme: theme,
                onInsufficientFunds: { showInsufficientJetonSheet = true }
            ) { vm.buyVowel() }

            // 3. Harf Al
            JetonActionButton(
                icon: "lightbulb",
                title: "Harf Al",
                cost: JetonManager.costLetter,
                canAct: vm.gameState == .playing,
                canAfford: jetons.canAfford(JetonManager.costLetter),
                theme: theme,
                onInsufficientFunds: { showInsufficientJetonSheet = true }
            ) { vm.buyLetter() }

            // 4. Pas — sadece mümkünse göster
            if vm.canSkip {
                JetonActionButton(
                    icon: "forward.fill",
                    title: "Pas",
                    cost: JetonManager.costSkip,
                    canAct: vm.gameState == .playing,
                    canAfford: jetons.canAfford(JetonManager.costSkip),
                    theme: theme,
                    onInsufficientFunds: { showInsufficientJetonSheet = true }
                ) { vm.skipWord() }
            }

            // 5. Geri Al — sadece mümkünse göster
            if vm.canUndo {
                JetonActionButton(
                    icon: "arrow.uturn.backward",
                    title: "Geri Al",
                    cost: JetonManager.costUndo,
                    canAct: vm.gameState == .playing,
                    canAfford: jetons.canAfford(JetonManager.costUndo),
                    theme: theme,
                    onInsufficientFunds: { showInsufficientJetonSheet = true }
                ) { vm.undo() }
            }
            }  // HStack kapanışı
            .padding(.horizontal, 16)
        }  // VStack kapanışı
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

    @State private var showOutOfLives    = false
    @State private var showWordReport    = false
    @State private var streakProtected   = false   // Seri bu oyunda kalkan/jeton ile korunduysa true

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

                // Kazanınca: streak rozeti
                if isWon && stats.currentStreak > 1 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(stats.currentStreak) galibiyet serisi 🔥")
                            .font(.subheadline.weight(.bold)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.orange.opacity(0.20), in: Capsule())
                }

                // Kaybedince: streak koruma teklifi
                if !isWon {
                    if streakProtected {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.fill").foregroundColor(.cyan)
                            Text("Seri korundu! \(stats.currentStreak) gün")
                                .font(.subheadline.weight(.bold)).foregroundColor(.white)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.20), in: Capsule())
                    } else if stats.canUseStreakProtection {
                        VStack(spacing: 8) {
                            // Jeton ile koru
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
                                .background(Color.orange.opacity(0.22))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.50), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(!jetons.canAfford(JetonManager.costStreakProtection))
                            .opacity(jetons.canAfford(JetonManager.costStreakProtection) ? 1 : 0.45)

                            // Reklam ile koru
                            Button {
                                Task {
                                    let granted = await AdManager.shared.presentRewarded(.streakSave)
                                    if granted {
                                        stats.restoreStreakFromAd()
                                        withAnimation { streakProtected = true }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.rectangle.fill").foregroundColor(.yellow)
                                    Text("Reklamla Seriyi Koru").font(.caption.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.80))
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.white.opacity(0.10), in: Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
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
                    // Paylaş (emoji grid + kart görseli)
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
                            let emojiGrid = buildEmojiGrid(
                                history: vm.guessHistory,
                                won: isWon,
                                wrongCount: vm.wrongGuesses,
                                maxWrong: vm.maxWrongGuesses,
                                modeLabel: "Sonsuz Mod",
                                streak: stats.currentStreak
                            )
                            var items: [Any] = [emojiGrid]
                            if let img = renderShareImage(GameShareCard(data: data)) {
                                items.insert(img, at: 0)
                            }
                            presentShareSheet(items)
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
            .background(Color.white.opacity(0.15))
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
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(cost == 0 ? accentColor : (canAct ? theme.primaryText : theme.secondaryText))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(cost == 0 ? accentColor : (canAct ? theme.primaryText : theme.secondaryText))
                    .lineLimit(1).minimumScaleFactor(0.7)
                // Her zaman 3. satır — eşit yükseklik için (cost==0 ise boş)
                HStack(spacing: 2) {
                    if cost > 0 {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("\(cost)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(canAfford ? .yellow : .orange)
                    } else {
                        Color.clear.frame(height: 10)
                    }
                }
                .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                cost == 0 ? AnyShapeStyle(accentColor.opacity(0.14)) : AnyShapeStyle(theme.cardFill),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cost == 0 ? accentColor.opacity(0.30) : theme.cardStroke, lineWidth: 1)
            )
            .opacity(canAct ? 1.0 : 0.50)
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

// MARK: - Insufficient Jeton Sheet

struct InsufficientJetonSheet: View {
    let onWatchAd: () -> Void
    let onGoStore: () -> Void

    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    private let ad = AdManager.shared
    var t: AppTheme { settings.theme }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(t.secondaryText.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Image(systemName: "circle.slash")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .padding(.bottom, 10)

            Text("Yeterli Jeton Yok")
                .font(.title2.weight(.black))
                .foregroundColor(t.primaryText)
            Text("Bakiye: \(jetons.balance) jeton")
                .font(.subheadline)
                .foregroundColor(t.secondaryText)
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                // Reklam izle
                Button(action: onWatchAd) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "play.rectangle.fill").foregroundColor(.purple))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reklam İzle")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(t.primaryText)
                            Text(ad.canShowRewarded(.letter)
                                 ? "Kısa video → jeton kazan"
                                 : "Bugünkü hak doldu")
                                .font(.caption)
                                .foregroundColor(t.secondaryText)
                        }
                        Spacer()
                        Text("+🟡")
                            .font(.caption.weight(.black))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.purple.opacity(0.15), in: Capsule())
                    }
                    .padding(14)
                    .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.cardStroke, lineWidth: 0.8))
                    .opacity(ad.canShowRewarded(.letter) ? 1 : 0.45)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!ad.canShowRewarded(.letter))

                // Mağaza
                Button(action: onGoStore) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.yellow.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "bag.fill").foregroundColor(.yellow))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jeton Satın Al")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(t.primaryText)
                            Text("Mağazadan jeton paketi seç")
                                .font(.caption)
                                .foregroundColor(t.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(t.secondaryText)
                    }
                    .padding(14)
                    .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.cardStroke, lineWidth: 0.8))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            Button("Kapat") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(t.secondaryText)
                .padding(.top, 16)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(t.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(AchievementManager.shared)
        .environmentObject(JetonManager.shared)
}
