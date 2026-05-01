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

                // Chapter overview stats
                let completed  = manager.chapters.filter { (manager.stars[$0.id] ?? 0) > 0 }.count
                let totalStars = manager.chapters.reduce(0) { $0 + (manager.stars[$1.id] ?? 0) }
                let maxStars   = manager.chapters.count * 3

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(completed)/\(manager.chapters.count)")
                            .font(.title3.weight(.black))
                            .foregroundColor(t.primaryText)
                        Text("Tamamlanan")
                            .font(.caption2)
                            .foregroundColor(t.secondaryText)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(t.secondaryText.opacity(0.2))
                        .frame(width: 1, height: 36)

                    VStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Text("\(totalStars)")
                                .font(.title3.weight(.black))
                                .foregroundColor(.yellow)
                            Text("/ \(maxStars)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.secondaryText)
                        }
                        Text("Toplam Yıldız")
                            .font(.caption2)
                            .foregroundColor(t.secondaryText)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(t.secondaryText.opacity(0.2))
                        .frame(width: 1, height: 36)

                    VStack(spacing: 4) {
                        Text(completed == manager.chapters.count ? "✅" : "🔓")
                            .font(.title3)
                        Text(completed == manager.chapters.count ? "Tümü Bitti!" : "Devam Et")
                            .font(.caption2)
                            .foregroundColor(t.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24).padding(.vertical, 14)
                .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
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
