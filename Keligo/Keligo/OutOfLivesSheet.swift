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

            // Reward toast (reklam izlendikten sonra)
            if let toast = rewardToast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.green, Color(red: 0.1, green: 0.7, blue: 0.4)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: .green.opacity(0.45), radius: 14, y: 4)
                        .padding(.bottom, 60)
                }
                .zIndex(50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(timer) { _ in
            now = Date()
            // Yenilenme oldu mu kontrol
            lives.recomputeRegen()
            if lives.current > 0 { dismiss() }
        }
        .alert("Reklam izle, +1 can kazan", isPresented: $showAdConfirm) {
            Button("İzle") {
                Task {
                    rewardedShowing = true
                    let ok = await lives.adRefill()
                    rewardedShowing = false
                    if ok {
                        withAnimation(.spring()) { rewardToast = "❤️ +1 Can kazandın!" }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation { rewardToast = nil }
                            dismiss()
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
        .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            // Reklam izle
            optionRow(
                icon: "play.rectangle.fill",
                color: .purple,
                title: "Reklam İzle",
                subtitle: ad.canShowRewarded(.life)
                    ? "📺 Kısa video → +1 can • Bugünkü hak: \(ad.remaining(.life))/\(AdManager.RewardKind.life.dailyCap)"
                    : "Bugünkü hak doldu — yarın tekrar gel",
                badge: "+1 ❤️",
                enabled: ad.canShowRewarded(.life) && !rewardedShowing,
                primary: false
            ) {
                showAdConfirm = true
            }

            // 50 jeton ile +1
            optionRow(
                icon: "heart.circle.fill",
                color: .pink,
                title: "1 Can Al",
                subtitle: "Bakiye: \(jetons.balance) 🪙",
                badge: "\(JetonManager.costRefillOne) 🪙",
                enabled: jetons.canAfford(JetonManager.costRefillOne),
                primary: false
            ) {
                if lives.buyOne() {
                    withAnimation(.spring()) { rewardToast = "❤️ +1 Can!" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
                }
            }

            // 200 jeton ile tam dolum
            optionRow(
                icon: "heart.fill",
                color: .red,
                title: "Tam Dolum",
                subtitle: "5 can — %50 indirim",
                badge: "\(JetonManager.costRefillAll) 🪙",
                enabled: jetons.canAfford(JetonManager.costRefillAll),
                primary: true
            ) {
                if lives.buyAll() {
                    withAnimation(.spring()) { rewardToast = "❤️❤️❤️❤️❤️ Tam dolum!" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
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
    private func optionRow(
        icon: String, color: Color,
        title: String, subtitle: String,
        badge: String,
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

                Text(badge)
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(
                        primary
                            ? AnyShapeStyle(color)
                            : AnyShapeStyle(color.opacity(0.18)),
                        in: Capsule()
                    )
                    .foregroundColor(primary ? .white : color)
            }
            .padding(14)
            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 16))
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
