import SwiftUI

// MARK: - Continue After Loss Overlay

struct ContinueAfterLossView: View {
    let theme: AppTheme
    let canAffordJetons: Bool
    let onWatchAd: () -> Void
    let onSpendJetons: () -> Void
    let onDecline: () -> Void
    
    @State private var appear = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { /* block dismiss */ }
            
            VStack(spacing: 22) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(theme.accentGradient)
                        .symbolEffect(.pulse)
                }
                
                // Title
                Text("Son Şansın!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Bir yanlış hakkın daha var. Oyunu kurtarmak ister misin?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    // Watch ad button
                    Button(action: onWatchAd) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reklam İzle")
                                    .font(.headline)
                                Text("Ücretsiz devam et")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Spend jetons button
                    Button(action: onSpendJetons) {
                        HStack(spacing: 10) {
                            Image(systemName: "circle.fill")
                                .font(.title3)
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(JetonManager.costContinueAfterLoss) Jeton Harca")
                                    .font(.headline)
                                Text(canAffordJetons ? "Hemen devam et" : "Yetersiz jeton")
                                    .font(.caption)
                                    .foregroundColor(canAffordJetons ? .white.opacity(0.7) : .red.opacity(0.9))
                            }
                            Spacer()
                        }
                        .foregroundColor(canAffordJetons ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            canAffordJetons
                                ? AnyShapeStyle(Color.white.opacity(0.12))
                                : AnyShapeStyle(Color.white.opacity(0.05)),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(canAffordJetons ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canAffordJetons)
                    
                    // Decline
                    Button(action: onDecline) {
                        Text("Vazgeç")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 30)
            .background(
                Color(white: 0.10).opacity(0.97),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.30), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 24)
            .scaleEffect(appear ? 1.0 : 0.85)
            .opacity(appear ? 1.0 : 0.0)
            .animation(CinematicSpring.bouncy, value: appear)
        }
        .onAppear { appear = true }
    }
}
