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
    // Free / unlock-able
    case classic, ocean, forest, sunset, midnight
    // Premium (themePackPremium IAP)
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

    var isDark: Bool {
        switch self {
        case .classic, .pastel, .vintage: return false
        default: return true  // includes chalk (dark chalkboard)
        }
    }

    // MARK: - Base colors

    var background: Color {
        switch self {
        case .classic:    return Color(.systemBackground)
        case .ocean:      return Color(red: 0.03, green: 0.07, blue: 0.20)
        case .forest:     return Color(red: 0.02, green: 0.11, blue: 0.05)
        case .sunset:     return Color(red: 0.14, green: 0.04, blue: 0.02)
        case .midnight:   return Color(red: 0.02, green: 0.02, blue: 0.09)
        case .neon:       return Color(red: 0.05, green: 0.02, blue: 0.12)
        case .galaxy:     return Color(red: 0.04, green: 0.03, blue: 0.18)
        case .pastel:     return Color(red: 0.98, green: 0.96, blue: 0.99)
        case .vintage:    return Color(red: 0.96, green: 0.92, blue: 0.84)
        case .halloween:  return Color(red: 0.08, green: 0.04, blue: 0.02)
        case .chalk:      return Color(red: 0.12, green: 0.20, blue: 0.14)  // dark chalkboard green
        }
    }

    var surface: Color {
        switch self {
        case .classic:    return Color(.secondarySystemBackground)
        case .ocean:      return Color(red: 0.08, green: 0.22, blue: 0.42)
        case .forest:     return Color(red: 0.08, green: 0.24, blue: 0.12)
        case .sunset:     return Color(red: 0.30, green: 0.12, blue: 0.06)
        case .midnight:   return Color(red: 0.10, green: 0.10, blue: 0.24)
        case .neon:       return Color(red: 0.14, green: 0.06, blue: 0.28)
        case .galaxy:     return Color(red: 0.12, green: 0.10, blue: 0.34)
        case .pastel:     return Color(red: 0.94, green: 0.90, blue: 0.96)
        case .vintage:    return Color(red: 0.90, green: 0.84, blue: 0.72)
        case .halloween:  return Color(red: 0.20, green: 0.10, blue: 0.04)
        case .chalk:      return Color(red: 0.20, green: 0.30, blue: 0.22)  // raised chalkboard panel
        }
    }

    var primaryText: Color {
        switch self {
        case .chalk: return Color(red: 0.94, green: 0.94, blue: 0.90)  // chalk white (slightly warm)
        default:     return isDark ? .white : Color(.label)
        }
    }

    var secondaryText: Color {
        switch self {
        case .chalk: return Color(red: 0.94, green: 0.94, blue: 0.90).opacity(0.60)
        default:     return isDark ? Color.white.opacity(0.55) : Color(.secondaryLabel)
        }
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
        case .chalk:      return Color(red: 1.00, green: 0.94, blue: 0.65)  // yellow chalk accent
        }
    }

    var correct: Color {
        switch self {
        case .neon:       return Color(red: 0.20, green: 1.00, blue: 0.55)
        case .pastel:     return Color(red: 0.45, green: 0.85, blue: 0.55)
        case .halloween:  return Color(red: 0.50, green: 0.95, blue: 0.30)
        case .chalk:      return Color(red: 0.65, green: 0.95, blue: 0.65)  // green chalk
        default:          return Color(red: 0.18, green: 0.78, blue: 0.35)
        }
    }
    var wrong: Color {
        switch self {
        case .pastel:     return Color(red: 0.95, green: 0.45, blue: 0.55)
        case .halloween:  return Color(red: 0.95, green: 0.18, blue: 0.10)
        case .chalk:      return Color(red: 0.95, green: 0.50, blue: 0.50)  // pink/red chalk
        default:          return Color(red: 0.95, green: 0.25, blue: 0.25)
        }
    }

    // MARK: - Gradient helpers

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

    var cardMaterial: Material {
        isDark ? .ultraThinMaterial : .regularMaterial
    }
}

// MARK: - Keyboard Style

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
