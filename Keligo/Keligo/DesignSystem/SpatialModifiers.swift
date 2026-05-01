import SwiftUI
import CoreMotion

// MARK: - Spatial Depth Modifier

struct SpatialDepthModifier: ViewModifier {
    let depth: CGFloat
    let perspective: CGFloat
    @State private var tiltX: CGFloat = 0
    @State private var tiltY: CGFloat = 0
    let motionEnabled: Bool
    
    @EnvironmentObject var settings: SettingsViewModel
    
    func body(content: Content) -> some View {
        let enabled = settings.spatialUIEnabled && !settings.motionSafeMode && !UIAccessibility.isReduceMotionEnabled
        
        content
            .rotation3DEffect(
                .degrees(enabled ? tiltX * 4 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(enabled ? tiltY * 3 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: perspective
            )
            .shadow(
                color: enabled
                    ? Color.black.opacity(0.25 + Double(depth) * 0.08)
                    : .clear,
                radius: enabled ? depth * 0.6 : 0,
                x: enabled ? -tiltX * depth * 0.3 : 0,
                y: enabled ? tiltY * depth * 0.3 + depth * 0.15 : 0
            )
            .onAppear {
                guard enabled, motionEnabled else { return }
                startMotionTracking()
            }
    }
    
    private func startMotionTracking() {
        // Lightweight gyro-driven tilt for floating feel
        // In a full app you'd use CMMotionManager; here we simulate subtle idle drift
        withAnimation(CinematicSpring.breathe) {
            tiltX = 1.5
            tiltY = 1.0
        }
    }
}

extension View {
    func spatialDepth(_ depth: CGFloat, perspective: CGFloat = 0.3, motion: Bool = true) -> some View {
        modifier(SpatialDepthModifier(depth: depth, perspective: perspective, motionEnabled: motion))
    }
}

// MARK: - Parallax Scroll Modifier

struct ParallaxScrollModifier: ViewModifier {
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            let y = geo.frame(in: .global).minY
            content
                .offset(y: y * -intensity)
        }
    }
}

extension View {
    func parallax(intensity: CGFloat = 0.15) -> some View {
        modifier(ParallaxScrollModifier(intensity: intensity))
    }
}

// MARK: - Magnetic Press Modifier

struct MagneticPressModifier: ViewModifier {
    @State private var isPressed = false
    @State private var pressLocation: CGPoint = .zero
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .offset(
                x: isPressed ? (pressLocation.x - 0.5) * -4 : 0,
                y: isPressed ? (pressLocation.y - 0.5) * -4 : 0
            )
            .animation(CinematicSpring.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        pressLocation = CGPoint(
                            x: value.location.x / value.startLocation.x,
                            y: value.location.y / value.startLocation.y
                        )
                        isPressed = true
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func magneticPress(scale: CGFloat = 0.94) -> some View {
        modifier(MagneticPressModifier(scale: scale))
    }
}

// MARK: - Ambient Glow Modifier

struct AmbientGlowModifier: ViewModifier {
    let color: Color
    let intensity: Double
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.45), radius: radius, x: 0, y: radius * 0.2)
    }
}

extension View {
    func ambientGlow(_ color: Color, intensity: Double = 0.5, radius: CGFloat = 20) -> some View {
        modifier(AmbientGlowModifier(color: color, intensity: intensity, radius: radius))
    }
}

// MARK: - Z-Layer Container

struct ZLayer<Content: View>: View {
    let depth: CGFloat
    let content: Content
    
    init(depth: CGFloat, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.content = content()
    }
    
    var body: some View {
        content
            .spatialDepth(depth)
    }
}
