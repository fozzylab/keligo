import SwiftUI

/// `AppPromptManager.current` ne zaman set olursa MainMenuView üzerinde dismiss edilebilir banner gösterilir.
struct AppPromptBanner: View {
    let kind: AppPromptManager.PromptKind
    let theme: AppTheme
    let onCTA: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.subheadline.weight(.black))
                    .foregroundColor(.white)
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onCTA) {
                    HStack(spacing: 4) {
                        Text(kind.ctaText)
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .foregroundColor(.black)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        .padding(.horizontal, 16)
    }

    private var emoji: String {
        switch kind {
        case .losingStreak:    return "💪"
        case .allChaptersDone: return "🏆"
        case .heavyHintUser:   return "💎"
        }
    }

    private var gradient: [Color] {
        switch kind {
        case .losingStreak:
            return [Color(red: 0.55, green: 0.20, blue: 0.95), Color(red: 0.85, green: 0.35, blue: 0.65)]
        case .allChaptersDone:
            return [Color(red: 0.95, green: 0.65, blue: 0.10), Color(red: 1.00, green: 0.40, blue: 0.20)]
        case .heavyHintUser:
            return [Color(red: 0.20, green: 0.50, blue: 0.95), Color(red: 0.45, green: 0.80, blue: 1.00)]
        }
    }
}

/// `RewardToast` — reklam izlendikten sonra ne kazanıldığını gösteren animasyonlu mini toast.
struct RewardToast: View {
    let icon: String
    let label: String
    let amount: String
    let color: Color
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.8))
                Text(amount)
                    .font(.headline.weight(.black))
                    .foregroundColor(color)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.4), radius: 16, y: 6)
        .padding(.horizontal, 20)
    }
}
