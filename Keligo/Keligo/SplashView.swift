import SwiftUI

// MARK: - Keligo Splash Screen
// "KELIGO" harfleri oyun mekaniğini yansıtır:
// önce boş kutular → harfler teker teker açılır → wordmark belirir

struct SplashView: View {
    var onFinish: () -> Void

    private let letters: [Character] = ["K", "E", "L", "İ", "G", "O"]

    @State private var revealedCount  = 0       // kaç harf açıldı
    @State private var tileScales     = Array(repeating: CGFloat(0.6), count: 6)
    @State private var tileOpacities  = Array(repeating: Double(0), count: 6)
    @State private var glowOpacity    = 0.0
    @State private var taglineOpacity = 0.0
    @State private var taglineOffset  = CGFloat(8)
    @State private var fadeOut        = 1.0

    // Arka plan FozzyLabs ile aynı renk — kesintisiz geçiş
    private let bgTop    = Color(red: 0.04, green: 0.06, blue: 0.10)
    private let bgBottom = Color(red: 0.07, green: 0.03, blue: 0.16)

    var body: some View {
        ZStack {
            // ── Arka plan ──
            LinearGradient(colors: [bgTop, bgBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Merkezi parıltı
            RadialGradient(
                colors: [Color(red: 0.30, green: 0.55, blue: 1.00).opacity(0.22), .clear],
                center: .center, startRadius: 0, endRadius: 240
            )
            .ignoresSafeArea()
            .opacity(glowOpacity)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: glowOpacity)

            VStack(spacing: 0) {
                Spacer()

                // ── Harf kutuları ──
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        LetterTile(
                            letter: i < revealedCount ? letters[i] : nil,
                            scale: tileScales[i],
                            opacity: tileOpacities[i]
                        )
                    }
                }
                .padding(.bottom, 32)

                // ── Tagline ──
                Text("Kelime Tahmin Oyunu")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.50))
                    .opacity(taglineOpacity)
                    .offset(y: taglineOffset)

                Spacer()

                // ── Bouncing dots ──
                BouncingDots()
                    .opacity(taglineOpacity)
                    .padding(.bottom, 56)
            }
        }
        .opacity(fadeOut)
        .onAppear { runAnimation() }
    }

    // MARK: - Sequenced animation

    private func runAnimation() {
        // 1. Tüm kutular birden belirir (boş)
        for i in 0..<6 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)
                            .delay(Double(i) * 0.04)) {
                tileScales[i]   = 1.0
                tileOpacities[i] = 1.0
            }
        }

        // 2. Glow aç
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            glowOpacity = 1.0
        }

        // 3. Harfler teker teker açılır (oyun mekaniği hissi)
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30 + Double(i) * 0.14) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    revealedCount = i + 1
                    // Açılan kutunun hafif sıçraması
                    tileScales[i] = 1.12
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        tileScales[i] = 1.0
                    }
                }
            }
        }

        // 4. Wordmark + tagline
        let allRevealed = 0.30 + 6 * 0.14 + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + allRevealed) {
            withAnimation(.easeOut(duration: 0.45)) {
                taglineOpacity = 1.0
                taglineOffset  = 0
            }
        }

        // 5. Fade out
        let holdUntil = allRevealed + 0.85
        DispatchQueue.main.asyncAfter(deadline: .now() + holdUntil) {
            withAnimation(.easeInOut(duration: 0.4)) { fadeOut = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onFinish() }
        }
    }
}

// MARK: - Letter Tile

private struct LetterTile: View {
    let letter: Character?
    let scale: CGFloat
    let opacity: Double

    var body: some View {
        ZStack {
            // Kutu arka planı
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    letter != nil
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.31, green: 0.56, blue: 0.97),
                                     Color(red: 0.00, green: 0.83, blue: 1.00)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(red: 0.12, green: 0.23, blue: 0.43))
                )
                .frame(width: 48, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            letter != nil
                                ? Color.white.opacity(0.25)
                                : Color(red: 0.25, green: 0.45, blue: 0.75).opacity(0.4),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: letter != nil
                        ? Color(red: 0.31, green: 0.56, blue: 0.97).opacity(0.55)
                        : .clear,
                    radius: 12, y: 4
                )

            if let ch = letter {
                Text(String(ch))
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: letter != nil)
    }
}

// MARK: - Bouncing Dots

private struct BouncingDots: View {
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.40))
                    .frame(width: 7, height: 7)
                    .offset(y: bounce ? -5 : 0)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: bounce
                    )
            }
        }
        .onAppear { bounce = true }
    }
}

// MARK: - Preview
#Preview {
    SplashView { }
}
