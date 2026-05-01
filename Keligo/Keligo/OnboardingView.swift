import SwiftUI

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let isSystemIcon: Bool
}

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var notifGranted: Bool? = nil   // nil=not asked, true=granted, false=denied
    @AppStorage("preferredMode") var preferredMode = "daily"

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "🔡",
            title: "Kelimeyi Bul",
            description: "Gizli kelimeyi bulmaya çalış. Her doğru harf seni zafere yaklaştırır!",
            gradient: [Color(red: 0.20, green: 0.45, blue: 1.00), Color(red: 0.45, green: 0.75, blue: 1.00)],
            isSystemIcon: false
        ),
        OnboardingPage(
            icon: "keyboard.fill",
            title: "Harf Seç",
            description: "Türkçe klavyeden harflere dokun. Yanlış tahminler adamı tamamlar!",
            gradient: [Color(red: 1.00, green: 0.45, blue: 0.10), Color(red: 1.00, green: 0.75, blue: 0.15)],
            isSystemIcon: true
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            title: "İpucu Kullan",
            description: "Sıkıştın mı? İpucu butonuyla gizli bir harf açabilirsin. Dikkatli kullan!",
            gradient: [Color(red: 0.65, green: 0.15, blue: 1.00), Color(red: 1.00, green: 0.38, blue: 0.82)],
            isSystemIcon: true
        ),
        OnboardingPage(
            icon: "🏆",
            title: "Hazır mısın?",
            description: "Günlük kelimeler, bölüm modu, hız modu ve kategorilerle oyna. İyi eğlenceler!",
            gradient: [Color(red: 0.10, green: 0.70, blue: 0.35), Color(red: 0.20, green: 0.95, blue: 0.50)],
            isSystemIcon: false
        ),
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: currentPage == 3
                    ? [Color(red: 0.20, green: 0.55, blue: 0.90), Color(red: 0.55, green: 0.25, blue: 0.95)]
                    : pages[currentPage < 3 ? currentPage : currentPage - 1].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Dark overlay for readability
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 4 {
                        Button("Geç") { onComplete() }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<5, id: \.self) { idx in
                        Group {
                            if idx == 3 {
                                modeSelectionPage
                            } else {
                                let pageIdx = idx < 3 ? idx : idx - 1
                                pageView(pages[pageIdx])
                            }
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                Spacer()

                // Pagination dots
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i == currentPage ? 1.0 : 0.35))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 28)

                // Action button(s)
                VStack(spacing: 10) {
                    // Last page: notification permission button (shown before "Başla")
                    if currentPage == 4, notifGranted == nil {
                        Button {
                            NotificationManager.shared.requestPermission { granted in
                                notifGranted = granted
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.subheadline.weight(.bold))
                                Text("Günlük Hatırlatıcı Aç")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.22))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 28)
                    } else if currentPage == 4, let granted = notifGranted {
                        // Status badge after permission decision
                        HStack(spacing: 6) {
                            Image(systemName: granted ? "bell.fill" : "bell.slash.fill")
                            Text(granted ? "Bildirimler açık ✓" : "Bildirimler kapalı")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white.opacity(0.80))
                        .padding(.vertical, 8)
                    }

                    // Main CTA
                    Button {
                        if currentPage < 4 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < 4 ? "İleri" : "Oynamaya Başla!")
                                .font(.headline)
                            Image(systemName: currentPage < 4 ? "arrow.right" : "play.fill")
                                .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundColor(
                            currentPage == 3
                                ? Color(red: 0.20, green: 0.55, blue: 0.90)
                                : (pages[currentPage < 3 ? currentPage : currentPage - 1].gradient.first ?? .blue)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 52)
                .animation(.easeInOut(duration: 0.25), value: currentPage)
                .animation(.easeInOut(duration: 0.25), value: notifGranted == nil)
            }
        }
    }

    private struct OnboardingMode {
        let id: String; let emoji: String; let title: String; let subtitle: String; let colors: [Color]
    }

    private let onboardingModes: [OnboardingMode] = [
        OnboardingMode(id: "daily",    emoji: "📅", title: "Günlük Kelime",   subtitle: "Her gün yeni bir kelime",          colors: [Color(red: 1.0, green: 0.45, blue: 0.10), Color(red: 1.0, green: 0.75, blue: 0.15)]),
        OnboardingMode(id: "infinite", emoji: "∞",  title: "Sonsuz Mod",      subtitle: "Kategori seç, sınırsız oyna",      colors: [Color(red: 0.20, green: 0.45, blue: 1.0), Color(red: 0.45, green: 0.75, blue: 1.0)]),
        OnboardingMode(id: "chapter",  emoji: "📖", title: "Bölüm Modu",      subtitle: "Aşamalar geç, yıldız kazan",       colors: [Color(red: 0.65, green: 0.15, blue: 1.0), Color(red: 1.0, green: 0.38, blue: 0.82)]),
        OnboardingMode(id: "speed",    emoji: "⚡️", title: "Hız Modu",         subtitle: "60 saniyede kaç kelime?",          colors: [Color(red: 1.0, green: 0.18, blue: 0.18), Color(red: 1.0, green: 0.58, blue: 0.10)]),
        OnboardingMode(id: "kids",     emoji: "🧒", title: "Çocuk Modu",       subtitle: "Kolay kelimeler, eğlenceli oyun",  colors: [Color(red: 0.10, green: 0.75, blue: 0.40), Color(red: 0.20, green: 0.95, blue: 0.55)]),
    ]

    private var modeSelectionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎮")
                .font(.system(size: 70))

            VStack(spacing: 8) {
                Text("Nasıl oynamak istersin?")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("İstediğinde ayarlardan değiştirebilirsin")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // Mode cards grid
            VStack(spacing: 10) {
                ForEach(onboardingModes, id: \.id) { mode in
                    Button { preferredMode = mode.id } label: {
                        HStack(spacing: 14) {
                            Text(mode.emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(colors: mode.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Spacer()
                            if preferredMode == mode.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(
                            preferredMode == mode.id
                                ? Color.white.opacity(0.20)
                                : Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(preferredMode == mode.id ? Color.white.opacity(0.5) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            // Icon with glow
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                if page.isSystemIcon {
                    Image(systemName: page.icon)
                        .font(.system(size: 80, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 8)
                } else {
                    Text(page.icon)
                        .font(.system(size: 90))
                        .shadow(color: .black.opacity(0.2), radius: 8)
                }
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }

            Spacer()
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
