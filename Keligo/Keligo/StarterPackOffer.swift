import SwiftUI
import Combine

// MARK: - Starter Pack Manager

class StarterPackManager: ObservableObject {
    static let shared = StarterPackManager()
    
    @Published var isVisible: Bool = false
    @Published var hoursRemaining: Int = 24
    
    private let ud = UserDefaults.standard
    private let kGamesPlayed = "starterPack_gamesPlayed"
    private let kShown = "starterPack_shown"
    private let kExpiry = "starterPack_expiry"
    
    private init() {
        checkVisibility()
    }
    
    func recordGamePlayed() {
        let count = ud.integer(forKey: kGamesPlayed) + 1
        ud.set(count, forKey: kGamesPlayed)
        if count >= 3 && !ud.bool(forKey: kShown) {
            triggerOffer()
        }
    }
    
    private func triggerOffer() {
        ud.set(true, forKey: kShown)
        let expiry = Date().addingTimeInterval(24 * 3600)
        ud.set(expiry.timeIntervalSince1970, forKey: kExpiry)
        isVisible = true
        updateHoursRemaining()
    }
    
    func checkVisibility() {
        guard ud.bool(forKey: kShown) else { isVisible = false; return }
        guard let expiry = ud.object(forKey: kExpiry) as? TimeInterval else { isVisible = false; return }
        isVisible = Date().timeIntervalSince1970 < expiry
        if isVisible { updateHoursRemaining() }
    }
    
    private func updateHoursRemaining() {
        guard let expiry = ud.object(forKey: kExpiry) as? TimeInterval else { return }
        let remaining = Int(expiry - Date().timeIntervalSince1970)
        hoursRemaining = max(0, remaining / 3600)
    }
    
    func dismiss() {
        isVisible = false
    }
    
    func purchase() {
        // In real app: trigger StoreKit purchase
        JetonManager.shared.earn(1000)
        isVisible = false
        ud.set(false, forKey: kShown) // Prevent re-show
    }
}

// MARK: - Starter Pack View

struct StarterPackView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @StateObject private var pack = StarterPackManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var t: AppTheme { settings.theme }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Badge
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                    Text("YENİ OYUNCU ÖZEL")
                        .font(.caption.weight(.black))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(8)
                
                // Title
                Text("Başlangıç Paketi")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                // Contents
                VStack(spacing: 14) {
                    starterItem(icon: "circle.fill", iconColor: .yellow, title: "1,000 Jeton", subtitle: "Hemen kullan")
                    starterItem(icon: "lightbulb.fill", iconColor: .orange, title: "10 İpucu", subtitle: "Zor kelimelerde yardım")
                    starterItem(icon: "paintbrush.fill", iconColor: .pink, title: "Özel Tema", subtitle: "Sadece bu pakette")
                }
                .padding(.vertical, 8)
                
                // Price
                HStack(spacing: 8) {
                    Text("₺29.99")
                        .font(.subheadline)
                        .strikethrough()
                        .foregroundColor(.white.opacity(0.5))
                    Text("₺9.99")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.yellow)
                }
                
                // CTA
                Button {
                    pack.purchase()
                } label: {
                    Text("Satın Al")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .foregroundColor(.black)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Timer
                Text("Teklif bitimine: \(pack.hoursRemaining) saat")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Button {
                    pack.dismiss()
                } label: {
                    Text("Şimdilik Geç")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(24)
            .modifier(GlassSurface(cornerRadius: 28, intensity: 0.9, borderGlow: .yellow, innerGlow: true))
            .padding(.horizontal, 24)
        }
    }
    
    private func starterItem(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
    }
}
