import SwiftUI

struct ChapterSelectView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var manager = ChapterManager.shared
    let onBack: () -> Void

    @State private var selectedChapter: Chapter? = nil

    var t: AppTheme { settings.theme }

    // Computed stats
    private var completed: Int  { manager.chapters.filter { (manager.stars[$0.id] ?? 0) > 0 }.count }
    private var totalStars: Int { manager.chapters.reduce(0) { $0 + (manager.stars[$1.id] ?? 0) } }
    private var maxStars: Int   { manager.chapters.count * 3 }

    var body: some View {
        // Use the background as the root fill — overlay puts content at the top
        t.background
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    // ── Hero banner ──────────────────────────────────────────
                    ChapterHeroBanner(
                        completed: completed,
                        total: manager.chapters.count,
                        totalStars: totalStars,
                        maxStars: maxStars,
                        theme: t,
                        onBack: onBack
                    )

                    // ── Motivation label ─────────────────────────────────────
                    Text(motivationLabel)
                        .font(.caption.weight(.medium))
                        .foregroundColor(t.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    // ── Chapter list ─────────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
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
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .overlay {
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

    private var motivationLabel: String {
        if completed == 0 { return "İlk bölümü aç ve başla! 🎯" }
        if completed < 5  { return "Harika gidiyorsun, devam et! 🔥" }
        if completed < manager.chapters.count { return "Şampiyon yolundasın! 👑" }
        return "Tüm bölümler tamamlandı! 🏆"
    }
}

// MARK: - Chapter Hero Banner

private struct ChapterHeroBanner: View {
    let completed: Int
    let total: Int
    let totalStars: Int
    let maxStars: Int
    let theme: AppTheme
    let onBack: () -> Void

    private var starProgress: Double {
        maxStars == 0 ? 0 : Double(totalStars) / Double(maxStars)
    }
    private var completionPct: Int {
        total == 0 ? 0 : Int((Double(completed) / Double(total)) * 100)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [theme.accent, theme.accent.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180)
                .offset(x: 100, y: -30)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 120)
                .offset(x: -80, y: 20)

            VStack(spacing: 0) {
                // Back button row
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                            Text("Geri")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Icon + title
                HStack(alignment: .center, spacing: 18) {
                    // Big icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 68, height: 68)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bölüm Modu")
                            .font(.title2.weight(.black))
                            .foregroundColor(.white)
                        Text("Kategoriden kategoriye ilerle")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.78))
                    }

                    Spacer()

                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: starProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: totalStars)
                        Text("\(completionPct)%")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 18)

                // Stats row
                HStack(spacing: 0) {
                    statPill(value: "\(totalStars)", unit: "/\(maxStars)", label: "Yıldız", icon: "star.fill", color: .yellow)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 28)
                    statPill(value: "\(completed)", unit: "/\(total)", label: "Bölüm", icon: "checkmark.circle.fill", color: .white)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 28)
                    statPill(value: "\(completionPct)", unit: "%", label: "Tamamlandı", icon: "chart.bar.fill", color: .white.opacity(0.9))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.12))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statPill(value: String, unit: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
                HStack(spacing: 0) {
                    Text(value).font(.subheadline.weight(.black)).foregroundColor(.white)
                    Text(unit).font(.caption2.weight(.semibold)).foregroundColor(.white.opacity(0.7))
                }
            }
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
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
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(theme.cardStroke, lineWidth: 0.8))
        .shadow(color: theme.cardShadow.opacity(0.45), radius: 8, y: 4)
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
