import SwiftUI

// MARK: - Helper shapes (relative 0–1 coordinates, scale with frame)

private struct LineSegment: Shape {
    let x1, y1, x2, y2: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: r.width * x1, y: r.height * y1))
        p.addLine(to: CGPoint(x: r.width * x2, y: r.height * y2))
        return p
    }
}

private struct CircleAt: Shape {
    let cx, cy, radius: CGFloat // radius relative to width
    func path(in r: CGRect) -> Path {
        let rd = r.width * radius
        return Path(ellipseIn: CGRect(
            x: r.width * cx - rd,
            y: r.height * cy - rd,
            width: rd * 2, height: rd * 2
        ))
    }
}

// MARK: - Animated stroke wrapper

private struct AnimatedPart<S: Shape>: View {
    let shape: S
    let color: Color
    @State private var progress: CGFloat = 0

    var body: some View {
        shape
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45)) { progress = 1 }
            }
    }
}

// MARK: - Main view

struct KeligoDrawing: View {
    let wrongGuesses: Int
    let maxWrong: Int
    let theme: AppTheme

    /// Show step N (1–6) relative to maxWrong
    private func show(_ step: Int) -> Bool {
        wrongGuesses >= Int((Double(step) / 6.0) * Double(maxWrong) + 0.5)
    }

    var body: some View {
        ZStack {
            // ── Gallows (always visible, no animation needed) ──
            LineSegment(x1: 0.10, y1: 0.95, x2: 0.90, y2: 0.95) // ground
                .stroke(theme.primaryText, lineWidth: 3)
            LineSegment(x1: 0.25, y1: 0.95, x2: 0.25, y2: 0.05) // pole
                .stroke(theme.primaryText, lineWidth: 3)
            LineSegment(x1: 0.25, y1: 0.05, x2: 0.60, y2: 0.05) // top beam
                .stroke(theme.primaryText, lineWidth: 3)
            LineSegment(x1: 0.60, y1: 0.05, x2: 0.60, y2: 0.18) // rope
                .stroke(theme.primaryText, lineWidth: 3)

            // ── Body parts (each animates in when it first appears) ──

            if show(1) { // head
                AnimatedPart(shape: CircleAt(cx: 0.60, cy: 0.27, radius: 0.075), color: theme.primaryText)
            }
            if show(2) { // torso
                AnimatedPart(shape: LineSegment(x1: 0.60, y1: 0.35, x2: 0.60, y2: 0.63), color: theme.primaryText)
            }
            if show(3) { // left arm
                AnimatedPart(shape: LineSegment(x1: 0.60, y1: 0.41, x2: 0.43, y2: 0.53), color: theme.primaryText)
            }
            if show(4) { // right arm
                AnimatedPart(shape: LineSegment(x1: 0.60, y1: 0.41, x2: 0.77, y2: 0.53), color: theme.primaryText)
            }
            if show(5) { // left leg
                AnimatedPart(shape: LineSegment(x1: 0.60, y1: 0.63, x2: 0.43, y2: 0.80), color: theme.primaryText)
            }
            if show(6) { // right leg
                AnimatedPart(shape: LineSegment(x1: 0.60, y1: 0.63, x2: 0.77, y2: 0.80), color: theme.primaryText)
            }
        }
        .frame(width: 190, height: 200)
    }
}

#Preview {
    HStack(spacing: 20) {
        KeligoDrawing(wrongGuesses: 3, maxWrong: 6, theme: .classic)
        KeligoDrawing(wrongGuesses: 6, maxWrong: 6, theme: .midnight)
    }
    .padding().background(Color(.systemBackground))
}
