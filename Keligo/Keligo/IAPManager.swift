import Foundation
import StoreKit
import Combine
import SwiftUI

// MARK: - Product IDs
// These must be configured in App Store Connect before going live.

enum IAPProduct: String, CaseIterable {
    case jetons500          = "com.fozzylabs.keligo.jetons500"
    case jetons1500         = "com.fozzylabs.keligo.jetons1500"
    case jetons5000         = "com.fozzylabs.keligo.jetons5000"
    case removeAds          = "com.fozzylabs.keligo.removeads"
    case sinemaPack         = "com.fozzylabs.keligo.sinemaPack"
    case bilimPack          = "com.fozzylabs.keligo.bilimPack"
    case unlimitedLives     = "com.fozzylabs.keligo.unlimitedLives"
    case themePackPremium   = "com.fozzylabs.keligo.themePackPremium"
    case tarihPlusPack      = "com.fozzylabs.keligo.tarihPlusPack"
    case sporYildizlariPack = "com.fozzylabs.keligo.sporYildizlariPack"
    case muzikProPack       = "com.fozzylabs.keligo.muzikProPack"
    case premiumBundle      = "com.fozzylabs.keligo.premiumBundle"

    var displayName: String {
        switch self {
        case .jetons500:          return "500 Jeton"
        case .jetons1500:         return "1.500 Jeton"
        case .jetons5000:         return "5.000 Jeton"
        case .removeAds:          return "Reklamları Kaldır"
        case .sinemaPack:         return "Sinema Dünyası Paketi"
        case .bilimPack:          return "Bilim & Teknoloji Paketi"
        case .unlimitedLives:     return "Sınırsız Can"
        case .themePackPremium:   return "Premium Tema Paketi"
        case .tarihPlusPack:      return "Tarih+ Paketi"
        case .sporYildizlariPack: return "Spor Yıldızları Paketi"
        case .muzikProPack:       return "Müzik Pro Paketi"
        case .premiumBundle:      return "Premium Paket — Tümü Bir Arada"
        }
    }

    var icon: String {
        switch self {
        case .jetons500, .jetons1500, .jetons5000: return "circle.fill"
        case .removeAds:          return "hand.thumbsup.fill"
        case .sinemaPack:         return "film.stack"
        case .bilimPack:          return "atom"
        case .unlimitedLives:     return "heart.fill"
        case .themePackPremium:   return "paintpalette.fill"
        case .tarihPlusPack:      return "scroll.fill"
        case .sporYildizlariPack: return "sportscourt.fill"
        case .muzikProPack:       return "music.note"
        case .premiumBundle:      return "crown.fill"
        }
    }

    var jetonAmount: Int {
        switch self {
        case .jetons500:     return 500
        case .jetons1500:    return 1500
        case .jetons5000:    return 5000
        case .premiumBundle: return 5000   // bundle içinde 5000J armağan
        default:             return 0
        }
    }
}

// MARK: - IAPManager

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var errorMessage: String? = nil

    var isAdsRemoved: Bool {
        purchasedProductIDs.contains(IAPProduct.removeAds.rawValue)
            || purchasedProductIDs.contains(IAPProduct.premiumBundle.rawValue)
            || UserDefaults.standard.bool(forKey: "adsRemoved")
    }

    var isUnlimitedLives: Bool {
        purchasedProductIDs.contains(IAPProduct.unlimitedLives.rawValue)
            || purchasedProductIDs.contains(IAPProduct.premiumBundle.rawValue)
            || UserDefaults.standard.bool(forKey: "pack_unlimited_lives_unlocked")
    }

    var isThemePackUnlocked: Bool {
        purchasedProductIDs.contains(IAPProduct.themePackPremium.rawValue)
            || purchasedProductIDs.contains(IAPProduct.premiumBundle.rawValue)
            || UserDefaults.standard.bool(forKey: "pack_theme_premium_unlocked")
    }

    func isPackUnlocked(_ packId: String) -> Bool {
        let bundleOwned = purchasedProductIDs.contains(IAPProduct.premiumBundle.rawValue)
            || UserDefaults.standard.bool(forKey: "pack_premium_bundle_unlocked")
        if bundleOwned { return true }
        switch packId {
        case "sinema":          return purchasedProductIDs.contains(IAPProduct.sinemaPack.rawValue)
                                    || UserDefaults.standard.bool(forKey: "pack_sinema_unlocked")
        case "bilim":           return purchasedProductIDs.contains(IAPProduct.bilimPack.rawValue)
                                    || UserDefaults.standard.bool(forKey: "pack_bilim_unlocked")
        case "tarih_plus":      return purchasedProductIDs.contains(IAPProduct.tarihPlusPack.rawValue)
                                    || UserDefaults.standard.bool(forKey: "pack_tarih_plus_unlocked")
        case "spor_yildizlari": return purchasedProductIDs.contains(IAPProduct.sporYildizlariPack.rawValue)
                                    || UserDefaults.standard.bool(forKey: "pack_spor_yildizlari_unlocked")
        case "muzik_pro":       return purchasedProductIDs.contains(IAPProduct.muzikProPack.rawValue)
                                    || UserDefaults.standard.bool(forKey: "pack_muzik_pro_unlocked")
        default: return false
        }
    }

    private init() {
        Task {
            await loadProducts()
            await refreshPurchases()
        }
    }

    func loadProducts() async {
        do {
            let ids = IAPProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleTransaction(transaction)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Satın alma beklemede."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Satın alma başarısız: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchases()
        } catch {
            errorMessage = "Geri yükleme başarısız."
        }
    }

    private func refreshPurchases() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            purchasedProductIDs.insert(transaction.productID)
        }
    }

    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        purchasedProductIDs.insert(transaction.productID)
        // Award jetons for products that include jeton bonus
        if let product = IAPProduct(rawValue: transaction.productID), product.jetonAmount > 0 {
            JetonManager.shared.earn(product.jetonAmount)
        }

        let ud = UserDefaults.standard
        switch transaction.productID {
        case IAPProduct.removeAds.rawValue:
            ud.set(true, forKey: "adsRemoved")
        case IAPProduct.sinemaPack.rawValue:
            ud.set(true, forKey: "pack_sinema_unlocked")
        case IAPProduct.bilimPack.rawValue:
            ud.set(true, forKey: "pack_bilim_unlocked")
        case IAPProduct.unlimitedLives.rawValue:
            ud.set(true, forKey: "pack_unlimited_lives_unlocked")
        case IAPProduct.themePackPremium.rawValue:
            ud.set(true, forKey: "pack_theme_premium_unlocked")
        case IAPProduct.tarihPlusPack.rawValue:
            ud.set(true, forKey: "pack_tarih_plus_unlocked")
        case IAPProduct.sporYildizlariPack.rawValue:
            ud.set(true, forKey: "pack_spor_yildizlari_unlocked")
        case IAPProduct.muzikProPack.rawValue:
            ud.set(true, forKey: "pack_muzik_pro_unlocked")
        case IAPProduct.premiumBundle.rawValue:
            // Bundle: tüm bayrakları aç
            ud.set(true, forKey: "adsRemoved")
            ud.set(true, forKey: "pack_sinema_unlocked")
            ud.set(true, forKey: "pack_bilim_unlocked")
            ud.set(true, forKey: "pack_unlimited_lives_unlocked")
            ud.set(true, forKey: "pack_theme_premium_unlocked")
            ud.set(true, forKey: "pack_tarih_plus_unlocked")
            ud.set(true, forKey: "pack_spor_yildizlari_unlocked")
            ud.set(true, forKey: "pack_muzik_pro_unlocked")
            ud.set(true, forKey: "pack_premium_bundle_unlocked")
        default:
            break
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - IAP Store View

struct IAPStoreView: View {
    @StateObject private var iap = IAPManager.shared
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("🛍️")
                                .font(.system(size: 60))
                            Text("Premium Mağaza")
                                .font(.title2.bold())
                                .foregroundColor(t.primaryText)

                            // Current balance
                            HStack(spacing: 5) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 10)).foregroundColor(.yellow)
                                Text("\(jetons.balance) jeton")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(t.primaryText)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.12), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.25), lineWidth: 1))
                        }
                        .padding(.top, 8)

                        if iap.isPurchasing {
                            ProgressView()
                                .padding()
                        } else if iap.products.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "wifi.slash")
                                    .font(.title2)
                                    .foregroundColor(t.secondaryText)
                                Text("Ürünler yüklenemedi")
                                    .font(.subheadline)
                                    .foregroundColor(t.secondaryText)
                                Button("Tekrar Dene") {
                                    Task { await iap.loadProducts() }
                                }
                                .foregroundColor(t.accent)
                            }
                            .padding(32)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(iap.products, id: \.id) { product in
                                    IAPProductRow(product: product, iap: iap, theme: t)
                                }
                            }
                            .padding(.horizontal)
                        }

                        if let err = iap.errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // MARK: Kelime Paketleri bölümü
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Text("📦")
                                    .font(.title3)
                                Text("Kelime Paketleri")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(t.primaryText)
                            }
                            .padding(.horizontal)

                            let packs: [(id: String, name: String, icon: String, desc: String, productId: String)] = [
                                ("sinema",          "Sinema Dünyası",     "🎬", "Film, yönetmen, senaryo, ödüller ve daha fazlası",      "com.fozzylabs.keligo.sinemaPack"),
                                ("bilim",           "Bilim & Teknoloji",  "🔬", "Algoritma, kuantum, galaksi, kimyasal terimler",         "com.fozzylabs.keligo.bilimPack"),
                                ("tarih_plus",      "Tarih+",             "📜", "Osmanlı, Bizans, Cumhuriyet dönemi özel kelimeleri",     "com.fozzylabs.keligo.tarihPlusPack"),
                                ("spor_yildizlari", "Spor Yıldızları",    "🏅", "Sporcu, takım, turnuva ve organizasyon isimleri",        "com.fozzylabs.keligo.sporYildizlariPack"),
                                ("muzik_pro",       "Müzik Pro",          "🎼", "Grup, albüm, çalgı, müzik teorisi terimleri",            "com.fozzylabs.keligo.muzikProPack"),
                            ]
                            ForEach(packs, id: \.id) { pack in
                                let isUnlocked = iap.isPackUnlocked(pack.id)
                                let product = iap.products.first(where: { $0.id == pack.productId })
                                HStack(spacing: 14) {
                                    Text(pack.icon)
                                        .font(.system(size: 30))
                                        .frame(width: 52, height: 52)
                                        .background(t.surface, in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(pack.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(t.primaryText)
                                            if isUnlocked {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .font(.caption)
                                                    .foregroundColor(t.correct)
                                            }
                                        }
                                        Text(pack.desc)
                                            .font(.caption)
                                            .foregroundColor(t.secondaryText)
                                    }
                                    Spacer()
                                    if isUnlocked {
                                        Image(systemName: "lock.open.fill")
                                            .foregroundColor(t.correct)
                                    } else if let product {
                                        Button {
                                            Task { await iap.purchase(product) }
                                        } label: {
                                            Text(product.displayPrice)
                                                .font(.subheadline.weight(.bold))
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(t.accentGradient, in: Capsule())
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                        .disabled(iap.isPurchasing)
                                    } else {
                                        ProgressView().scaleEffect(0.8)
                                    }
                                }
                                .padding(14)
                                .background(t.surface, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isUnlocked ? t.correct.opacity(0.35) : Color.clear, lineWidth: 1))
                                .padding(.horizontal)
                            }
                        }

                        Button("Satın Almaları Geri Yükle") {
                            Task { await iap.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                        .padding(.bottom, 32)
                    }
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

struct IAPProductRow: View {
    let product: Product
    @ObservedObject var iap: IAPManager
    let theme: AppTheme

    private var iapProduct: IAPProduct? { IAPProduct(rawValue: product.id) }

    private var emoji: String {
        switch iapProduct {
        case .jetons500:           return "🟡"
        case .jetons1500:          return "🟠"
        case .jetons5000:          return "💎"
        case .removeAds:           return "🚫"
        case .sinemaPack:          return "🎬"
        case .bilimPack:           return "🔬"
        case .unlimitedLives:      return "❤️"
        case .themePackPremium:    return "🎨"
        case .tarihPlusPack:       return "📜"
        case .sporYildizlariPack:  return "🏅"
        case .muzikProPack:        return "🎼"
        case .premiumBundle:       return "👑"
        case nil:                  return "🪙"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(iapProduct?.displayName ?? product.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.primaryText)
                let amount = iapProduct?.jetonAmount ?? 0
                if amount > 0 {
                    Text("\(amount) jeton hesabına eklenir")
                        .font(.caption).foregroundColor(theme.secondaryText)
                }
            }

            Spacer()

            Button {
                Task { await iap.purchase(product) }
            } label: {
                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(theme.accentGradient, in: Capsule())
                    .foregroundColor(.white)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(iap.isPurchasing)
        }
        .padding(14)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
