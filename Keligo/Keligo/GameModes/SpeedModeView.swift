import SwiftUI
import Combine

class SpeedGameState: ObservableObject {
    @Published var currentWord = ""
    @Published var category = ""
    @Published var guessedLetters: Set<Character> = []
    @Published var wrongGuesses = 0
    @Published var wordsCompleted = 0
    @Published var timeRemaining: Double
    @Published var gameEnded = false
    @Published var lastCorrectLetter: Character? = nil

    let maxWrong = 4
    private let sound = SoundManager.shared
    var soundEnabled = true
    var hapticEnabled = true

    init(duration: Double = 60) {
        self.timeRemaining = duration
        nextWord()
    }

    func reset(duration: Double) {
        timeRemaining = duration
        wordsCompleted = 0
        gameEnded = false
        guessedLetters = []
        wrongGuesses = 0
        nextWord()
    }

    var displayWord: [Character] {
        currentWord.map { guessedLetters.contains($0) ? $0 : "_" }
    }

    func guess(_ letter: Character) {
        guard !guessedLetters.contains(letter), !gameEnded else { return }
        guessedLetters.insert(letter)
        sound.soundEnabled = soundEnabled
        sound.hapticEnabled = hapticEnabled

        if !currentWord.contains(letter) {
            wrongGuesses += 1
            sound.playWrong()
            if wrongGuesses >= maxWrong { nextWord() }
        } else {
            lastCorrectLetter = letter
            sound.playCorrect()
            if displayWord.allSatisfy({ $0 != "_" }) {
                wordsCompleted += 1
                sound.playWin()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.nextWord() }
            }
        }
    }

    func tick(by delta: Double) {
        guard !gameEnded else { return }
        timeRemaining = max(0, timeRemaining - delta)
        if timeRemaining == 0 { gameEnded = true }
    }

    private func nextWord() {
        let entry = WordList.random()
        currentWord = entry.word
        category = entry.category
        guessedLetters = []
        wrongGuesses = 0
        lastCorrectLetter = nil
    }
}

private let speedRows: [[Character]] = [
    ["A","B","C","Ç","D","E","F","G","Ğ"],
    ["H","I","İ","J","K","L","M","N","O"],
    ["Ö","P","R","S","Ş","T","U","Ü","V"],
    ["Y","Z"]
]

struct SpeedModeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var state = SpeedGameState()
    let onBack: () -> Void

    @State private var bouncingIndices: Set<Int> = []
    @State private var shakeCount: CGFloat = 0
    @State private var gameStarted = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var t: AppTheme { settings.theme }

    private var timerColor: Color {
        if state.timeRemaining > 20 { return t.correct }
        if state.timeRemaining > 10 { return .orange }
        return t.wrong
    }

    private var startScreen: some View {
        ZStack {
            t.background.ignoresSafeArea()
            RadialGradient(colors: [t.glowColor, .clear], center: .top, startRadius: 0, endRadius: 300)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                            .foregroundStyle(t.accentGradient)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 12)

                Spacer()

                Text("⚡️").font(.system(size: 80))

                Text("Hız Modu")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(t.primaryText)

                Text("Süre seç ve başla")
                    .font(.subheadline)
                    .foregroundColor(t.secondaryText)

                // Time options
                VStack(spacing: 12) {
                    ForEach([30, 60, 90], id: \.self) { seconds in
                        Button { settings.speedDuration = seconds } label: {
                            HStack {
                                Text("\(seconds) Saniye")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(settings.speedDuration == seconds ? .white : t.primaryText)
                                Spacer()
                                if settings.speedDuration == seconds {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20).padding(.vertical, 16)
                            .background(
                                settings.speedDuration == seconds
                                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.18, blue: 0.18), Color(red: 1, green: 0.58, blue: 0.10)], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(t.cardMaterial),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)

                // Start button
                Button {
                    state.reset(duration: Double(settings.speedDuration))
                    gameStarted = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Başla!")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [Color(red: 1, green: 0.18, blue: 0.18), Color(red: 1, green: 0.58, blue: 0.10)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 1, green: 0.18, blue: 0.18).opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    var body: some View {
        if gameStarted {
            gameView
        } else {
            startScreen
        }
    }

    private var gameView: some View {
        ZStack {
            t.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(t.accent)
                    }
                    Spacer()
                    Text("⚡️ Hız Modu")
                        .font(.headline).foregroundColor(t.primaryText)
                    Spacer()
                    Text("🏆 \(stats.speedHighScore)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(t.secondaryText)
                }
                .padding(.horizontal, 20).padding(.top, 12)

                // Timer
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", state.timeRemaining))
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(timerColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: Int(state.timeRemaining))

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(t.surface)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(timerColor)
                                .frame(width: geo.size.width * (state.timeRemaining / Double(settings.speedDuration)), height: 8)
                                .animation(.linear(duration: 0.05), value: state.timeRemaining)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 12)

                // Score
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("\(state.wordsCompleted)")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(t.accent)
                        Text("kelime")
                            .font(.caption)
                            .foregroundColor(t.secondaryText)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                // Category + wrong indicator
                HStack(spacing: 8) {
                    Text(state.category)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(t.surface)
                        .foregroundColor(t.secondaryText)
                        .cornerRadius(8)

                    HStack(spacing: 4) {
                        ForEach(0..<state.maxWrong, id: \.self) { i in
                            Circle()
                                .fill(i < state.wrongGuesses ? t.wrong : t.surface)
                                .frame(width: 9, height: 9)
                        }
                    }
                }
                .padding(.bottom, 10)

                // Word
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(state.displayWord.enumerated()), id: \.offset) { idx, char in
                            VStack(spacing: 3) {
                                Text(char == "_" ? " " : String(char))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(t.primaryText)
                                    .frame(minWidth: 24)
                                    .scaleEffect(bouncingIndices.contains(idx) ? 1.4 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.4), value: bouncingIndices.contains(idx))
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(t.primaryText.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .modifier(ShakeEffect(animatableData: shakeCount))
                .padding(.bottom, 12)

                Spacer(minLength: 0)

                // Keyboard
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(t.isDark ? 0.18 : 0.45))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    VStack(spacing: 7) {
                        ForEach(speedRows, id: \.self) { row in
                            HStack(spacing: 5) {
                                ForEach(row, id: \.self) { letter in
                                    SpeedKeyButton(letter: letter, state: state, theme: t)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(t.isDark ? 0.06 : 0.55),
                                        Color.white.opacity(t.isDark ? 0.02 : 0.20)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        VStack {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(t.isDark ? 0.18 : 0.60))
                                .frame(height: 1).padding(.horizontal, 1)
                            Spacer()
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 20, y: -4)
                .padding(.horizontal, -8)
                .ignoresSafeArea(edges: .bottom)
            }

            // Game over
            if state.gameEnded {
                SpeedResultOverlay(
                    score: state.wordsCompleted,
                    highScore: stats.speedHighScore,
                    theme: t,
                    onBack: onBack,
                    onRetry: {
                        state.reset(duration: Double(settings.speedDuration))
                    }
                )
            }
        }
        .onReceive(timer) { _ in
            state.soundEnabled = settings.soundEnabled
            state.hapticEnabled = settings.hapticEnabled
            let wasRunning = !state.gameEnded
            state.tick(by: 0.05)
            if state.gameEnded && wasRunning {
                if state.wordsCompleted > stats.speedHighScore {
                    stats.speedHighScore = state.wordsCompleted
                }
                GameCenterManager.shared.submitSpeedScore(state.wordsCompleted)
                achievementManager.check(stats: stats, chapters: ChapterManager.shared)
            }
        }
        .onChange(of: state.wrongGuesses) {
            withAnimation(.linear(duration: 0.4)) { shakeCount += 1 }
        }
        .onChange(of: state.lastCorrectLetter) { _, letter in
            guard let letter else { return }
            let indices = Set(state.displayWord.enumerated().compactMap { $0.element == letter ? $0.offset : nil })
            bouncingIndices.formUnion(indices)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { bouncingIndices.subtract(indices) }
        }
    }
}

struct SpeedKeyButton: View {
    let letter: Character
    @ObservedObject var state: SpeedGameState
    let theme: AppTheme

    private var isGuessed: Bool { state.guessedLetters.contains(letter) }
    private var isWrong: Bool   { isGuessed && !state.currentWord.contains(letter) }
    private var isCorrect: Bool { isGuessed && state.currentWord.contains(letter) }

    var body: some View {
        Button { state.guess(letter) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(baseFill)
                    .shadow(color: shadowColor, radius: isCorrect ? 5 : 2, y: isCorrect ? 0 : 2)

                if !isGuessed {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0)],
                                startPoint: .top, endPoint: .init(x: 0.5, y: 0.55)
                            )
                        )
                }

                if isWrong {
                    ZStack(alignment: .topTrailing) {
                        Text(String(letter))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.wrong.opacity(0.40))
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(theme.wrong.opacity(0.50))
                            .offset(x: 2, y: -2)
                    }
                } else {
                    Text(String(letter))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isCorrect ? .white : theme.primaryText)
                }
            }
            .frame(width: 34, height: 42)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 0.75)
            )
            .shadow(color: isCorrect ? theme.correct.opacity(0.50) : .clear, radius: 6)
        }
        .disabled(isGuessed || state.gameEnded)
        .buttonStyle(KeyPressStyle())
    }

    private var baseFill: AnyShapeStyle {
        if isCorrect {
            return AnyShapeStyle(LinearGradient(
                colors: [theme.correct, theme.correct.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        if isWrong { return AnyShapeStyle(theme.wrong.opacity(0.12)) }
        return AnyShapeStyle(theme.cardMaterial)
    }

    private var shadowColor: Color {
        if isCorrect { return theme.correct.opacity(0.28) }
        return Color.black.opacity(theme.isDark ? 0.38 : 0.12)
    }

    private var strokeColor: Color {
        if isCorrect { return Color.white.opacity(0.25) }
        if isWrong   { return theme.wrong.opacity(0.25) }
        return Color.white.opacity(theme.isDark ? 0.10 : 0.48)
    }
}

struct SpeedResultOverlay: View {
    let score: Int
    let highScore: Int
    let theme: AppTheme
    let onBack: () -> Void
    let onRetry: () -> Void

    private var isNewRecord: Bool { score > highScore || highScore == 0 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("⏱️ Süre Doldu!")
                    .font(.largeTitle.bold()).foregroundColor(.white)

                VStack(spacing: 6) {
                    Text("\(score)")
                        .font(.system(size: 72, weight: .black))
                        .foregroundColor(theme.accent)
                    Text("kelime")
                        .font(.title3).foregroundColor(.white.opacity(0.8))
                }

                if isNewRecord && score > 0 {
                    Text("🎉 Yeni Rekor!")
                        .font(.headline)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .cornerRadius(10)
                } else {
                    Text("En İyi: \(max(score, highScore))")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 12) {
                    Button(action: onRetry) {
                        Label("Tekrar", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    Button(action: onBack) {
                        Label("Menü", systemImage: "house.fill")
                            .font(.headline)
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }

                Button {
                    GameCenterManager.shared.showLeaderboard()
                } label: {
                    Label("Liderlik Tablosu", systemImage: "list.number")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    SpeedModeView(onBack: {})
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(JetonManager.shared)
}
