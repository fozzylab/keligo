import SwiftUI

// MARK: - Next-Gen Glass Surface (2026 Liquid Glass inspired)

struct GlassSurface: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double // 0.0 ... 1.0
    let borderGlow: Color?
    let innerGlow: Bool
    
    @EnvironmentObject var settings: SettingsViewModel
    
    func body(content: Content) -> some View {
        let enabled = settings.spatialUIEnabled && !settings.motionSafeMode
        let mat = settings.theme.isDark ? Material.ultraThinMaterial : Material.regularMaterial
        
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(mat)
                    
                    if enabled {
                        // Inner sheen
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18 * intensity),
                                        Color.white.opacity(0.04 * intensity),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        if innerGlow {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            (borderGlow ?? Color.white).opacity(0.35 * intensity),
                                            (borderGlow ?? Color.white).opacity(0.05 * intensity)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        enabled
                            ? Color.white.opacity(0.10 * intensity)
                            : Color.white.opacity(0.06),
                        lineWidth: 0.5
                    )
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
    
    init(size: CGFloat, depth: CGFloat = 6, glowColor: Color = .white, @ViewBuilder content: () -> Content) {
        self.size = size
        self.depth = depth
        self.glowColor = glowColor
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(glowColor.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: glowColor.opacity(0.20), radius: 8, x: 0, y: 4)
            )
            .clipShape(Circle())
            .spatialDepth(depth, perspective: 0.4)
    }
}
