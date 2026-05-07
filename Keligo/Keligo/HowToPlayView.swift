import SwiftUI

// MARK: - How To Play

struct HowToPlayView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero
                        VStack(spacing: 10) {
                            // Keligo mini logo — harf kutuları
                            VStack(spacing: 5) {
                                HStack(spacing: 5) {
                                    ForEach(["K","E","L"], id: \.self) { letter in
                                        HowToLetterTile(letter: letter, accent: t.accent)
                                    }
                                }
                                HStack(spacing: 5) {
                                    ForEach(["İ","G","O"], id: \.self) { letter in
                                        HowToLetterTile(letter: letter, accent: t.accent)
                                    }
                                }
                            }
                            .padding(.bottom, 4)

                            Text("Nasıl Oynanır?")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(t.primaryText)
                            Text("Türkçe kelime tahmin oyunu — harfleri keşfet!")
                                .font(.subheadline)
                                .foregroundColor(t.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Rules
                        ruleSection(
                            icon: "🎯",
                            title: "Amaç",
                            color: .blue,
                            items: [
                                "Ekranda gizlenmiş bir kelime var.",
                                "Harf tahmin ederek kelimeyi bulmaya çalış.",
                                "Tüm harfleri bulmadan önce 6 yanlış yapma!"
                            ]
                        )

                        ruleSection(
                            icon: "🔤",
                            title: "Nasıl Oynanır?",
                            color: .green,
                            items: [
                                "Klavyeden bir harf seç.",
                                "Doğruysa: harf kelimede yerini alır ✅",
                                "Yanlışsa: adam bir adım ilerler ❌",
                                "6 yanlış → oyun bitti! 💀"
                            ]
                        )

                        ruleSection(
                            icon: "💡",
                            title: "İpuçları (Power-Up'lar)",
                            color: .orange,
                            items: [
                                "Kategori her zaman görünür — ipucu olarak kullan.",
                                "Harf sayısı çizgilerle gösterilir.",
                                "İpucu: kelimeyi anlatan kısa cümle (50 🟡)",
                                "Sesli Harf Al: tüm sesli harfleri açar (200 🟡)",
                                "Harf Al: rastgele doğru harf (100 🟡)",
                                "Geri Al: son tahmini geri al (75 🟡)",
                                "Pas: kelimeyi atla (50 🟡)"
                            ]
                        )

                        ruleSection(
                            icon: "❤️",
                            title: "Can Sistemi",
                            color: .pink,
                            items: [
                                "Toplam 5 canın var — Sonsuz ve Çocuk modunda kayıp = -1 can.",
                                "Her 30 dakikada 1 can otomatik dolar.",
                                "Canlar bittiğinde: bekle, reklam izle (+1) veya 50/200 jetonla doldur.",
                                "Daily / Bölüm / Hız modu canı etkilemez.",
                                "Sınırsız Can (IAP) ile tek seferlik sonsuza dek özgür ol."
                            ]
                        )

                        ruleSection(
                            icon: "📺",
                            title: "Reklamlar (Ücretsiz Ödüller)",
                            color: .indigo,
                            items: [
                                "Reklam izle, kelimeden 1 doğru harf aç (5/gün).",
                                "Reklam izle, +1 can yenile (3/gün).",
                                "Reklam izle, +25 jeton günlük bonus (1/gün — ana menüde).",
                                "Daily kayıpta seriyi reklam ile kurtar (1/gün).",
                                "İstersen \"Reklamları Kaldır\" IAP ile interstitial'lar kaybolur — rewarded'lar kalır."
                            ]
                        )

                        ruleSection(
                            icon: "🏆",
                            title: "Puanlama",
                            color: .yellow,
                            items: [
                                "Kazanma: +15 Jeton, +20 XP",
                                "Günlük Kelime: +25 Jeton bonus",
                                "Az hatayla bitirince: bonus XP",
                                "Her 5 galibiyet serisi: +50 Jeton",
                                "Streak milestones: 3→30, 7→100, 14→250, 30→600, 50→1000, 100→2000 🟡",
                                "Kaybetsen bile: +5 XP"
                            ]
                        )

                        ruleSection(
                            icon: "🔥",
                            title: "Seri (Streak)",
                            color: .red,
                            items: [
                                "Her kazandığında serisi artar.",
                                "Kaybedersen seri sıfırlanır.",
                                "Seri Koruma (75 🟡) ile günde 1 kez serini kurtar!",
                                "Reklamla seri kurtarma — ücretsiz alternatif (1/gün).",
                                "Günlük login serisi: 1-7. günler arası artan jeton ödülü."
                            ]
                        )

                        ruleSection(
                            icon: "🗂️",
                            title: "Oyun Modları",
                            color: .purple,
                            items: [
                                "📅 Günlük Kelime + Takvim — her gün 1 kelime, geçmişe bak",
                                "∞ Sonsuz Mod — kategori seç, can ile oyna",
                                "📖 Bölüm Modu — sıralı bölümler, yıldız kazan",
                                "⚡️ Hız Modu — 30/60/90 sn'de kaç kelime?",
                                "🧒 Çocuk Modu — kısa ve kolay kelimeler",
                                "📆 Haftalık Meydan Okuma — 7 gün, 400 🟡 ödül",
                                "👥 Arkadaşa Sor — kod paylaş, tahmin ettir"
                            ]
                        )

                        ruleSection(
                            icon: "💎",
                            title: "Premium Paketler",
                            color: .yellow,
                            items: [
                                "🎬 Sinema · 🔬 Bilim+ · 📜 Tarih+ · 🏆 Spor+ · 🎼 Müzik+ — her biri 60+ niş kelime",
                                "🎨 Premium Tema Paketi — Neon, Galaksi, Pastel, Vintage, Cadılar",
                                "❤️ Sınırsız Can — bir daha bekleme",
                                "👑 Premium Paket (Bundle) — hepsi + 5000 jeton, %50 tasarruf",
                                "Mevcut 21 kategori daima ücretsiz — premium = ekstra çeşit."
                            ]
                        )

                        // Türkçe özel harfler uyarısı
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Text("🇹🇷").font(.title3)
                                Text("Türkçe Harfler")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(t.primaryText)
                            }
                            Text("Ç, Ğ, İ, Ö, Ş, Ü gibi Türkçe özel harflere dikkat et!\nBunlar farklı harfler — İ ile I aynı değil!")
                                .font(.caption)
                                .foregroundColor(t.secondaryText)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))

                        // Close button
                        Button {
                            dismiss()
                        } label: {
                            Text("Anladım, Oynayalım! 🎮")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 18))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Oyun Kuralları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(t.accentGradient)
                    }
                }
            }
        }
    }

    // MARK: - Rule section builder

    private func ruleSection(icon: String, title: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(icon).font(.title3)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(t.primaryText)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(t.secondaryText)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Mini letter tile (only for HowToPlayView hero)
private struct HowToLetterTile: View {
    let letter: String
    let accent: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [accent, accent.opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 38)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: accent.opacity(0.45), radius: 6, y: 2)
            Text(letter)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    HowToPlayView()
        .environmentObject(SettingsViewModel())
}
