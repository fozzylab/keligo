import SwiftUI
import Combine

// MARK: - Ambient Mood

enum AmbientMood: String, CaseIterable {
    case calm, focused, urgent, celebratory, mysterious, zen
    
    var meshColors: [Color] {
        switch self {
        case .calm:
            return [.teal.opacity(0.15), .blue.opacity(0.08), .black.opacity(0.5),
                    .mint.opacity(0.08), .teal.opacity(0.05), .blue.opacity(0.10),
                    .black.opacity(0.5), .mint.opacity(0.05), .teal.opacity(0.08)]
        case .focused:
            return [.indigo.opacity(0.18), .purple.opacity(0.10), .black.opacity(0.5),
                    .blue.opacity(0.10), .indigo.opacity(0.08), .purple.opacity(0.12),
                    .black.opacity(0.5), .blue.opacity(0.08), .indigo.opacity(0.10)]
        case .urgent:
            return [.red.opacity(0.20), .orange.opacity(0.12), .black.opacity(0.5),
                    .orange.opacity(0.10), .red.opacity(0.08), .pink.opacity(0.15),
                    .black.opacity(0.5), .orange.opacity(0.08), .red.opacity(0.12)]
        case .celebratory:
            return [.yellow.opacity(0.18), .orange.opacity(0.10), .black.opacity(0.4),
                    .green.opacity(0.10), .yellow.opacity(0.08), .cyan.opacity(0.12),
                    .black.opacity(0.4), .green.opacity(0.08), .yellow.opacity(0.10)]
        case .mysterious:
            return [.purple.opacity(0.18), .indigo.opacity(0.10), .black.opacity(0.5),
                    .pink.opacity(0.08), .purple.opacity(0.05), .indigo.opacity(0.12),
                    .black.opacity(0.5), .pink.opacity(0.05), .purple.opacity(0.10)]
        case .zen:
            return [.green.opacity(0.12), .teal.opacity(0.08), .black.opacity(0.4),
                    .mint.opacity(0.08), .green.opacity(0.05), .teal.opacity(0.10),
                    .black.opacity(0.4), .mint.opacity(0.05), .green.opacity(0.08)]
        }
    }
    
    var baseOpacity: Double {
        switch self {
        case .calm: return 0.30
        case .focused: return 0.32
        case .urgent: return 0.38
        case .celebratory: return 0.35
        case .mysterious: return 0.32
        case .zen: return 0.28
        }
    }
}

// MARK: - Generative Ambient Background (Optimized)

struct GenerativeBackground: View {
    let mood: AmbientMood
    let intensity: Double
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Animated MeshGradient (iOS 18+) — single TimelineView drives everything
                if #available(iOS 18.0, *) {
                    MeshGradient(
                        width: 3, height: 3,
                        points: animatedPoints(phase: phase),
                        colors: mood.meshColors
                    )
                    .ignoresSafeArea()
                    .opacity(intensity * mood.baseOpacity)
                } else {
                    LinearGradient(
                        colors: Array(mood.meshColors.prefix(3)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    .opacity(intensity * mood.baseOpacity * 0.6)
                }
                
                // Layer 2: Soft radial pulse (GPU-friendly, no Canvas)
                RadialGradient(
                    colors: [
                        pulseColor.opacity(0.06 * intensity),
                        pulseColor.opacity(0.0)
                    ],
                    center: .init(x: 0.5 + 0.2 * cos(phase), y: 0.5 + 0.2 * sin(phase)),
                    startRadius: 50,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                // Layer 3: Vignette for depth (lighter)
                RadialGradient(
                    colors: [.clear, .black.opacity(0.28 * intensity)],
                    center: .center,
                    startRadius: geo.size.width * 0.35,
                    endRadius: geo.size.width * 0.95
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Lightweight phase animation — 12 Hz, no separate Timer
            let target = DisplayLinkTarget { [self] in phase += 0.003 }
            let displayLink = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick(_:)))
            displayLink.preferredFramesPerSecond = 12
            displayLink.add(to: .main, forMode: .common)
        }
    }
    
    private var pulseColor: Color {
        switch mood {
        case .calm: return .teal
        case .focused: return .indigo
        case .urgent: return .red
        case .celebratory: return .yellow
        case .mysterious: return .purple
        case .zen: return .green
        }
    }
    
    @available(iOS 18.0, *)
    private func animatedPoints(phase: CGFloat) -> [SIMD2<Float>] {
        let t = Float(sin(phase))
        let c = Float(cos(phase * 0.7))
        
        return [
            .init(x: 0.0, y: 0.0),
            .init(x: 0.5 + t * 0.06, y: 0.0),
            .init(x: 1.0, y: 0.0),
            .init(x: 0.0, y: 0.5 + c * 0.04),
            .init(x: 0.5 + c * 0.04, y: 0.5 + t * 0.04),
            .init(x: 1.0, y: 0.5 - c * 0.04),
            .init(x: 0.0, y: 1.0),
            .init(x: 0.5 - t * 0.06, y: 1.0),
            .init(x: 1.0, y: 1.0)
        ]
    }
}

// MARK: - Lightweight Display Link Target

final class DisplayLinkTarget: NSObject {
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func tick(_ link: CADisplayLink) { action() }
}

// MARK: - Reactive Game State Background

struct ReactiveGameBackground: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var settings: SettingsViewModel
    
    private var mood: AmbientMood {
        if vm.gameState == .won { return .celebratory }
        if vm.gameState == .lost { return .mysterious }
        if vm.wrongGuesses == vm.maxWrongGuesses - 1 { return .urgent }
        return .focused
    }
    
    var body: some View {
        Group {
            if settings.spatialUIEnabled {
                GenerativeBackground(
                    mood: mood,
                    intensity: settings.ambientIntensity
                )
            } else {
                settings.theme.background.ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 1.2), value: mood)
        .animation(.easeInOut(duration: 0.8), value: settings.ambientIntensity)
    }
}
