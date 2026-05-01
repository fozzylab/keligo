import SwiftUI

struct ChapterSelectView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var manager = ChapterManager.shared
    let onBack: () -> Void

    @State private var selectedChapter: Chapter? = nil

    var t: AppTheme { settings.theme }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()
            RadialGradient(
                colors: [t.glowColor, .clear],
                center: .topTrailing, startRadius: 0, endRadius: 320
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                            .foregroundStyle(t.accentGradient)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                    Text("Bölüm Modu")
                        .font(.headline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Spacer()
                    Color.clear.frame(width: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Chapter overview hero
                let completed  = manager.chapters.filter { (manager.stars[$0.id] ?? 0) > 0 }.count
                let totalStars = manager.chapters.reduce(0) { $0 + (manager.stars[$1.id] ?? 0) }
                let maxStars   = manager.chapters.count * 3

                ChapterHeroBar(
                    completed: completed,
                    total: manager.chapters.count,
                    totalStars: totalStars,
                    maxStars: maxStars,
                    theme: t
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(manager.chapters) { chapter in
                            ChapterCard(
                                chapter: chapter,
                                stars: manager.stars[chapter.id] ?? 0,
                                unlocked: manager.isUnlocked(chapter),
                                theme: t
                            )
                            .onTapGesture {
                                if manager.isUnlocked(chapter) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedChapter = chapter
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }

            if let chapter = selectedChapter {
                ChapterGameView(
                    chapter: chapter,
                    settings: settings,
                    stats: stats,
                    onBack: { withAnimation(.easeInOut(duration: 0.3)) { selectedChapter = nil } }
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedChapter?.id)
    }
}

// MARK: - Chapter Hero Bar

private struct ChapterHeroBar: View {
    let completed: Int
    let total: Int
    let totalStars: Int
    let maxStars: Int
    let theme: AppTheme

    private var completion: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }
    private var starProgress: Double {
        maxStars == 0 ? 0 : Double(totalStars) / Double(maxStars)
    }
    private var motivationLabel: String {
        if completed == 0  { return "İlk bölümü aç ve başla! 🎯" }
        if completed < 5   { return "Harika gidiyorsun, devam et! 🔥" }
        if completed < total { return "Şampiyon yolundasın! 👑" }
        return "Tüm bölümler tamamlandı! 🏆"
    }

    var body: some View {
        VStack(spacing: 10) {
            // Stats row + progress ring
            HStack(spacing: 0) {
                // ⭐ Stars
                statPill(icon: "star.fill", color: .yellow,
                         value: "\(totalStars)/\(maxStars)", label: "Yıldız")
                divider()
                // ✓ Bölümler
                statPill(icon: "checkmark.circle.fill", color: theme.accent,
                         value: "\(completed)/\(total)", label: "Bölüm")
                divider()
                // 🏆 Yüzde
                statPill(icon: "percent", color: .green,
                         value: "\(Int(completion * 100))%", label: "Tamamlandı")

                // Progress ring — right side
                Spacer(minLength: 12)
                ZStack {
                    Circle()
                        .stroke(theme.secondaryText.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: starProgress)
                        .stroke(
                            LinearGradient(colors: [.yellow, theme.accent],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: totalStars)
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(theme.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )

            // Motivasyon etiketi
            Text(motivationLabel)
                .font(.caption.weight(.medium))
                .foregroundColor(theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private func statPill(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
                Text(value).font(.subheadline.weight(.black)).foregroundColor(theme.primaryText)
            }
            Text(label).font(.caption2).foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle()
            .fill(theme.secondaryText.opacity(0.18))
            .frame(width: 1, height: 36)
    }
}

// MARK: - Chapter Card

struct ChapterCard: View {
    let chapter: Chapter
    let stars: Int
    let unlocked: Bool
    let theme: AppTheme

    private let chapterGradients: [[Color]] = [
        [Color(red: 0.20, green: 0.80, blue: 0.40), Color(red: 0.10, green: 0.60, blue: 0.30)],
        [Color(red: 1.00, green: 0.55, blue: 0.10), Color(red: 1.00, green: 0.80, blue: 0.20)],
        [Color(red: 1.00, green: 0.25, blue: 0.25), Color(red: 0.90, green: 0.10, blue: 0.50)],
        [Color(red: 0.60, green: 0.20, blue: 1.00), Color(red: 0.90, green: 0.40, blue: 1.00)],
    ]

    private var gradient: [Color] {
        chapterGradients[min(chapter.id, chapterGradients.count - 1)]
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        unlocked
                            ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: (unlocked ? gradient.first : .clear)?.opacity(0.4) ?? .clear, radius: 8, y: 4)

                if unlocked {
                    Text(chapter.icon).font(.title2)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(unlocked ? theme.primaryText : theme.secondaryText)
                Text(chapter.subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)

                // Stars
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i < stars ? .yellow : theme.secondaryText.opacity(0.3))
                    }
                }
            }

            Spacer()

            if unlocked {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(16)
        .background(theme.cardMaterial, in: RoundedRectangle(cornerRadius: 20))
        .opacity(unlocked ? 1 : 0.6)
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ChapterSelectView(onBack: {})
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(JetonManager.shared)
}
