import SwiftUI

struct LivesInfoSheet: View {
    @ObservedObject var lives: LivesManager
    let onRefill: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager

    @State private var now = Date()
    @State private var timer: Timer? = nil

    var t: AppTheme { settings.theme }

    // MARK: - Derived state

    private var isFull: Bool { lives.isFull || lives.hasInfinite }

    private var secondsToNextLife: TimeInterval {
        guard let next = lives.nextRegenAt, !lives.isFull, !lives.hasInfinite else { return 0 }
        return max(0, next.timeIntervalSince(now))
    }

    private var secondsToFull: TimeInterval {
        guard !lives.isFull, !lives.hasInfinite else { return 0 }
        let missing = LivesManager.maxLives - lives.current
        return max(0, secondsToNextLife + TimeInterval(max(0, missing - 1)) * LivesManager.regenIntervalSeconds)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(t.secondaryText.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Hearts row
            HStack(spacing: 14) {
                ForEach(0..<LivesManager.maxLives, id: \.self) { i in
                    Image(systemName: i < lives.current ? "heart.fill" : "heart")
                        .font(.system(size: 30))
                        .foregroundColor(i < lives.current ? .red : t.secondaryText.opacity(0.25))
                        .scaleEffect(i < lives.current ? 1.0 : 0.85)
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: lives.current)
                }
            }
            .padding(.bottom, 8)

            // State label
            if lives.hasInfinite {
                Label("Sınırsız Can", systemImage: "infinity.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundColor(t.accent)
                    .padding(.bottom, 4)
                Text("İstediğin kadar oyna!")
                    .font(.subheadline)
                    .foregroundColor(t.secondaryText)
            } else if lives.isFull {
                Text("Canların tam dolu 🎉")
                    .font(.title2.weight(.bold))
                    .foregroundColor(t.primaryText)
                    .padding(.bottom, 4)
                Text("Oynamaya başla!")
                    .font(.subheadline)
                    .foregroundColor(t.secondaryText)
            } else {
                Text("\(lives.current) / \(LivesManager.maxLives) can")
                    .font(.title2.weight(.bold))
                    .foregroundColor(t.primaryText)
                    .padding(.bottom, 4)

                // Single countdown block
                VStack(spacing: 6) {
                    Text("Sonraki can")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(t.secondaryText)

                    Text(formatTime(secondsToNextLife))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(t.accent)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    if LivesManager.maxLives - lives.current > 1 {
                        let totalMins = Int(ceil(secondsToFull / 60))
                        Text("Tüm canlar \(totalMins) dk içinde dolacak")
                            .font(.caption)
                            .foregroundColor(t.secondaryText)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .background(t.cardFill, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(t.cardStroke, lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if !lives.isFull && !lives.hasInfinite {
                    Button {
                        onDismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onRefill() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.heart.fill")
                            Text("Jeton ile Hemen Doldur")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.red, Color(red: 1, green: 0.3, blue: 0.3)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button("Tamam") { onDismiss() }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(t.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.cardStroke, lineWidth: 1))
                    .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(t.background.ignoresSafeArea())
        .onAppear {
            lives.recomputeRegen()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                now = Date()
                lives.recomputeRegen()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
