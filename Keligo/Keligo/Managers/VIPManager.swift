import Foundation
import Combine

// MARK: - VIP Monthly Pass Manager

class VIPManager: ObservableObject {
    static let shared = VIPManager()
    
    @Published var isVIP: Bool {
        didSet { ud.set(isVIP, forKey: "vip_isActive") }
    }
    @Published var expiryDate: Date? {
        didSet {
            if let date = expiryDate {
                ud.set(date.timeIntervalSince1970, forKey: "vip_expiry")
            } else {
                ud.removeObject(forKey: "vip_expiry")
            }
        }
    }
    
    private let ud = UserDefaults.standard
    
    private init() {
        isVIP = ud.bool(forKey: "vip_isActive")
        if let ts = ud.object(forKey: "vip_expiry") as? TimeInterval {
            expiryDate = Date(timeIntervalSince1970: ts)
        }
        validateStatus()
    }
    
    func validateStatus() {
        guard isVIP, let expiry = expiryDate else { return }
        if Date() > expiry {
            isVIP = false
            expiryDate = nil
        }
    }
    
    func activateVIP(for days: Int = 30) {
        isVIP = true
        expiryDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
    }
    
    func cancelVIP() {
        isVIP = false
        expiryDate = nil
    }
    
    var remainingDays: Int {
        guard let expiry = expiryDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return max(0, days)
    }
    
    var formattedExpiry: String {
        guard let expiry = expiryDate else { return "Aktif değil" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: expiry)
    }
    
    // MARK: - VIP Benefits
    
    var jetonMultiplier: Double { isVIP ? 1.5 : 1.0 }
    var dailyLoginMultiplier: Double { isVIP ? 2.0 : 1.0 }
    var hasUnlimitedLives: Bool { isVIP }
    var hasNoInterstitials: Bool { isVIP }
}
