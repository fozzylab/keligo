import SwiftUI

struct LivesInfoSheet: View {
    @ObservedObject var lives: LivesManager
    let onRefill: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager

    @State private var now = Date()
    @State private var timer: Timer? = nil
    @State private var rewardedShowing = false
    @State private var showAdConfirm = false
    @State private var rewardToast: String? = nil
    @State private var showIAPStore = false

    private let ad = AdManager.shared
    var t: AppTheme { settings.theme }

    // MARK: - Computed

    private var secondsToNext: TimeInterval {
        guard let next = lives.nextRegenAt, !lives.isFull, !lives.hasInfinite else { return 0 }
        return max(0, next.timeIntervalSince(now))
    }

    private var totalSecondsToFull: TimeInterval {
        guard !lives.isFull, !lives.hasInfinite else { return 0 }
        let missing = LivesManager.maxLives - lives.current
        return max(0, secondsToNext + TimeInterval(max(0, missing - 1)) * LivesManager.regenIntervalSeconds)
    }

    private func fmt(_ s: TimeInterval) -> String {
        String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(t.secondaryText.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 18)

            // Hearts
            HStack(spacing: 12) {
                ForEach(0..<LivesManager.maxLives, id: \.self) { i in
                    Image(systemName: i < lives.current ? "heart.fill" : "heart")
                        .font(.system(size: 26))
                        .foregroundColor(i < lives.current ? .red : t.secondaryText.opacity(0.25))
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: lives.current)
                }
            }
            .padding(.bottom, 6)

            if lives.hasInfinite {
                // Sınırsız can
                Label("Sınırsız Can", systemImage: "infinity.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundColor(t.accent)
                    .padding(.bottom, 4)
                Text("İstediğin kadar oyna!")
                    .font(.subheadline).foregroundColor(t.secondaryText)
                    .padding(.bottom, 24)

            } else if lives.isFull {
                // Tam dolu
                Text("Canların tam dolu 🎉")
                    .font(.title2.weight(.bold)).foregroundColor(t.primaryText)
                    .padding(.bottom, 4)
                Text("Oynamaya başla!").font(.subheadline)
                    .foregroundColor(t.secondaryText).padding(.bottom, 24)

            } else {
                // Eksik can — sayaç + seçenekler
                Text("\(lives.current) / \(LivesManager.maxLives) can")
                    .font(.headline.weight(.bold)).foregroundColor(t.primaryText)
                    .padding(.bottom, 8)

                // Sayaç kutusu
                VStack(spacing: 4) {
                    Text("Sonraki can")
                        .font(.caption.weight(.semibold)).foregroundColor(t.secondaryText)
                    Text(fmt(secondsToNext))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(t.accent).monospacedDigit()
                        .contentTransition(.numericText())
                    if LivesManager.maxLives - lives.current > 1 {
                        Text("Tüm canlar \(Int(ceil(totalSecondsToFull / 60))) dk içinde dolacak")
                            .font(.caption).foregroundColor(t.secondaryText)
                    }
                }
                .padding(.vertical, 16).padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(t.cardFill, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(t.cardStroke, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Seçenekler
                VStack(spacing: 10) {
                    // Reklam izle
                    if !IAPManager.shared.isAdsRemoved {
                        optionRow(
                            icon: "play.rectangle.fill", color: .purple,
                            title: "Reklam İzle",
                            subtitle: ad.canShowRewarded(.life)
                                ? "Kısa video → +1 can • Hak: \(ad.remaining(.life))/\(AdManager.RewardKind.life.dailyCap)"
                                : "Bugünkü hak doldu",
                            badge: { Text("+1 ❤️").font(.caption.weight(.black)).foregroundColor(.purple)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.purple.opacity(0.15), in: Capsule()) },
                            enabled: ad.canShowRewarded(.life) && !rewardedShowing
                        ) { showAdConfirm = true }
                    }

                    // 1 Can Al
                    optionRow(
                        icon: "heart.circle.fill", color: .pink,
                        title: "1 Can Al",
                        subtitle: "Bakiye: \(jetons.balance) jeton",
                        badge: { coinBadge(lives.currentRefillCost) },
                        enabled: jetons.canAfford(lives.currentRefillCost)
                    ) {
                        if lives.buyOne() {
                            rewardToast = "❤️ +1 Can kazandın!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { rewardToast = nil }
                        }
                    }

                    // Tam Dolum
                    optionRow(
                        icon: "heart.fill", color: .red,
                        title: "Tam Dolum",
                        subtitle: "\(LivesManager.maxLives) can — %50 indirim",
                        badge: { coinBadge(JetonManager.costRefillAll, primary: true) },
                        enabled: jetons.canAfford(JetonManager.costRefillAll)
                    ) {
                        if lives.buyAll() {
                            rewardToast = "❤️❤️❤️❤️❤️ Tam dolum!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { rewardToast = nil }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            // Alt butonlar
            VStack(spacing: 10) {
                if !lives.hasInfinite {
                    // Sınırsız can için mağazaya yönlendir
                    Button { showIAPStore = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "infinity.circle.fill")
                                .foregroundColor(t.accent)
                            Text("Sınırsız Can Al")
                                .foregroundColor(t.accent)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(t.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.accent.opacity(0.30), lineWidth: 1))
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
            .padding(.horizontal, 20)
            .padding(.bottom, 34)

            // Toast overlay — ekran ortasında büyük göster
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
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(t.background.ignoresSafeArea())
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: rewardToast)
        .onAppear {
            lives.recomputeRegen()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                now = Date()
                lives.recomputeRegen()
            }
        }
        .onDisappear { timer?.invalidate(); timer = nil }
        .alert("Reklam izle, +1 can kazan", isPresented: $showAdConfirm) {
            Button("İzle") {
                Task {
                    rewardedShowing = true
                    let ok = await lives.adRefill()
                    rewardedShowing = false
                    if ok {
                        rewardToast = "❤️ +1 Can kazandın!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { rewardToast = nil }
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Kısa bir reklam sonrası 1 canın yenilenir.")
        }
        .sheet(isPresented: $showIAPStore) {
            IAPStoreView()
                .environmentObject(settings)
                .environmentObject(jetons)
        }
    }

    // MARK: - Helpers

    private func coinBadge(_ amount: Int, primary: Bool = false) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7, weight: .bold)).foregroundColor(.yellow)
            Text("\(amount)")
                .font(.caption.weight(.black)).foregroundColor(.yellow)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color.yellow.opacity(primary ? 0.22 : 0.14), in: Capsule())
    }

    @ViewBuilder
    private func optionRow<Badge: View>(
        icon: String, color: Color,
        title: String, subtitle: String,
        @ViewBuilder badge: () -> Badge,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: icon).font(.body).foregroundColor(color))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundColor(t.primaryText)
                    Text(subtitle).font(.caption).foregroundColor(t.secondaryText).lineLimit(1)
                }
                Spacer()
                badge()
            }
            .padding(12)
            .background(t.cardFill, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.cardStroke, lineWidth: 0.8))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!enabled)
    }
}
