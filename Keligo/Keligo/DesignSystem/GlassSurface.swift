import SwiftUI

// MARK: - Next-Gen Glass Surface (2026 Liquid Glass inspired)

struct GlassSurface: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double // 0.0 ... 1.0
    let borderGlow: Color?
    let innerGlow: Bool
    
    @EnvironmentObject var settings: SettingsViewModel
    
    func body(content: Content) -> some View {
        let theme  = settings.theme
        let isDark = theme.isDark
        // Always use theme.cardFill — adapts to system dark/light mode for every theme.
        // Classic: Color(.secondarySystemBackground) adapts automatically.
        // Other light themes (pastel, vintage): have their own explicit tints.
        // Dark themes: explicit dark surface colors.
        let baseFill: Color = theme.cardFill
        let strokeColor: Color = isDark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)

        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(baseFill)

                    // Çok hafif üst ışıltı (dark'ta neredeyse yok)
                    if isDark {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.02 * intensity),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }

                    // Accent iç kenarlık (dark'ta çok az parlayan)
                    if innerGlow {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        (borderGlow ?? Color.white).opacity(isDark ? 0.08 * intensity : 0.18 * intensity),
                                        (borderGlow ?? Color.white).opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: isDark ? 0.5 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassSurface(
        cornerRadius: CGFloat = 20,
        intensity: Double = 1.0,
        borderGlow: Color? = nil,
        innerGlow: Bool = true
    ) -> some View {
        modifier(GlassSurface(
            cornerRadius: cornerRadius,
            intensity: intensity,
            borderGlow: borderGlow,
            innerGlow: innerGlow
        ))
    }
}

// MARK: - Floating Glass Card

struct FloatingGlassCard<Content: View>: View {
    let depth: CGFloat
    let cornerRadius: CGFloat
    let content: Content
    
    init(depth: CGFloat = 12, cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .glassSurface(cornerRadius: cornerRadius, intensity: 1.0, innerGlow: true)
            .spatialDepth(depth, perspective: 0.25)
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    let accent: Color
    let depth: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .glassSurface(cornerRadius: 16, intensity: configuration.isPressed ? 0.6 : 1.0, borderGlow: accent, innerGlow: true)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .ambientGlow(accent, intensity: configuration.isPressed ? 0.2 : 0.5, radius: 16)
            .animation(CinematicSpring.snappy, value: configuration.isPressed)
    }
}

// MARK: - Floating Orb (for keys, dots, badges)

struct FloatingOrb<Content: View>: View {
    let size: CGFloat
    let depth: CGFloat
    let glowColor: Color
    let content: Content
    
    @EnvironmentObject var settings: SettingsViewModel
    
    init(size: CGFloat, depth: CGFloat = 6, glowColor: Color = .white, @ViewBuilder content: () -> Content) {
        self.size = size
        self.depth = depth
        self.glowColor = glowColor
        self.content = content()
    }
    
    var body: some View {
        let theme = settings.theme
        let isDark = theme.isDark
        content
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(theme.cardFill)
                    .overlay(
                        Circle()
                            .stroke(glowColor.opacity(isDark ? 0.12 : 0.25), lineWidth: 1)
                    )
                    .shadow(color: isDark ? .black.opacity(0.45) : glowColor.opacity(0.20), radius: 8, x: 0, y: 4)
            )
            .clipShape(Circle())
            .spatialDepth(depth, perspective: 0.4)
    }
}
