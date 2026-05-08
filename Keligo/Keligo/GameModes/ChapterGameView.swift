import SwiftUI

struct ChapterGameView: View {
    let chapter: Chapter
    let settings: SettingsViewModel
    let stats: StatsManager
    let onBack: () -> Void

    @StateObject private var vm: GameViewModel
    @StateObject private var manager = ChapterManager.shared
    @State private var wordIndex = 0
    @State private var results: [Bool] = []
    @State private var showSummary = false

    private var words: [WordEntry]

    init(chapter: Chapter, settings: SettingsViewModel, stats: StatsManager, onBack: @escaping () -> Void) {
        self.chapter = chapter
        self.settings = settings
        self.stats = stats
        self.onBack = onBack
        // Compute words with next playCount without mutating @Published in init (causes SwiftUI warning)
        let nextPlayCount = (ChapterManager.shared.playCounts[chapter.id] ?? 0) + 1
        let w = ChapterManager.shared.words(for: chapter, overridePlayCount: nextPlayCount)
        self.words = w
        _vm = StateObject(wrappedValue: GameViewModel(settings: settings, stats: stats, fixedEntry: w.first))
    }

    var t: AppTheme { settings.theme }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            if showSummary {
                ChapterSummaryView(
                    chapter: chapter,
                    results: results,
                    theme: t,
                    onBack: onBack,
                    onRetry: retry
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                GameBoardView(vm: vm, theme: t,
                              modeLabel: "\(chapter.icon) \(chapter.title) — \(wordIndex + 1)/\(words.count)",
                              onBack: onBack) {
                    ChapterGameOverView(vm: vm, theme: t, onNext: advanceWord, onBack: onBack)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSummary)
        .onAppear {
            ChapterManager.shared.incrementPlayCount(for: chapter.id)
        }
    }

    private func advanceWord() {
        results.append(vm.gameState == .won)
        let next = wordIndex + 1
        if next >= words.count {
            manager.recordResult(chapterId: chapter.id, wins: results.filter { $0 }.count, total: words.count)
            withAnimation { showSummary = true }
        } else {
            wordIndex = next
            vm.loadWord(words[wordIndex])
        }
    }

    private func retry() {
        wordIndex = 0
        results = []
        showSummary = false
        vm.loadWord(words[0])
    }
}

// MARK: - Chapter game-over overlay

struct ChapterGameOverView: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(vm.gameState == .won ? "🎉" : "❌")
                    .font(.system(size: 64))

                Text(vm.gameState == .won ? "Doğru!" : "Yanlış!")
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

                HStack(spacing: 14) {
                    // Back button
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Next button
                    Button(action: onNext) {
                        HStack(spacing: 8) {
                            Text("Sonraki")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Chapter summary

struct ChapterSummaryView: View {
    let chapter: Chapter
    let results: [Bool]
    let theme: AppTheme
    let onBack: () -> Void
    let onRetry: () -> Void

    @StateObject private var manager = ChapterManager.shared
    @State private var showShare  = false
    @State private var shareItems: [Any] = []
    @State private var animateStars = false

    private var wins: Int { results.filter { $0 }.count }
    private var stars: Int { manager.stars[chapter.id] ?? 0 }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            RadialGradient(
                colors: [theme.glowColor, .clear],
                center: .top, startRadius: 0, endRadius: 350
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                            .foregroundStyle(theme.accentGradient)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 16)

                Spacer()

                // Chapter icon with glow
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .blur(radius: 20)
                    Text(chapter.icon)
                        .font(.system(size: 72))
                }

                Text(chapter.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .padding(.top, 8)

                // Stars
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 42))
                            .foregroundColor(i < stars ? .yellow : theme.secondaryText.opacity(0.25))
                            .scaleEffect(animateStars && i < stars ? 1.2 : 1.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.5)
                                    .delay(Double(i) * 0.15),
                                value: animateStars
                            )
                    }
                }
                .padding(.vertical, 20)

                // Score
                Text("\(wins)/\(results.count) kelime doğru")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(theme.secondaryText)

                // Result dots
                HStack(spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, won in
                        Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(won ? theme.correct : theme.wrong)
                    }
                }
                .padding(.vertical, 12)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: onRetry) {
                            Label("Tekrar", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(theme.primaryText)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button(action: onBack) {
                            Label("Bölümler", systemImage: "flag.checkered")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Button {
                        Task { @MainActor in
                            let card = ChapterShareCard(
                                chapterTitle: chapter.title,
                                chapterIcon: chapter.icon,
                                results: results,
                                stars: stars
                            )
                            if let img = renderShareImage(card) {
                                shareItems = [img]
                            } else {
                                shareItems = [buildShareText()]
                            }
                            showShare = true
                        }
                    } label: {
                        Label("Sonucu Paylaş", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateStars = true
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    private func buildShareText() -> String {
        let starStr = String(repeating: "⭐️", count: stars) +
                      String(repeating: "☆", count: max(0, 3 - stars))
        let resultStr = results.map { $0 ? "✅" : "❌" }.joined(separator: "")
        return "🔡 Keligo\n📖 \(chapter.title)\n\(starStr) \(wins)/\(results.count) doğru\n\(resultStr)\n#Keligo"
    }
}

#Preview {
    ChapterGameView(
        chapter: ChapterManager.shared.chapters[0],
        settings: SettingsViewModel(),
        stats: StatsManager(),
        onBack: {}
    )
    .environmentObject(SettingsViewModel())
    .environmentObject(StatsManager())
    .environmentObject(AchievementManager.shared)
    .environmentObject(JetonManager.shared)
}
