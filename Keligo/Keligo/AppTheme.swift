import SwiftUI

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:   return "Kolay"
        case .normal: return "Normal"
        case .hard:   return "Zor"
        }
    }

    var icon: String {
        switch self {
        case .easy:   return "😊"
        case .normal: return "🎯"
        case .hard:   return "💀"
        }
    }

    var maxWrongGuesses: Int {
        switch self {
        case .easy:   return 8
        case .normal: return 6
        case .hard:   return 4
        }
    }

    var hintCount: Int {
        switch self {
        case .easy:   return 3
        case .normal: return 2
        case .hard:   return 1
        }
    }

    var minWordLength: Int { self == .hard ? 7 : 0 }
    var maxWordLength: Int { self == .easy ? 5 : 99 }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case classic, ocean, forest, sunset, midnight
    case neon, galaxy, pastel, vintage, halloween, chalk

    var id: String { rawValue }

    var isPremium: Bool {
        switch self {
        case .neon, .galaxy, .pastel, .vintage, .halloween, .chalk: return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .classic:    return "Klasik"
        case .ocean:      return "Okyanus"
        case .forest:     return "Orman"
        case .sunset:     return "Gün Batımı"
        case .midnight:   return "Gece Yarısı"
        case .neon:       return "Neon"
        case .galaxy:     return "Galaksi"
        case .pastel:     return "Pastel"
        case .vintage:    return "Vintage"
        case .halloween:  return "Cadılar"
        case .chalk:      return "Tebeşir"
        }
    }

    var icon: String {
        switch self {
        case .classic:    return "☀️"
        case .ocean:      return "🌊"
        case .forest:     return "🌲"
        case .sunset:     return "🌅"
        case .midnight:   return "🌙"
        case .neon:       return "💜"
        case .galaxy:     return "🌌"
        case .pastel:     return "🌷"
        case .vintage:    return "📻"
        case .halloween:  return "🎃"
        case .chalk:      return "🖊️"
        }
    }

    /// Dark mod: tema tipine göre belirlenir.
    /// Classic, Pastel, Vintage = light; diğerleri = dark.
    /// NOT: System dark mode cardFill'a etki etmez. Kullanıcı dark tema seçmelidir.
    var isDark: Bool {
        switch self {
        case .classic, .pastel, .vintage: return false
        default: return true
        }
    }

    var background: Color {
        switch self {
        case .classic:
            return Color(.systemBackground)
        case .ocean:      return Color(red: 0.03, green: 0.07, blue: 0.20)
        case .forest:     return Color(red: 0.02, green: 0.11, blue: 0.05)
        case .sunset:     return Color(red: 0.14, green: 0.04, blue: 0.02)
        case .midnight:   return Color(red: 0.02, green: 0.02, blue: 0.09)
        case .neon:       return Color(red: 0.05, green: 0.02, blue: 0.12)
        case .galaxy:     return Color(red: 0.04, green: 0.03, blue: 0.18)
        case .pastel:     return Color(red: 0.98, green: 0.96, blue: 0.99)
        case .vintage:    return Color(red: 0.96, green: 0.92, blue: 0.84)
        case .halloween:  return Color(red: 0.08, green: 0.04, blue: 0.02)
        case .chalk:      return Color(red: 0.12, green: 0.20, blue: 0.14)
        }
    }

    /// Kart yüzey rengi — dark temalarda background'dan BELİRGİN şekilde daha açık,
    /// ama hâlâ koyu/koyu-gri tonlarda. Beyaza asla yaklaşmaz.
    var surface: Color {
        switch self {
        case .classic:    return Color(.secondarySystemBackground)
        case .ocean:      return Color(red: 0.08, green: 0.16, blue: 0.35)
        case .forest:     return Color(red: 0.08, green: 0.20, blue: 0.12)
        case .sunset:     return Color(red: 0.28, green: 0.12, blue: 0.05)
        case .midnight:   return Color(red: 0.10, green: 0.10, blue: 0.22)
        case .neon:       return Color(red: 0.12, green: 0.06, blue: 0.26)
        case .galaxy:     return Color(red: 0.10, green: 0.09, blue: 0.30)
        case .pastel:     return Color(red: 0.94, green: 0.90, blue: 0.96)
        case .vintage:    return Color(red: 0.90, green: 0.84, blue: 0.72)
        case .halloween:  return Color(red: 0.18, green: 0.09, blue: 0.03)
        case .chalk:      return Color(red: 0.16, green: 0.24, blue: 0.18)
        }
    }
    
    var primaryText: Color {
        switch self {
        case .chalk:   return Color(red: 0.94, green: 0.94, blue: 0.90)
        case .pastel:  return Color(red: 0.22, green: 0.10, blue: 0.32)
        case .vintage: return Color(red: 0.22, green: 0.14, blue: 0.06)
        case .classic: return Color(red: 0.95, green: 0.95, blue: 1.00)
        default:       return isDark ? .white : Color(red: 0.10, green: 0.10, blue: 0.12)
        }
    }

    var secondaryText: Color {
        switch self {
        case .chalk:   return Color(red: 0.94, green: 0.94, blue: 0.90).opacity(0.72)
        case .pastel:  return Color(red: 0.22, green: 0.10, blue: 0.32).opacity(0.65)
        case .vintage: return Color(red: 0.22, green: 0.14, blue: 0.06).opacity(0.65)
        case .classic: return Color(red: 0.95, green: 0.95, blue: 1.00).opacity(0.72)
        default:       return isDark ? Color.white.opacity(0.72) : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.60)
        }
    }

    /// Kart kenarlık rengi — dark temalar için ince beyaz, light'ta ince siyah
    var cardStroke: Color {
        isDark ? .white.opacity(0.13) : .black.opacity(0.07)
    }

    /// Kart gölgesi
    var cardShadow: Color {
        isDark ? .black.opacity(0.45) : .black.opacity(0.12)
    }

    var accent: Color {
        switch self {
        case .classic:    return Color(red: 0.20, green: 0.45, blue: 1.00)
        case .ocean:      return Color(red: 0.15, green: 0.85, blue: 1.00)
        case .forest:     return Color(red: 0.20, green: 0.95, blue: 0.45)
        case .sunset:     return Color(red: 1.00, green: 0.62, blue: 0.18)
        case .midnight:   return Color(red: 0.72, green: 0.38, blue: 1.00)
        case .neon:       return Color(red: 0.95, green: 0.18, blue: 0.95)
        case .galaxy:     return Color(red: 0.55, green: 0.55, blue: 1.00)
        case .pastel:     return Color(red: 1.00, green: 0.55, blue: 0.78)
        case .vintage:    return Color(red: 0.78, green: 0.42, blue: 0.20)
        case .halloween:  return Color(red: 1.00, green: 0.50, blue: 0.10)
        case .chalk:      return Color(red: 1.00, green: 0.94, blue: 0.65)
        }
    }

    var correct: Color {
        switch self {
        case .neon:       return Color(red: 0.20, green: 1.00, blue: 0.55)
        case .pastel:     return Color(red: 0.45, green: 0.85, blue: 0.55)
        case .halloween:  return Color(red: 0.50, green: 0.95, blue: 0.30)
        case .chalk:      return Color(red: 0.65, green: 0.95, blue: 0.65)
        default:          return Color(red: 0.18, green: 0.78, blue: 0.35)
        }
    }
    var wrong: Color {
        switch self {
        case .pastel:     return Color(red: 0.95, green: 0.45, blue: 0.55)
        case .halloween:  return Color(red: 0.95, green: 0.18, blue: 0.10)
        case .chalk:      return Color(red: 0.95, green: 0.50, blue: 0.50)
        default:          return Color(red: 0.95, green: 0.25, blue: 0.25)
        }
    }

    var glowColor: Color { accent.opacity(isDark ? 0.35 : 0.20) }

    var accentGradient: LinearGradient {
        switch self {
        case .classic:    return LinearGradient(colors: [Color(red: 0.20, green: 0.45, blue: 1.00), Color(red: 0.50, green: 0.70, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:      return LinearGradient(colors: [Color(red: 0.10, green: 0.70, blue: 1.00), Color(red: 0.15, green: 0.90, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:     return LinearGradient(colors: [Color(red: 0.10, green: 0.80, blue: 0.30), Color(red: 0.20, green: 0.95, blue: 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunset:     return LinearGradient(colors: [Color(red: 1.00, green: 0.40, blue: 0.10), Color(red: 1.00, green: 0.70, blue: 0.20)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .midnight:   return LinearGradient(colors: [Color(red: 0.55, green: 0.20, blue: 0.95), Color(red: 0.80, green: 0.45, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neon:       return LinearGradient(colors: [Color(red: 0.95, green: 0.18, blue: 0.95), Color(red: 0.10, green: 1.00, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .galaxy:     return LinearGradient(colors: [Color(red: 0.55, green: 0.30, blue: 1.00), Color(red: 0.20, green: 0.65, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastel:     return LinearGradient(colors: [Color(red: 1.00, green: 0.55, blue: 0.78), Color(red: 0.78, green: 0.55, blue: 1.00)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .vintage:    return LinearGradient(colors: [Color(red: 0.78, green: 0.42, blue: 0.20), Color(red: 0.65, green: 0.30, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .halloween:  return LinearGradient(colors: [Color(red: 1.00, green: 0.50, blue: 0.10), Color(red: 0.55, green: 0.10, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chalk:      return LinearGradient(colors: [Color(red: 1.00, green: 0.94, blue: 0.65), Color(red: 0.85, green: 0.75, blue: 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // NOTE: Never use iOS Material for cards — Material respects the SYSTEM color scheme,
    // not the app theme. Always use cardFill (explicit color) instead.
    var cardMaterial: Material { .ultraThinMaterial }   // Legacy; prefer cardFill

    /// Primary card fill — system dark mode'a otomatik uyum sağlar.
    /// Classic tema system dark mode'da koyu gri, light'ta beyaz görünür.
    /// Diğer dark temalar her zaman koyu renklerini korur.
    var cardFill: Color {
        switch self {
        case .classic:
            // Classic: system dark/light mode'a otomatik uyum
            return Color(.secondarySystemBackground)
        case .ocean:      return Color(red: 0.10, green: 0.20, blue: 0.38)
        case .forest:     return Color(red: 0.10, green: 0.22, blue: 0.14)
        case .sunset:     return Color(red: 0.32, green: 0.14, blue: 0.06)
        case .midnight:   return Color(red: 0.12, green: 0.12, blue: 0.26)
        case .neon:       return Color(red: 0.16, green: 0.08, blue: 0.30)
        case .galaxy:     return Color(red: 0.14, green: 0.12, blue: 0.34)
        case .pastel:     return Color(red: 0.94, green: 0.90, blue: 0.96)
        case .vintage:    return Color(red: 0.90, green: 0.84, blue: 0.72)
        case .halloween:  return Color(red: 0.22, green: 0.10, blue: 0.04)
        case .chalk:      return Color(red: 0.20, green: 0.30, blue: 0.22)
        }
    }

    /// Slightly more elevated card (selected / featured items)
    var cardFillElevated: Color {
        switch self {
        case .classic:
            return Color(.tertiarySystemBackground)
        case .ocean:      return Color(red: 0.14, green: 0.26, blue: 0.44)
        case .forest:     return Color(red: 0.14, green: 0.28, blue: 0.18)
        case .sunset:     return Color(red: 0.38, green: 0.18, blue: 0.08)
        case .midnight:   return Color(red: 0.16, green: 0.16, blue: 0.30)
        case .neon:       return Color(red: 0.20, green: 0.12, blue: 0.34)
        case .galaxy:     return Color(red: 0.18, green: 0.16, blue: 0.38)
        case .pastel:     return Color(red: 0.96, green: 0.92, blue: 0.98)
        case .vintage:    return Color(red: 0.92, green: 0.86, blue: 0.76)
        case .halloween:  return Color(red: 0.28, green: 0.14, blue: 0.06)
        case .chalk:      return Color(red: 0.24, green: 0.34, blue: 0.26)
        }
    }

    // MARK: - 2026: Ambient MeshGradient Backgrounds
    
    @ViewBuilder
    func ambientBackground(for category: String? = nil) -> some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3, height: 3,
                points: meshPoints(for: category),
                colors: meshColors(for: category)
            )
            .ignoresSafeArea()
            .overlay(background.opacity(0.3).ignoresSafeArea())
        } else {
            background.ignoresSafeArea()
        }
    }
    
    private func meshPoints(for category: String?) -> [SIMD2<Float>] {
        // Animated organic mesh points
        let base: [SIMD2<Float>] = [
            .init(x: 0.0, y: 0.0), .init(x: 0.5, y: 0.0), .init(x: 1.0, y: 0.0),
            .init(x: 0.0, y: 0.5), .init(x: Float.random(in: 0.3...0.7), y: Float.random(in: 0.3...0.7)), .init(x: 1.0, y: 0.5),
            .init(x: 0.0, y: 1.0), .init(x: 0.5, y: 1.0), .init(x: 1.0, y: 1.0)
        ]
        return base
    }
    
    private func meshColors(for category: String?) -> [Color] {
        switch category {
        case "Uzay", "Bilim", "Teknoloji":
            return [.purple.opacity(0.4), .indigo.opacity(0.3), .black,
                    .blue.opacity(0.3), .purple.opacity(0.2), .indigo.opacity(0.4),
                    .black, .blue.opacity(0.2), .purple.opacity(0.3)]
        case "Hayvanlar", "Doğa", "Bitkiler":
            return [.green.opacity(0.3), .teal.opacity(0.2), .black,
                    .mint.opacity(0.2), .green.opacity(0.15), .teal.opacity(0.3),
                    .black, .mint.opacity(0.15), .green.opacity(0.25)]
        case "Spor":
            return [.orange.opacity(0.3), .red.opacity(0.2), .black,
                    .yellow.opacity(0.2), .orange.opacity(0.15), .red.opacity(0.3),
                    .black, .yellow.opacity(0.15), .orange.opacity(0.25)]
        case "Tarih", "Mitoloji":
            return [.brown.opacity(0.3), .orange.opacity(0.2), .black,
                    .yellow.opacity(0.15), .brown.opacity(0.2), .orange.opacity(0.25),
                    .black, .yellow.opacity(0.1), .brown.opacity(0.2)]
        default:
            return [accent.opacity(0.2), accent.opacity(0.1), background,
                    accent.opacity(0.15), background.opacity(0.5), accent.opacity(0.25),
                    background, accent.opacity(0.1), accent.opacity(0.2)]
        }
    }
    
    // MARK: - 2026 Spatial Helpers
    
    var spatialShadow: Color {
        isDark ? Color.black.opacity(0.45) : Color.black.opacity(0.18)
    }
    
    var glassHighlight: Color {
        isDark ? Color.white.opacity(0.15) : Color.white.opacity(0.55)
    }
    
    var glassBorder: Color {
        isDark ? accent.opacity(0.25) : accent.opacity(0.18)
    }
    
    var ambientMood: AmbientMood {
        switch self {
        case .ocean, .midnight, .galaxy: return .focused
        case .sunset: return .urgent
        case .neon: return .celebratory
        case .forest, .classic: return .calm
        case .pastel: return .zen
        case .vintage, .chalk: return .mysterious
        case .halloween: return .urgent
        }
    }
}

enum KeyboardStyle: String, CaseIterable, Identifiable {
    case glass    = "glass"
    case flat     = "flat"
    case minimal  = "minimal"
    case colorful = "colorful"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glass:    return "Cam"
        case .flat:     return "Düz"
        case .minimal:  return "Minimal"
        case .colorful: return "Renkli"
        }
    }

    var icon: String {
        switch self {
        case .glass:    return "⬜"
        case .flat:     return "🔲"
        case .minimal:  return "⬛"
        case .colorful: return "🌈"
        }
    }
}