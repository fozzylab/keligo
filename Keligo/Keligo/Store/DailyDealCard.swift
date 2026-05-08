import SwiftUI
import Combine

// MARK: - Daily Deal System

enum DealType {
    case jetonDiscount, hintBundle, themeDiscount, wordPackBundle
    
    var title: String {
        switch self {
        case .jetonDiscount: return "Jeton İndirimi"
        case .hintBundle: return "İpucu Paketi"
        case .themeDiscount: return "Tema İndirimi"
        case .wordPackBundle: return "Kelime Paketi"
        }
    }
    
    var subtitle: String {
        switch self {
        case .jetonDiscount: return "500 Jeton — %50 İndirimli"
        case .hintBundle: return "10 İpucu — Sadece bugün"
        case .themeDiscount: return "Premium Tema — %40 İndirim"
        case .wordPackBundle: return "2 Paket Bir Arada"
        }
    }
    
    var icon: String {
        switch self {
        case .jetonDiscount: return "circle.fill"
        case .hintBundle: return "lightbulb.fill"
        case .themeDiscount: return "paintbrush.fill"
        case .wordPackBundle: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .jetonDiscount: return .yellow
        case .hintBundle: return .orange
        case .themeDiscount: return .pink
        case .wordPackBundle: return .cyan
        }
    }
}

class DailyDealManager: ObservableObject {
    static let shared = DailyDealManager()
    
    @Published var currentDeal: DealType
    @Published var hoursRemaining: Int
    @Published var hasClaimed: Bool
    
    private let ud = UserDefaults.standard
    private let kDealDay = "dailyDeal_day"
    private let kClaimed = "dailyDeal_claimed"
    
    private init() {
        let today = Self.todayString()
        let savedDay = ud.string(forKey: kDealDay) ?? ""
        if savedDay != today {
            // New day — rotate deal
            ud.set(today, forKey: kDealDay)
            ud.set(false, forKey: kClaimed)
            currentDeal = Self.randomDeal()
            hasClaimed = false
        } else {
            currentDeal = Self.restoreDeal()
            hasClaimed = ud.bool(forKey: kClaimed)
        }
        hoursRemaining = Self.hoursUntilMidnight()
    }

    /// Call on foreground / onAppear to handle midnight rollover while app is running.
    func refreshIfNeeded() {
        let today = Self.todayString()
        let savedDay = ud.string(forKey: kDealDay) ?? ""
        guard savedDay != today else { return }
        ud.set(today, forKey: kDealDay)
        ud.set(false, forKey: kClaimed)
        currentDeal = Self.restoreDeal()
        hasClaimed = false
        hoursRemaining = Self.hoursUntilMidnight()
    }

    private static func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    
    static func randomDeal() -> DealType {
        let all: [DealType] = [.jetonDiscount, .hintBundle, .themeDiscount, .wordPackBundle]
        return all.randomElement() ?? .jetonDiscount
    }
    
    static func restoreDeal() -> DealType {
        // In a real app, persist the deal type. Here we just pick one deterministically by day.
        let day = Calendar.current.component(.day, from: Date())
        let all: [DealType] = [.jetonDiscount, .hintBundle, .themeDiscount, .wordPackBundle]
        return all[day % all.count]
    }
    
    static func hoursUntilMidnight() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let diff = calendar.dateComponents([.hour], from: now, to: midnight).hour ?? 0
        return max(0, diff)
    }
    
    func claim() {
        hasClaimed = true
        ud.set(true, forKey: kClaimed)
    }
}

// MARK: - Daily Deal Card View

struct DailyDealCard: View {
    @EnvironmentObject var settings: SettingsViewModel
    @StateObject private var deal = DailyDealManager.shared
    
    var t: AppTheme { settings.theme }
    
    var body: some View {
        Button {
            // Navigate to store or show deal sheet
            deal.claim()
        } label: {
            HStack(spacing: 14) {
                // Deal icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(deal.currentDeal.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: deal.currentDeal.icon)
                        .font(.title2)
                        .foregroundColor(deal.currentDeal.color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Bugünün Fırsatı")
                            .font(.caption.weight(.black))
                            .foregroundColor(deal.currentDeal.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(deal.currentDeal.color.opacity(0.12))
                            .cornerRadius(6)
                        
                        if deal.hasClaimed {
                            Text("Alındı ✓")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(t.correct)
                        }
                    }
                    
                    Text(deal.currentDeal.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Text(deal.currentDeal.subtitle)
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }
                
                Spacer()
                
                // Countdown
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                    Text("\(deal.hoursRemaining)sa")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(t.secondaryText)
                }
            }
            .padding(14)
            .glassSurface(cornerRadius: 18, intensity: 0.8, borderGlow: deal.currentDeal.color, innerGlow: true)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(deal.currentDeal.color.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(deal.hasClaimed)
        .opacity(deal.hasClaimed ? 0.6 : 1.0)
    }
}
