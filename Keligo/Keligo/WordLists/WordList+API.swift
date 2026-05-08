import Foundation

extension WordList {

    // MARK: - Pre-indexed lookups for O(1) access (computed once on first access)

    private static let _byCategory: [String: [WordEntry]] =
        Dictionary(grouping: words, by: \.category)

    private static let _difficultyIndex: [String: [WordEntry]] = {
        var result = [String: [WordEntry]]()
        for diff in Difficulty.allCases {
            let filtered = words.filter {
                $0.word.replacingOccurrences(of: " ", with: "").count >= diff.minWordLength &&
                $0.word.replacingOccurrences(of: " ", with: "").count <= diff.maxWordLength
            }
            result[diff.rawValue] = filtered.isEmpty ? words : filtered
        }
        return result
    }()

    private static let _catDiffIndex: [String: [String: [WordEntry]]] = {
        var result = [String: [String: [WordEntry]]]()
        for (cat, catWords) in _byCategory {
            for diff in Difficulty.allCases {
                let filtered = catWords.filter {
                    $0.word.replacingOccurrences(of: " ", with: "").count >= diff.minWordLength &&
                    $0.word.replacingOccurrences(of: " ", with: "").count <= diff.maxWordLength
                }
                result[cat, default: [:]][diff.rawValue] = filtered.isEmpty ? catWords : filtered
            }
        }
        return result
    }()

    // MARK: - Public API

    static var categories: [String] {
        Array(_byCategory.keys).sorted()
    }

    /// Premium kategoriler (IAP bağımsız listesi — picker bunları kilit ikonuyla gösterir).
    static let premiumCategories: [String] = ["Sinema", "Bilim+", "Tarih+", "Spor+", "Müzik+"]

    /// Premium kategorinin pack id eşleşmesi.
    static func packId(for premiumCategory: String) -> String? {
        switch premiumCategory {
        case "Sinema": return "sinema"
        case "Bilim+": return "bilim"
        case "Tarih+": return "tarih_plus"
        case "Spor+":  return "spor_yildizlari"
        case "Müzik+": return "muzik_pro"
        default:       return nil
        }
    }

    static func random(for difficulty: Difficulty = .normal, category: String? = nil) -> WordEntry {
        if let cat = category {
            let pool = _catDiffIndex[cat]?[difficulty.rawValue] ?? _byCategory[cat] ?? words
            return pool.randomElement() ?? words.first ?? WordEntry(word: "ELMA", category: "Meyveler")
        }
        let pool = _difficultyIndex[difficulty.rawValue] ?? words
        return pool.randomElement() ?? words.first ?? WordEntry(word: "ELMA", category: "Meyveler")
    }

    static func random(
        for difficulty: Difficulty = .normal,
        category: String? = nil,
        minLength: Int = 0,
        maxLength: Int = 99,
        kidsMode: Bool = false
    ) -> WordEntry {
        let effectiveMin = kidsMode ? 3 : minLength
        let effectiveMax = kidsMode ? 6 : maxLength

        // Premium packs — yalnızca açıksa havuza katılır
        var extraWords: [WordEntry] = []
        if IAPManager.shared.isPackUnlocked("sinema")          { extraWords += sinemaPack }
        if IAPManager.shared.isPackUnlocked("bilim")           { extraWords += bilimPack }
        if IAPManager.shared.isPackUnlocked("tarih_plus")      { extraWords += tarihPlusPack }
        if IAPManager.shared.isPackUnlocked("spor_yildizlari") { extraWords += sporYildizlariPack }
        if IAPManager.shared.isPackUnlocked("muzik_pro")       { extraWords += muzikProPack }

        var pool: [WordEntry]
        if let cat = category {
            // Premium kategoriler — sadece açıksa
            switch cat {
            case "Sinema"  where IAPManager.shared.isPackUnlocked("sinema"):          pool = sinemaPack
            case "Bilim+"  where IAPManager.shared.isPackUnlocked("bilim"):           pool = bilimPack
            case "Tarih+"  where IAPManager.shared.isPackUnlocked("tarih_plus"):      pool = tarihPlusPack
            case "Spor+"   where IAPManager.shared.isPackUnlocked("spor_yildizlari"): pool = sporYildizlariPack
            case "Müzik+"  where IAPManager.shared.isPackUnlocked("muzik_pro"):       pool = muzikProPack
            default:
                pool = (_catDiffIndex[cat]?[difficulty.rawValue] ?? _byCategory[cat] ?? words) + extraWords.filter { $0.category == cat }
            }
        } else {
            pool = (_difficultyIndex[difficulty.rawValue] ?? words) + extraWords
        }

        if effectiveMin > 0 || effectiveMax < 99 {
            let filtered = pool.filter {
                let len = $0.word.filter { $0 != " " }.count
                return len >= effectiveMin && len <= effectiveMax
            }
            pool = filtered.isEmpty ? pool : filtered
        }

        return pool.randomElement() ?? words.first ?? WordEntry(word: "ELMA", category: "Meyveler")
    }

    // MARK: - Hint lookup

    static func hint(for word: String) -> String? {
        hints[word.uppercased()]
    }
}
