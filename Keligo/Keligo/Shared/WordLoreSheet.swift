import SwiftUI

// MARK: - Word Lore (Trivia after solving)

struct WordLoreSheet: View {
    let word: String
    let category: String
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    private var loreText: String {
        // In a real app, this would come from a curated database or AI.
        // Here we generate contextually relevant placeholder trivia.
        WordLoreDatabase.lore(for: word, category: category)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Word display
                        VStack(spacing: 8) {
                            Text(word)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(theme.primaryText)
                            Text(category)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(theme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(theme.accent.opacity(0.12))
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                        
                        // Lore card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.accent)
                                Text("Kelimenin Hikayesi")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(theme.primaryText)
                            }
                            
                            Text(loreText)
                                .font(.body)
                                .foregroundColor(theme.secondaryText)
                                .lineSpacing(5)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassSurface(cornerRadius: 20, intensity: 0.8, borderGlow: theme.accent, innerGlow: true)
                        
                        // Fun fact
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title3)
                                    .foregroundColor(.yellow)
                                Text("Biliyor muydun?")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(theme.primaryText)
                            }
                            Text(WordLoreDatabase.funFact(for: word))
                                .font(.body)
                                .foregroundColor(theme.secondaryText)
                                .lineSpacing(5)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassSurface(cornerRadius: 20, intensity: 0.8, borderGlow: .yellow, innerGlow: true)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Harika!")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 18))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Kelime Bilgisi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(theme.accentGradient)
                    }
                }
            }
        }
    }
}

// MARK: - Mock Lore Database

enum WordLoreDatabase {
    static func lore(for word: String, category: String) -> String {
        let lower = word.lowercased()
        switch lower {
        case let w where w.contains("deniz"):
            return "Deniz, Türkçede geniş su kütlesini ifade eder. Eski Türkçe 'tengiz' kelimesinden gelmektedir ve Moğolca'da da aynı anlamı taşır."
        case let w where w.contains("güneş"):
            return "Güneş, güneş sistemimizin merkezindeki yıldızdır. Türk mitolojisinde Güneş kadın bir tanrıça olarak personifleştirilmiştir."
        case let w where w.contains("kitap"):
            return "Kitap kelimesi Arapça 'kütüb' kökünden gelir. Günümüzde bilginin en önemli taşıyıcılarından biridir."
        default:
            return "\"\(word)\" kelimesi \(category) kategorisinde önemli bir yer tutar. Bu kelime Türkçede sıkça kullanılan ve zengin bir anlam dünyasına sahip olan sözcüklerden biridir."
        }
    }
    
    static func funFact(for word: String) -> String {
        let lower = word.lowercased()
        if lower.count > 8 {
            return "Bu kelime \(lower.count) harf içeriyor — uzun kelimeler Türkçede çok yaygındır ve eklerle daha da uzayabilir!"
        }
        if lower.contains("ç") || lower.contains("ş") || lower.contains("ğ") {
            return "Bu kelime Türkçeye özgü harfler içeriyor. Türkçe, dünya üzerindeki en zengin söyleniş yapısına sahip dillerden biridir."
        }
        return "Türkçe yaklaşık 80.000 kelimeden oluşan kök bir dile sahiptir ve eklerle milyonlarca farklı kelime üretilebilir."
    }
}
