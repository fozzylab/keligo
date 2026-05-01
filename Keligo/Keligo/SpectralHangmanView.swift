import SwiftUI

// MARK: - Shared Shape Helpers (also in KeligoDrawing.swift)

struct SpectralLine: Shape {
    let x1, y1, x2, y2: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: r.width * x1, y: r.height * y1))
        p.addLine(to: CGPoint(x: r.width * x2, y: r.height * y2))
        return p
    }
}

struct SpectralCircle: Shape {
    let cx, cy, radius: CGFloat
    func path(in r: CGRect) -> Path {
        let rd = r.width * radius
        return Path(ellipseIn: CGRect(
            x: r.width * cx - rd,
            y: r.height * cy - rd,
            width: rd * 2, height: rd * 2
        ))
    }
}

// MARK: - Spectral Hangman (Next-Gen Drawing)

struct SpectralHangmanView: View {
    let wrongGuesses: Int
    let maxWrong: Int
    let theme: AppTheme
    let isLastChance: Bool
    
    @State private var particleOrigins: [CGPoint] = []
    @State private var showParticles = false
    
    private func show(_ step: Int) -> Bool {
        wrongGuesses >= Int((Double(step) / 6.0) * Double(maxWrong) + 0.5)
    }
    
    var body: some View {
        ZStack {
            // Gallows — always visible, subtle depth
            gallows
            
            // Body parts with spectral materialize
            spectralPart(step: 1, shape: SpectralCircle(cx: 0.60, cy: 0.27, radius: 0.075))
            spectralPart(step: 2, shape: SpectralLine(x1: 0.60, y1: 0.35, x2: 0.60, y2: 0.63))
            spectralPart(step: 3, shape: SpectralLine(x1: 0.60, y1: 0.41, x2: 0.43, y2: 0.53))
            spectralPart(step: 4, shape: SpectralLine(x1: 0.60, y1: 0.41, x2: 0.77, y2: 0.53))
            spectralPart(step: 5, shape: SpectralLine(x1: 0.60, y1: 0.63, x2: 0.43, y2: 0.80))
            spectralPart(step: 6, shape: SpectralLine(x1: 0.60, y1: 0.63, x2: 0.77, y2: 0.80))
            
            // Last chance heartbeat pulse
            if isLastChance {
                Color.red.opacity(0.08)
                    .frame(width: 220, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .blur(radius: 30)
                    .breathe(intensity: 1.5, speed: 0.55)
            }
        }
        .frame(width: 190, height: 200)
        .onChange(of: wrongGuesses) { _, _ in
            withAnimation(CinematicSpring.snappy) {
                showParticles = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showParticles = false
            }
        }
    }
    
    private var gallows: some View {
        ZStack {
            SpectralLine(x1: 0.10, y1: 0.95, x2: 0.90, y2: 0.95)
                .stroke(theme.primaryText.opacity(0.4), lineWidth: 3)
            SpectralLine(x1: 0.25, y1: 0.95, x2: 0.25, y2: 0.05)
                .stroke(theme.primaryText.opacity(0.4), lineWidth: 3)
            SpectralLine(x1: 0.25, y1: 0.05, x2: 0.60, y2: 0.05)
                .stroke(theme.primaryText.opacity(0.4), lineWidth: 3)
            SpectralLine(x1: 0.60, y1: 0.05, x2: 0.60, y2: 0.18)
                .stroke(theme.primaryText.opacity(0.4), lineWidth: 3)
        }
    }
    
    @ViewBuilder
    private func spectralPart<S: Shape>(step: Int, shape: S) -> some View {
        if show(step) {
            ZStack {
                // Glow layer
                shape
                    .stroke(theme.wrong.opacity(0.3), lineWidth: 8)
                    .blur(radius: 6)
                
                // Main spectral stroke
                SpectralStroke(shape: shape, color: theme.primaryText, lineWidth: 3)
                    .ambientGlow(theme.primaryText, intensity: 0.4, radius: 12)
            }
        }
    }
}

// MARK: - Spectral Stroke (animated path drawing with glow)

struct SpectralStroke<S: Shape>: View {
    let shape: S
    let color: Color
    let lineWidth: CGFloat
    
    @State private var progress: CGFloat = 0
    
    var body: some View {
        shape
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55)) {
                    progress = 1
                }
            }
    }
}

// MARK: - Crystal Letter Tile (3D Flip + Glass)

struct CrystalLetterTile: View {
    let letter: Character
    let isRevealed: Bool
    let isSpace: Bool
    let theme: AppTheme
    let accent: Color
    let isBouncing: Bool
    let index: Int
    
    @EnvironmentObject var settings: SettingsViewModel
    
    private var flipAngle: Double { isRevealed ? 0 : 180 }
    private var letterFontSize: CGFloat { UIDevice.current.userInterfaceIdiom == .pad ? 34 : 26 }
    private var tileSize: CGFloat { UIDevice.current.userInterfaceIdiom == .pad ? 44 : 36 }
    
    var body: some View {
        Group {
            if isSpace {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20, height: 40)
            } else {
                ZStack {
                    // Back face (hidden state)
                    tileFace(content: hiddenContent, brightness: -0.05)
                        .rotation3DEffect(
                            .degrees(isRevealed ? -180 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .opacity(isRevealed ? 0 : 1)
                    
                    // Front face (revealed state)
                    tileFace(content: revealedContent, brightness: 0)
                        .rotation3DEffect(
                            .degrees(isRevealed ? 0 : 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .opacity(isRevealed ? 1 : 0)
                }
                .frame(width: tileSize, height: tileSize + 14)
                .scaleEffect(isBouncing ? 1.25 : 1.0)
                .animation(isRevealed ? CinematicSpring.flip.delay(Double(index) * 0.03) : .default, value: isRevealed)
                .animation(.spring(response: 0.2, dampingFraction: 0.4), value: isBouncing)
            }
        }
    }
    
    @ViewBuilder
    private func tileFace<Content: View>(content: Content, brightness: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: accent.opacity(0.15), radius: 6, y: 3)
            
            content
        }
    }
    
    @ViewBuilder
    private var hiddenContent: some View {
        VStack(spacing: 4) {
            Text(" ")
                .font(.system(size: letterFontSize, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryText.opacity(0.15))
            RoundedRectangle(cornerRadius: 2)
                .frame(width: tileSize - 8, height: 2.5)
                .foregroundColor(theme.primaryText.opacity(0.15))
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var revealedContent: some View {
        VStack(spacing: 4) {
            Text(String(letter))
                .font(.system(size: letterFontSize, weight: .black, design: .rounded))
                .foregroundColor(theme.primaryText)
                .ambientGlow(accent, intensity: 0.6, radius: 10)
            RoundedRectangle(cornerRadius: 2)
                .frame(width: tileSize - 8, height: 2.5)
                .foregroundColor(accent.opacity(0.85))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Floating Key Orb (Next-Gen Keyboard Key)

struct FloatingKeyOrb: View {
    let letter: Character
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    
    @EnvironmentObject var settings: SettingsViewModel
    @State private var isPressed = false
    @State private var tiltX: CGFloat = 0
    @State private var tiltY: CGFloat = 0
    @State private var ripplePhase: CGFloat = 0
    
    private var isGuessed: Bool { vm.guessedLetters.contains(letter) }
    private var isWrong: Bool { isGuessed && !vm.currentWord.contains(letter) }
    private var isCorrect: Bool { isGuessed && vm.currentWord.contains(letter) }
    private var isSpatial: Bool { settings.spatialUIEnabled && !settings.motionSafeMode }
    
    private var keySize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 44 : 36
    }
    
    var body: some View {
        Button {
            guard vm.gameState == .playing, !isGuessed else { return }
            vm.guess(letter)
            if settings.hapticEnabled {
                CinematicHaptics.shared.play(isCorrect ? .correct : .wrong)
            }
        } label: {
            ZStack {
                // Orb body
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(orbFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(orbStroke, lineWidth: isSpatial ? 1.0 : 0.75)
                    )
                    .shadow(color: orbShadowColor, radius: orbShadowRadius, x: 0, y: orbShadowY)
                
                // Inner sheen
                if isSpatial && !isGuessed {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Letter content
                if isWrong {
                    ZStack {
                        Text(String(letter))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(theme.wrong.opacity(0.35))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.top, 3).padding(.leading, 4)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(theme.wrong.opacity(0.65))
                    }
                } else {
                    Text(String(letter))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isCorrect ? .white : theme.primaryText)
                        .ambientGlow(isCorrect ? theme.correct : .clear, intensity: 0.5, radius: 8)
                }
                
                // (AI cold-zone highlight removed — caused visual inconsistency)
            }
            .frame(width: keySize, height: keySize + (isSpatial ? 4 : 0))
        }
        .disabled(isGuessed || vm.gameState != .playing)
        .buttonStyle(PlainButtonStyle())
        .rotation3DEffect(
            .degrees(isSpatial ? tiltX * 8 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(isSpatial ? tiltY * 6 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .scaleEffect(isPressed ? 0.88 : 1.0)
        .animation(CinematicSpring.snappy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isPressed = true
                    let center = CGPoint(x: keySize/2, y: keySize/2)
                    let dx = (value.location.x - center.x) / center.x
                    let dy = (value.location.y - center.y) / center.y
                    tiltX = dx
                    tiltY = dy
                }
                .onEnded { _ in
                    isPressed = false
                    tiltX = 0
                    tiltY = 0
                }
        )
    }
    
    private var orbFill: AnyShapeStyle {
        if isCorrect {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [theme.correct, theme.correct.opacity(0.72)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        if isWrong { return AnyShapeStyle(theme.wrong.opacity(0.12)) }
        
        if isSpatial {
            return AnyShapeStyle(theme.cardFill)
        }
        
        switch settings.keyboardStyle {
        case .glass:    return AnyShapeStyle(theme.cardMaterial)
        case .flat:     return AnyShapeStyle(theme.surface)
        case .minimal:  return AnyShapeStyle(Color.clear)
        case .colorful: return AnyShapeStyle(theme.accent.opacity(0.15))
        }
    }
    
    private var orbStroke: Color {
        if isCorrect { return Color.white.opacity(0.25) }
        if isWrong   { return theme.wrong.opacity(0.25) }
        if isSpatial { return theme.glassBorder.opacity(0.4) }
        switch settings.keyboardStyle {
        case .minimal:  return theme.accent.opacity(0.40)
        case .colorful: return theme.accent.opacity(0.30)
        default:        return Color.white.opacity(theme.isDark ? 0.10 : 0.45)
        }
    }
    
    private var orbShadowColor: Color {
        if isCorrect { return theme.correct.opacity(0.25) }
        if isWrong   { return .clear }
        return isSpatial ? theme.spatialShadow.opacity(0.3) : Color.black.opacity(theme.isDark ? 0.35 : 0.12)
    }
    
    private var orbShadowRadius: CGFloat {
        isCorrect ? 8 : (isSpatial ? 12 : 2)
    }
    
    private var orbShadowY: CGFloat {
        isCorrect ? 0 : (isSpatial ? 6 : 2)
    }
}
