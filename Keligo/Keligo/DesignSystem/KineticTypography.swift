import SwiftUI

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
            .onAppear { animateTo(value) }
            .onChange(of: value) { _, new in animateTo(new) }
    }
    
    private func animateTo(_ target: Int) {
        let diff = target - displayValue
        let steps = min(abs(diff), 20)
        guard steps > 0 else { return }
        let increment = diff / steps
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.025) {
                displayValue += increment
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.025) {
            displayValue = target
        }
    }
}

// MARK: - Letter-by-Letter Reveal

struct RevealingText: View {
    let text: String
    let font: Font
    let color: Color
    let delayPerLetter: Double
    
    @State private var revealedCount: Int = 0
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(text.enumerated()), id: \.offset) { idx, char in
                Text(String(char))
                    .font(font)
                    .foregroundColor(color)
                    .opacity(idx < revealedCount ? 1 : 0)
                    .offset(y: idx < revealedCount ? 0 : 12)
                    .animation(
                        CinematicSpring.snappy.delay(Double(idx) * delayPerLetter),
                        value: revealedCount
                    )
            }
        }
        .onAppear {
            revealedCount = 0
            for i in 0...text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delayPerLetter) {
                    revealedCount = i
                }
            }
        }
    }
}

// MARK: - Scramble Text Effect

struct ScrambleText: View {
    let finalText: String
    let font: Font
    let color: Color
    let duration: Double
    
    @State private var displayText: String = ""
    private let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    var body: some View {
        Text(displayText)
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
            .onAppear { scramble() }
    }
    
    private func scramble() {
        let total = finalText.count
        let steps = Int(duration * 30)
        let revealIndex = steps / total
        
        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) / 30.0) {
                let revealUpTo = step / revealIndex
                var result = ""
                for (idx, char) in finalText.enumerated() {
                    if idx < revealUpTo {
                        result.append(char)
                    } else if char == " " {
                        result.append(" ")
                    } else {
                        result.append(chars.randomElement() ?? "?")
                    }
                }
                displayText = result
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayText = finalText
        }
    }
}

// MARK: - Breathe Scale (idle animation)

struct BreatheModifier: ViewModifier {
    let intensity: Double
    let speed: Double
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + Double(phase) * intensity * 0.02)
            .opacity(1.0 - Double(phase) * intensity * 0.03)
            .onAppear {
                withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func breathe(intensity: Double = 1.0, speed: Double = 3.5) -> some View {
        modifier(BreatheModifier(intensity: intensity, speed: speed))
    }
}

// MARK: - Glitch Text (for urgent/last-chance states)

struct GlitchText: View {
    let text: String
    let font: Font
    let color: Color
    let isActive: Bool
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var sliceOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .offset(x: offsetX, y: offsetY)
            
            if isActive {
                Text(text)
                    .font(font)
                    .foregroundColor(.red.opacity(0.6))
                    .offset(x: offsetX + 2, y: offsetY - 1)
                    .mask(
                        Rectangle()
                            .offset(y: sliceOffset)
                            .frame(height: 8)
                    )
            }
        }
        .onChange(of: isActive) { _, active in
            if active { startGlitch() }
        }
    }
    
    private func startGlitch() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            guard isActive else { timer.invalidate(); return }
            withAnimation(.linear(duration: 0.04)) {
                offsetX = CGFloat.random(in: -3...3)
                offsetY = CGFloat.random(in: -1...1)
                sliceOffset = CGFloat.random(in: -10...10)
            }
        }
    }
}
