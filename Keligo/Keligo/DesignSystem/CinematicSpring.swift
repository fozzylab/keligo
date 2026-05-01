import SwiftUI

// MARK: - 2026 Cinematic Animation Constants

enum CinematicSpring {
    static let snappy   = Animation.spring(response: 0.35, dampingFraction: 0.82)
    static let bouncy   = Animation.spring(response: 0.50, dampingFraction: 0.65)
    static let gentle   = Animation.spring(response: 0.70, dampingFraction: 0.80)
    static let dramatic = Animation.spring(response: 0.85, dampingFraction: 0.55)
    static let elastic  = Animation.interpolatingSpring(stiffness: 180, damping: 15)
    
    static let flip     = Animation.spring(response: 0.55, dampingFraction: 0.60)
    static let levitate = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let breathe  = Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true)
    static let heartbeat = Animation.easeInOut(duration: 0.55).repeatForever(autoreverses: true)
}

enum CinematicDuration {
    static let instant: Double = 0.12
    static let fast: Double    = 0.22
    static let normal: Double  = 0.35
    static let slow: Double    = 0.60
    static let cinematic: Double = 1.10
}

// MARK: - Haptic Patterns (2026 Rich Haptics)

import CoreHaptics

final class CinematicHaptics {
    static let shared = CinematicHaptics()
    private var engine: CHHapticEngine?
    
    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { }
    }
    
    func play(_ type: HapticType) {
        guard let engine = engine else {
            fallback(type)
            return
        }
        do {
            let pattern = try CHHapticPattern(events: type.events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallback(type)
        }
    }
    
    private func fallback(_ type: HapticType) {
        switch type {
        case .keyPress:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .correct:    UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .wrong:      UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .win:        UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .loss:       UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .lastChance: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .hint:       UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .tick:       UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

enum HapticType {
    case keyPress, correct, wrong, win, loss, lastChance, hint, tick
    
    var events: [CHHapticEvent] {
        switch self {
        case .keyPress:
            return [CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.60)
            ], relativeTime: 0)]
        case .correct:
            return [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.50),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.40)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.80),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.70)
                ], relativeTime: 0.08)
            ]
        case .wrong:
            return [CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.70),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.90)
            ], relativeTime: 0, duration: 0.18)]
        case .win:
            return (0..<5).map { i in
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.4 + Double(i) * 0.15)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.60)
                ], relativeTime: Double(i) * 0.06)
            }
        case .loss:
            return [CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.60),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.30)
            ], relativeTime: 0, duration: 0.45)]
        case .lastChance:
            return [CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0, duration: 0.25)]
        case .hint:
            return [CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.50)
            ], relativeTime: 0)]
        case .tick:
            return [CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.20),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.80)
            ], relativeTime: 0)]
        }
    }
}
