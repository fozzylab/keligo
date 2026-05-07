import Foundation

struct WordEntry {
    let word: String
    let category: String
}

enum WordList {

    // MARK: - Free words (all categories combined)
    static let words: [WordEntry] =
        hayvanlarWords + mesleklerWords + yiyeceklerWords +
        sehirlerWords + sporWords + dogaWords +
        teknolojiWords + muzikWords + bilimWords +
        ulkelerWords + mitolojiWords + meyvelerWords +
        sebzelerWords + tasitlarWords + uzayWords +
        sanatWords + tarihWords + bitkilerWords +
        cografyaWords + markalarWords + gunlukWords

    // MARK: - Premium packs
    static let bilimPack:           [WordEntry] = bilimPlusWords
    static let tarihPlusPack:       [WordEntry] = tarihPlusWords
    static let sporYildizlariPack:  [WordEntry] = sporPlusWords
    static let muzikProPack:        [WordEntry] = muzikPlusWords
    static let sinemaPack:          [WordEntry] = sinemaPlusWords

    // MARK: - Hints (all categories combined)
    static let hints: [String: String] = {
        var h: [String: String] = [:]
        for dict in [
            hayvanlarHints, mesleklerHints, yiyeceklerHints,
            sehirlerHints, sporHints, dogaHints,
            teknolojiHints, muzikHints, bilimHints,
            ulkelerHints, mitolojiHints, meyvelerHints,
            sebzelerHints, tasitlarHints, uzayHints,
            sanatHints, tarihHints, bitkilerHints,
            cografyaHints, markalarHints, gunlukHints,
            bilimPlusHints, tarihPlusHints, sporPlusHints,
            muzikPlusHints, sinemaPlusHints,
        ] { h.merge(dict) { $1 } }
        return h
    }()
}
