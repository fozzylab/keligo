import SwiftUI

private struct Piece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let delay: Double
    let rotation: Double
    let isCircle: Bool
}

private struct PieceView: View {
    let piece: Piece
    let screenHeight: CGFloat
    @State private var yOffset: CGFloat = -20
    @State private var opacity: Double = 1

    var body: some View {
        Group {
            if piece.isCircle {
                Circle().fill(piece.color).frame(width: piece.size, height: piece.size)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.6)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .position(x: piece.x, y: yOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 1.8).delay(piece.delay)) {
                yOffset = screenHeight + 40
            }
            withAnimation(.linear(duration: 0.4).delay(piece.delay + 1.4)) {
                opacity = 0
            }
        }
    }
}

struct ConfettiView: View {
    @State private var pieces: [Piece] = []

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    PieceView(piece: piece, screenHeight: geo.size.height)
                }
            }
            .onAppear {
                pieces = (0..<60).map { _ in
                    Piece(
                        x: CGFloat.random(in: 20...(geo.size.width - 20)),
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 6...14),
                        delay: Double.random(in: 0...0.6),
                        rotation: Double.random(in: 0...360),
                        isCircle: Bool.random()
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}
