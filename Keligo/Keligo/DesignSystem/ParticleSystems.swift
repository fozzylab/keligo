import SwiftUI

// MARK: - Particle Burst (for wrong guesses, reveals, wins)

struct ParticleBurst: View {
    let origin: CGPoint
    let color: Color
    let count: Int
    let spread: CGFloat
    
    @State private var particles: [BurstParticle] = []
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: false)) { _ in
            Canvas { context, size in
                for p in particles {
                    var path = Path()
                    path.addEllipse(in: CGRect(x: p.x - p.size/2, y: p.y - p.size/2, width: p.size, height: p.size))
                    context.fill(path, with: .color(color.opacity(p.opacity)))
                }
            }
        }
        .onAppear { spawn() }
        .allowsHitTesting(false)
    }
    
    private func spawn() {
        particles = (0..<count).map { i in
            BurstParticle(
                id: i,
                x: origin.x,
                y: origin.y,
                vx: CGFloat.random(in: -spread...spread),
                vy: CGFloat.random(in: -spread...spread) - 40,
                size: CGFloat.random(in: 2...6),
                life: 1.0,
                decay: CGFloat.random(in: 0.015...0.03)
            )
        }
        
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            var alive = false
            for i in particles.indices {
                particles[i].x += particles[i].vx
                particles[i].y += particles[i].vy
                particles[i].vy += 1.2 // gravity
                particles[i].life -= particles[i].decay
                if particles[i].life > 0 { alive = true }
            }
            if !alive { timer.invalidate() }
        }
    }
}

struct BurstParticle {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var life: CGFloat
    var decay: CGFloat
    
    var opacity: Double { max(0, Double(life)) }
}

// MARK: - Spark Trail (for correct letter reveals)

struct SparkTrail: View {
    let position: CGPoint
    let color: Color
    
    @State private var sparks: [Spark] = []
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: false)) { _ in
            Canvas { context, size in
                for spark in sparks {
                    var path = Path()
                    path.addEllipse(in: CGRect(x: spark.x, y: spark.y, width: spark.size, height: spark.size))
                    context.fill(path, with: .color(color.opacity(spark.opacity)))
                }
            }
        }
        .onAppear {
            for i in 0..<12 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.015) {
                    let angle = Double.random(in: 0...(2 * .pi))
                    let dist = CGFloat.random(in: 10...40)
                    sparks.append(Spark(
                        x: position.x + cos(angle) * dist,
                        y: position.y + sin(angle) * dist,
                        size: CGFloat.random(in: 1.5...3.5),
                        opacity: 1.0,
                        decay: CGFloat.random(in: 0.04...0.08)
                    ))
                }
            }
            Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
                var alive = false
                for i in sparks.indices {
                    sparks[i].opacity -= sparks[i].decay
                    if sparks[i].opacity > 0 { alive = true }
                }
                if !alive { timer.invalidate() }
            }
        }
        .allowsHitTesting(false)
    }
}

struct Spark {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var decay: CGFloat
}

// MARK: - Dissolve Effect (for game over)

struct DissolveOverlay: View {
    let isActive: Bool
    let direction: DissolveDirection
    
    @State private var progress: CGFloat = 0
    
    enum DissolveDirection {
        case fade, crumble, wipeDown
    }
    
    var body: some View {
        GeometryReader { geo in
            if isActive {
                switch direction {
                case .fade:
                    Color.black.opacity(Double(progress) * 0.7)
                        .ignoresSafeArea()
                case .wipeDown:
                    VStack {
                        Color.black.opacity(0.75)
                            .frame(height: geo.size.height * progress)
                        Spacer()
                    }
                    .ignoresSafeArea()
                case .crumble:
                    CrumbleCanvas(progress: progress, size: geo.size)
                        .ignoresSafeArea()
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 1.2)) {
                    progress = 1.0
                }
            } else {
                progress = 0
            }
        }
        .allowsHitTesting(false)
    }
}

struct CrumbleCanvas: View {
    let progress: CGFloat
    let size: CGSize
    
    var body: some View {
        let blocks = 20
        let blockW = size.width / CGFloat(blocks)
        let blockH = size.height / CGFloat(blocks)
        
        Canvas { context, _ in
            for row in 0..<blocks {
                for col in 0..<blocks {
                    let threshold = CGFloat(row * blocks + col) / CGFloat(blocks * blocks)
                    if progress > threshold {
                        let alpha = min(1.0, Double((progress - threshold) * 4))
                        let rect = CGRect(x: CGFloat(col) * blockW, y: CGFloat(row) * blockH, width: blockW, height: blockH)
                        var path = Path()
                        path.addRect(rect)
                        context.fill(path, with: .color(.black.opacity(alpha * 0.75)))
                    }
                }
            }
        }
    }
}

// MARK: - Floating Dust (Static, No TimelineView)

struct FloatingDust: View {
    let color: Color
    let count: Int
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, _ in
                for _ in 0..<count {
                    let x = CGFloat.random(in: 0...geo.size.width)
                    let y = CGFloat.random(in: 0...geo.size.height)
                    let size = CGFloat.random(in: 1...2.5)
                    let opacity = Double.random(in: 0.04...0.10)
                    
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
                    context.fill(path, with: .color(color.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
