import SwiftUI

// MARK: - FozzyLabs Publisher Intro
// Oyun açılışında ~1.2 saniye gösterilir, ardından SplashView devreye girer.

struct FozzyLabsIntroView: View {
    var onFinish: () -> Void

    // Animation states
    @State private var hexScale: CGFloat    = 0.5
    @State private var hexOpacity: Double   = 0
    @State private var letterOpacity: Double = 0
    @State private var orbitOpacity: Double  = 0
    @State private var orbitRotation: Double = -15
    @State private var sparkScale: CGFloat   = 0
    @State private var labelOpacity: Double  = 0
    @State private var fadeOut: Double       = 1

    var body: some View {
        ZStack {
            // ── Background: deep space ──
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.10),
                    Color(red: 0.07, green: 0.03, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radial glow behind hex
            RadialGradient(
                colors: [
                    Color(red: 0.48, green: 0.23, blue: 0.93).opacity(0.30),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .ignoresSafeArea()
            .scaleEffect(hexScale)

            VStack(spacing: 28) {
                Spacer()

                // ── Logo mark ──
                ZStack {
                    // Orbit ring 1
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.48, green: 0.23, blue: 0.93).opacity(0.5),
                                    Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 210, height: 96)
                        .rotationEffect(.degrees(orbitRotation))
                        .opacity(orbitOpacity)

                    // Orbit ring 2
                    Ellipse()
                        .stroke(
                            Color(red: 0.02, green: 0.71, blue: 0.84).opacity(0.25),
                            lineWidth: 1
                        )
                        .frame(width: 185, height: 82)
                        .rotationEffect(.degrees(orbitRotation + 70))
                        .opacity(orbitOpacity)

                    // Electron dot 1
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.02, green: 0.71, blue: 0.84), Color(red: 0.13, green: 0.83, blue: 0.93)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(red: 0.02, green: 0.71, blue: 0.84).opacity(0.8), radius: 8)
                        .offset(x: 98, y: -32)
                        .opacity(orbitOpacity)

                    // Electron dot 2
                    Circle()
                        .fill(Color(red: 0.96, green: 0.62, blue: 0.07))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.07).opacity(0.8), radius: 6)
                        .offset(x: -88, y: 38)
                        .opacity(orbitOpacity)

                    // ── Hexagon ──
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.48, green: 0.23, blue: 0.93).opacity(0.22),
                                    Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            HexagonShape()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.48, green: 0.23, blue: 0.93),
                                            Color(red: 0.31, green: 0.27, blue: 0.90)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(color: Color(red: 0.48, green: 0.23, blue: 0.93).opacity(0.5), radius: 20)
                        .scaleEffect(hexScale)
                        .opacity(hexOpacity)

                    // ── FL Lettermark ──
                    HStack(spacing: 0) {
                        // F
                        FLetterMark()
                            .fill(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.77, green: 0.71, blue: 1.0)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 34, height: 50)

                        // L
                        LLetterMark()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.02, green: 0.71, blue: 0.84), Color(red: 0.13, green: 0.83, blue: 0.93)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 26, height: 50)
                            .shadow(color: Color(red: 0.02, green: 0.71, blue: 0.84).opacity(0.6), radius: 8)
                    }
                    .opacity(letterOpacity)

                    // ── Spark / lightning ──
                    SparkShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.96, green: 0.62, blue: 0.07), Color(red: 0.99, green: 0.83, blue: 0.25)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 22)
                        .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.07).opacity(0.9), radius: 8)
                        .offset(x: 62, y: -58)
                        .scaleEffect(sparkScale)
                        .opacity(sparkScale)
                }

                // ── Labels ──
                VStack(spacing: 4) {
                    Text("FozzyLabs")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.77, green: 0.71, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("A FozzyLabs Game")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                        .kerning(1.5)
                }
                .opacity(labelOpacity)

                Spacer()
            }
        }
        .opacity(fadeOut)
        .onAppear { runAnimation() }
    }

    // MARK: - Animation sequence
    private func runAnimation() {
        // 1. Hex scales in
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.05)) {
            hexScale   = 1.0
            hexOpacity = 1.0
        }
        // 2. Orbits rotate in
        withAnimation(.easeOut(duration: 0.55).delay(0.15)) {
            orbitOpacity  = 1.0
            orbitRotation = -20
        }
        // 3. Letters appear
        withAnimation(.easeOut(duration: 0.35).delay(0.25)) {
            letterOpacity = 1.0
        }
        // 4. Spark pops
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.35)) {
            sparkScale = 1.0
        }
        // 5. Label fades in
        withAnimation(.easeOut(duration: 0.3).delay(0.40)) {
            labelOpacity = 1.0
        }
        // 6. Hold then fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.35)) { fadeOut = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onFinish() }
        }
    }
}

// MARK: - Custom Shapes

/// Regular hexagon (flat-top)
private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}

/// Stylised "F" lettermark
private struct FLetterMark: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let bar: CGFloat = w * 0.30   // vertical bar width
        let cap: CGFloat = h * 0.22   // cap height
        let mid: CGFloat = h * 0.20   // mid bar height
        let r:   CGFloat = 4          // corner radius
        var p = Path()
        // Vertical bar
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: bar, height: h), cornerSize: CGSize(width: r, height: r))
        // Top horizontal bar
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: w, height: cap), cornerSize: CGSize(width: r, height: r))
        // Mid horizontal bar
        p.addRoundedRect(in: CGRect(x: 0, y: h * 0.40, width: w * 0.78, height: mid), cornerSize: CGSize(width: r, height: r))
        return p
    }
}

/// Stylised "L" lettermark
private struct LLetterMark: Shape {
    func path(in rect: CGRect) -> Path {
        let w  = rect.width
        let h  = rect.height
        let bar: CGFloat = w * 0.38
        let foot: CGFloat = h * 0.22
        let r:   CGFloat = 3
        var p = Path()
        // Vertical bar
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: bar, height: h), cornerSize: CGSize(width: r, height: r))
        // Horizontal foot
        p.addRoundedRect(in: CGRect(x: 0, y: h - foot, width: w, height: foot), cornerSize: CGSize(width: r, height: r))
        return p
    }
}

/// Small lightning bolt spark
private struct SparkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.65, y: 0))
        p.addLine(to: CGPoint(x: w * 0.20, y: h * 0.48))
        p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.48))
        p.addLine(to: CGPoint(x: w * 0.35, y: h))
        p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.52))
        p.closeSubpath()
        return p
    }
}

// MARK: - Preview
#Preview {
    FozzyLabsIntroView { }
}
