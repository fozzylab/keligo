import SwiftUI
import Combine

/// Canlar bittiğinde gösterilen modal sheet.
/// 5 seçenek: bekle, reklam, 50 jeton, 200 jeton, sınırsız can IAP CTA.
struct OutOfLivesSheet: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager
    @StateObject private var lives = LivesManager.shared
    @StateObject private var iap = IAPManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var now: Date = Date()
    @State private var showIAPStore = false
    @State private var rewardedShowing = false
    @State private var showAdConfirm = false
    @State private var rewardToast: String? = nil

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let ad = AdManager.shared

    var t: AppTheme { settings.theme }

    private var timeRemaining: String {
        guard let next = lives.nextRegenAt else { return "—" }
        let remaining = max(0, next.timeIntervalSince(now))
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    countdownCard
                    optionsList
                    iapCta
                    waitButton
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }

            // Reward toast (reklam / jeton sonrası)
            if let toast = rewardToast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.title3.weight(.black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28).padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [.green, Color(red: 0.1, green: 0.7, blue: 0.4)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .shadow(color: .green.opacity(0.5), radius: 20, y: 6)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .zIndex(50)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .onReceive(timer) { _ in
            now = Date()
            lives.recomputeRegen()
        }
        .alert("Reklam izle, +1 can kazan", isPresented: $showAdConfirm) {
            Button("İzle") {
                Task {
                    rewardedShowing = true
                    // Alert animasyonu kapanmadan ad sunmaya çalışmamak için kısa bekleme
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    let ok = await lives.adRefill()
                    rewardedShowing = false
                    if ok {
                        withAnimation(.spring()) { rewardToast = "❤️ +1 Can kazandın!" }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { rewardToast = nil }
                        }
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("📺 Kısa bir reklam sonrası 1 canın yenilenir.\nBugünkü hak: \(ad.remaining(.life))/\(AdManager.RewardKind.life.dailyCap)")
        }
        .sheet(isPresented: $showIAPStore) {
            IAPStoreView()
                .environmentObject(settings)
                .environmentObject(jetons)
        }
    }

    // MARK: - Helpers

    /// Sarı jeton rozeti — tüm call site'larda tutarlı
    private func jetonBadge(_ amount: Int, primary: Bool = false) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.yellow)
            Text("\(amount)")
                .font(.caption.weight(.black))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(primary ? Color.yellow.opacity(0.22) : Color.yellow.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(Color.yellow.opacity(0.30), lineWidth: primary ? 1 : 0))
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<LivesManager.maxLives, id: \.self) { _ in
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(t.secondaryText.opacity(0.4))
                }
            }
            Text("Canların Bitti!")
                .font(.title.weight(.black))
                .foregroundColor(t.primaryText)
            Text("Devam etmek için bekle, reklam izle ya da jeton harca.")
                .font(.subheadline)
                .foregroundColor(t.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var countdownCard: some View {
        VStack(spacing: 6) {
            Text("Yeni canın geliyor")
                .font(.caption.weight(.semibold))
                .foregroundColor(t.secondaryText)
            Text(timeRemaining)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(t.accent)
            Text("(her 30 dakikada 1 can)")
                .font(.caption2)
                .foregroundColor(t.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(t.cardFill, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(t.cardStroke, lineWidth: 0.8))
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            // Reklam izle
            optionRow(
                icon: "play.rectangle.fill", color: .purple,
                title: "Reklam İzle",
                subtitle: ad.canShowRewarded(.life)
                    ? "Kısa video → +1 can • Hak: \(ad.remaining(.life))/\(AdManager.RewardKind.life.dailyCap)"
                    : "Bugünkü hak doldu — yarın tekrar gel",
                badgeContent: {
                    Text("+1 ❤️")
                        .font(.caption.weight(.black))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.purple.opacity(0.18), in: Capsule())
                },
                enabled: ad.canShowRewarded(.life) && !rewardedShowing,
                primary: false
            ) { showAdConfirm = true }

            // 1 can al
            optionRow(
                icon: "heart.circle.fill", color: .pink,
                title: "1 Can Al",
                subtitle: "Bakiye: \(jetons.balance) jeton",
                badgeContent: { jetonBadge(JetonManager.costRefillOne) },
                enabled: jetons.canAfford(JetonManager.costRefillOne),
                primary: false
            ) {
                if lives.buyOne() {
                    withAnimation(.spring()) { rewardToast = "❤️ +1 Can kazandın!" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation { rewardToast = nil }
                    }
                }
            }

            // Tam dolum
            optionRow(
                icon: "heart.fill", color: .red,
                title: "Tam Dolum",
                subtitle: "5 can — %50 indirim",
                badgeContent: { jetonBadge(JetonManager.costRefillAll, primary: true) },
                enabled: jetons.canAfford(JetonManager.costRefillAll),
                primary: true
            ) {
                if lives.buyAll() {
                    withAnimation(.spring()) { rewardToast = "❤️❤️❤️❤️❤️ Tam dolum!" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation { rewardToast = nil }
                    }
                }
            }
        }
    }

    private var iapCta: some View {
        Button {
            showIAPStore = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "infinity.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sınırsız Can")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Text("Tek seferlik satın al, bir daha bekleme")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(t.secondaryText)
            }
            .padding(14)
            .background(
                LinearGradient(colors: [Color.yellow.opacity(0.12), Color.orange.opacity(0.08)],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var waitButton: some View {
        Button("Bekleyeceğim") { dismiss() }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(t.secondaryText)
            .padding(.top, 6)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func optionRow<Badge: View>(
        icon: String, color: Color,
        title: String, subtitle: String,
        @ViewBuilder badgeContent: () -> Badge,
        enabled: Bool, primary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(primary
                              ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(color.opacity(0.18)))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(primary ? .white : color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }

                Spacer()

                badgeContent()
            }
            .padding(14)
            .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(t.cardStroke, lineWidth: 0.8))
            .opacity(enabled ? 1.0 : 0.45)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!enabled)
    }
}

#Preview {
    OutOfLivesSheet()
        .environmentObject(SettingsViewModel())
        .environmentObject(JetonManager.shared)
}
