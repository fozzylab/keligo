import Foundation
import Combine

// MARK: - Season & Battle Pass System

struct SeasonReward: Identifiable {
    let id = UUID()
    let tier: Int
    let xpRequired: Int
    let freeReward: String
    let freeRewardIcon: String
    let premiumReward: String
    let premiumRewardIcon: String
    let isPremiumTheme: Bool
}

class SeasonManager: ObservableObject {
    static let shared = SeasonManager()
    
    @Published var currentXP: Int {
        didSet { ud.set(currentXP, forKey: seasonKey("xp")) }
    }
    @Published var isPremiumPass: Bool {
        didSet { ud.set(isPremiumPass, forKey: seasonKey("premium")) }
    }
    @Published var seasonID: String {
        didSet { ud.set(seasonID, forKey: "season_currentID") }
    }
    
    private let ud = UserDefaults.standard
    private let seasonDurationDays = 30
    
    private init() {
        let id = ud.string(forKey: "season_currentID") ?? Self.generateSeasonID()
        seasonID = id
        currentXP = ud.integer(forKey: "season_\(id)_xp")
        isPremiumPass = ud.bool(forKey: "season_\(id)_premium")
        checkSeasonReset()
    }
    
    static func generateSeasonID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private func seasonKey(_ suffix: String) -> String {
        "season_\(seasonID)_\(suffix)"
    }
    
    func checkSeasonReset() {
        let savedID = ud.string(forKey: "season_currentID") ?? ""
        let currentID = Self.generateSeasonID()
        if savedID != currentID {
            // New season — reset progress
            seasonID = currentID
            currentXP = 0
            isPremiumPass = false
        }
    }
    
    func addXP(_ amount: Int) {
        currentXP += amount
    }
    
    func unlockPremium() {
        isPremiumPass = true
    }
    
    var currentTier: Int {
        rewards.lastIndex(where: { $0.xpRequired <= currentXP }) ?? 0
    }
    
    var maxTier: Int { rewards.count }
    
    var progressToNext: Double {
        let next = rewards.first(where: { $0.xpRequired > currentXP })
        guard let next = next else { return 1.0 }
        let prevXP = rewards.first(where: { $0.tier == next.tier - 1 })?.xpRequired ?? 0
        let range = Double(next.xpRequired - prevXP)
        let current = Double(currentXP - prevXP)
        return min(1.0, max(0.0, current / range))
    }
    
    var seasonName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: Date())
    }
    
    // MARK: - Reward Track (20 tiers)
    
    let rewards: [SeasonReward] = [
        SeasonReward(tier: 1, xpRequired: 0, freeReward: "100 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 2, xpRequired: 50, freeReward: "1 İpucu", freeRewardIcon: "lightbulb.fill", premiumReward: "250 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 3, xpRequired: 120, freeReward: "50 Jeton", freeRewardIcon: "circle.fill", premiumReward: "2 İpucu", premiumRewardIcon: "lightbulb.fill", isPremiumTheme: false),
        SeasonReward(tier: 4, xpRequired: 200, freeReward: "1 Can", freeRewardIcon: "heart.fill", premiumReward: "500 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 5, xpRequired: 300, freeReward: "Tema: Orman", freeRewardIcon: "leaf.fill", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 6, xpRequired: 420, freeReward: "100 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Kelime Paketi", premiumRewardIcon: "book.fill", isPremiumTheme: false),
        SeasonReward(tier: 7, xpRequired: 560, freeReward: "2 İpucu", freeRewardIcon: "lightbulb.fill", premiumReward: "750 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 8, xpRequired: 720, freeReward: "50 Jeton", freeRewardIcon: "circle.fill", premiumReward: "2 Can", premiumRewardIcon: "heart.fill", isPremiumTheme: false),
        SeasonReward(tier: 9, xpRequired: 900, freeReward: "1 İpucu", freeRewardIcon: "lightbulb.fill", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 10, xpRequired: 1100, freeReward: "200 Jeton", freeRewardIcon: "circle.fill", premiumReward: "1000 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 11, xpRequired: 1320, freeReward: "1 Can", freeRewardIcon: "heart.fill", premiumReward: "Kelime Paketi", premiumRewardIcon: "book.fill", isPremiumTheme: false),
        SeasonReward(tier: 12, xpRequired: 1560, freeReward: "100 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 13, xpRequired: 1820, freeReward: "2 İpucu", freeRewardIcon: "lightbulb.fill", premiumReward: "1500 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 14, xpRequired: 2100, freeReward: "50 Jeton", freeRewardIcon: "circle.fill", premiumReward: "3 Can", premiumRewardIcon: "heart.fill", isPremiumTheme: false),
        SeasonReward(tier: 15, xpRequired: 2400, freeReward: "Tema: Okyanus", freeRewardIcon: "water.waves", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 16, xpRequired: 2720, freeReward: "250 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Kelime Paketi", premiumRewardIcon: "book.fill", isPremiumTheme: false),
        SeasonReward(tier: 17, xpRequired: 3060, freeReward: "1 İpucu", freeRewardIcon: "lightbulb.fill", premiumReward: "2000 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 18, xpRequired: 3420, freeReward: "100 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Özel Tema", premiumRewardIcon: "paintbrush.fill", isPremiumTheme: true),
        SeasonReward(tier: 19, xpRequired: 3800, freeReward: "2 Can", freeRewardIcon: "heart.fill", premiumReward: "3000 Jeton", premiumRewardIcon: "circle.fill", isPremiumTheme: false),
        SeasonReward(tier: 20, xpRequired: 4200, freeReward: "500 Jeton", freeRewardIcon: "circle.fill", premiumReward: "Efsanevi Tema", premiumRewardIcon: "crown.fill", isPremiumTheme: true),
    ]
}
