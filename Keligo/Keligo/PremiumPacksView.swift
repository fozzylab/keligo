import SwiftUI
import StoreKit

struct PremiumPacksView: View {
    @StateObject private var iap = IAPManager.shared
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }

    private let packs: [(id: String, name: String, icon: String, description: String, productId: String, words: Int)] = [
        ("sinema", "Sinema Dünyası", "🎬", "Film, yönetmen, senaryo ve daha fazlası", "com.fozzylabs.keligo.sinemaPack", 25),
        ("bilim",  "Bilim & Teknoloji", "🔬", "Algoritma, kuantum, galaksi ve daha fazlası", "com.fozzylabs.keligo.bilimPack", 25),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("📦")
                                .font(.system(size: 56))
                            Text("Kelime Paketleri")
                                .font(.title2.bold())
                                .foregroundColor(t.primaryText)
                            Text("Yeni kategoriler ve özel kelimeler")
                                .font(.caption)
                                .foregroundColor(t.secondaryText)
                        }
                        .padding(.top, 8)

                        ForEach(packs, id: \.id) { pack in
                            PackCard(pack: pack, iap: iap, theme: t)
                        }
                        .padding(.horizontal)

                        Button("Satın Almaları Geri Yükle") {
                            Task { await iap.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
        }
    }
}

private struct PackCard: View {
    let pack: (id: String, name: String, icon: String, description: String, productId: String, words: Int)
    @ObservedObject var iap: IAPManager
    let theme: AppTheme

    private var isUnlocked: Bool { iap.isPackUnlocked(pack.id) }
    private var product: Product? { iap.products.first(where: { $0.id == pack.productId }) }

    var body: some View {
        HStack(spacing: 14) {
            Text(pack.icon)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(pack.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.primaryText)
                    if isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(theme.correct)
                    }
                }
                Text(pack.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                Text("\(pack.words) özel kelime")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(theme.accent)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundColor(theme.correct)
            } else if let product {
                Button {
                    Task { await iap.purchase(product) }
                } label: {
                    Text(product.displayPrice)
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(theme.accentGradient, in: Capsule())
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(iap.isPurchasing)
            } else {
                ProgressView().scaleEffect(0.8)
            }
        }
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isUnlocked ? theme.correct.opacity(0.35) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    PremiumPacksView()
        .environmentObject(SettingsViewModel())
}
