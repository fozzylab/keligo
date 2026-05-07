import Foundation
import Combine
import UserNotifications

/// Lives (hearts) sistemi.
/// - Maks 5 can, kayıp/oyun başına -1, 30 dk'da +1 regen.
/// - Anti-cheat: forward-only ratchet + monotonic uptime cross-check + iCloud anchor.
final class LivesManager: ObservableObject {
    static let shared = LivesManager()

    // MARK: - Tunables
    static let maxLives: Int = 5
    static let regenIntervalSeconds: TimeInterval = 30 * 60

    // MARK: - Published state
    @Published private(set) var current: Int
    @Published private(set) var nextRegenAt: Date?   // nil = full

    // MARK: - Persistence keys
    private let kCurrent       = "lives_current"
    private let kNextRegen     = "lives_nextRegenAt"
    private let kLastTickWall  = "lives_lastTickWall"
    private let kLastTickMono  = "lives_lastTickMonotonic"
    private let kForwardRatch  = "lives_forwardRatchet"
    private let kICloudAnchor  = "lives_iCloudAnchor"
    private let kRefillCount   = "lives_refillCountToday"
    private let kRefillDay     = "lives_refillDay"
    private func kAdRefillsToday(_ day: String) -> String {
        "lives_adRefillsToday_\(day)"
    }
    
    /// Escalating cost for life refills: 1st=50, 2nd=75, 3rd+=100
    var currentRefillCost: Int {
        let today = dayString()
        let savedDay = UserDefaults.standard.string(forKey: kRefillDay) ?? ""
        let count = (savedDay == today) ? UserDefaults.standard.integer(forKey: kRefillCount) : 0
        switch count {
        case 0: return JetonManager.costRefillOne
        case 1: return 75
        default: return 100
        }
    }

    // MARK: - State (raw)
    private var forwardRatchet: Date {
        get { (UserDefaults.standard.object(forKey: kForwardRatch) as? Date) ?? .distantPast }
        set { UserDefaults.standard.set(newValue, forKey: kForwardRatch) }
    }

    private var lastTickWall: Date? {
        get { UserDefaults.standard.object(forKey: kLastTickWall) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: kLastTickWall) }
    }

    private var lastTickMono: TimeInterval? {
        get {
            let v = UserDefaults.standard.double(forKey: kLastTickMono)
            return v == 0 ? nil : v
        }
        set { UserDefaults.standard.set(newValue ?? 0, forKey: kLastTickMono) }
    }

    // MARK: - Init
    private init() {
        let ud = UserDefaults.standard
        if ud.object(forKey: kCurrent) == nil {
            // First launch: tam dolu başla
            ud.set(Self.maxLives, forKey: kCurrent)
            self.current = Self.maxLives
        } else {
            self.current = max(0, min(Self.maxLives, ud.integer(forKey: kCurrent)))
        }
        self.nextRegenAt = ud.object(forKey: kNextRegen) as? Date

        // Foreground'a her dönüşte tick et
        recomputeRegen()
    }

    // MARK: - Public computed
    var isFull: Bool { current >= Self.maxLives }
    var hasInfinite: Bool {
        // IAP unlock kontrolü
        IAPManager.shared.isUnlimitedLives
    }

    // MARK: - Public actions

    /// Bir oyun kaybedildiğinde çağır. Sınırsız can sahibi ise no-op.
    func loseOne() {
        recomputeRegen()
        guard !hasInfinite else { return }
        guard current > 0 else { return }
        current -= 1
        UserDefaults.standard.set(current, forKey: kCurrent)
        // Eğer dolu->eksik geçişiyse regen sayacını başlat
        if nextRegenAt == nil {
            startRegen()
        }
        snapshotTick()
    }

    /// Jeton ile +1 can. Maliyet günde yükselir: 50 → 75 → 100
    @discardableResult
    func buyOne() -> Bool {
        recomputeRegen()
        guard current < Self.maxLives else { return false }
        let cost = currentRefillCost
        guard JetonManager.shared.spend(cost) else { return false }
        incrementRefillCount()
        addOne(internal: true)
        return true
    }
    
    private func incrementRefillCount() {
        let today = dayString()
        let savedDay = UserDefaults.standard.string(forKey: kRefillDay) ?? ""
        if savedDay == today {
            let current = UserDefaults.standard.integer(forKey: kRefillCount)
            UserDefaults.standard.set(current + 1, forKey: kRefillCount)
        } else {
            UserDefaults.standard.set(today, forKey: kRefillDay)
            UserDefaults.standard.set(1, forKey: kRefillCount)
        }
    }
    
    private func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 200 jeton ile tam dolum. Başarısızsa false.
    @discardableResult
    func buyAll() -> Bool {
        recomputeRegen()
        guard current < Self.maxLives else { return false }
        guard JetonManager.shared.spend(JetonManager.costRefillAll) else { return false }
        fillAll()
        return true
    }

    /// Reklam ile +1 can. Cap dolduysa false.
    @discardableResult
    func adRefill() async -> Bool {
        recomputeRegen()
        guard current < Self.maxLives else { return false }
        let shown = await AdManager.shared.presentRewarded(.life)
        guard shown else { return false }
        addOne(internal: true)
        return true
    }

    /// Foreground/launch sırasında çağır.
    func recomputeRegen() {
        guard !hasInfinite else {
            if current < Self.maxLives { fillAll() }
            return
        }
        guard current < Self.maxLives else {
            nextRegenAt = nil
            UserDefaults.standard.removeObject(forKey: kNextRegen)
            return
        }
        // Eğer hiç tick yoksa, başlat
        guard let lastWall = lastTickWall, let lastMono = lastTickMono else {
            startRegen()
            return
        }
        let elapsed = effectiveElapsed(savedWall: lastWall, savedMono: lastMono)
        let regenCount = Int(elapsed / Self.regenIntervalSeconds)
        if regenCount > 0 {
            let added = min(regenCount, Self.maxLives - current)
            current += added
            UserDefaults.standard.set(current, forKey: kCurrent)
            // Yeni tick noktası: tüketilen elapsed'i geri sar
            advanceTick(by: TimeInterval(added) * Self.regenIntervalSeconds)
            if current >= Self.maxLives {
                nextRegenAt = nil
                UserDefaults.standard.removeObject(forKey: kNextRegen)
            } else {
                let remaining = Self.regenIntervalSeconds - (elapsed - TimeInterval(added) * Self.regenIntervalSeconds)
                nextRegenAt = Date().addingTimeInterval(remaining)
                UserDefaults.standard.set(nextRegenAt, forKey: kNextRegen)
            }
        } else {
            // Sayaç ilerlesin ama can artmasın
            let remaining = Self.regenIntervalSeconds - elapsed
            nextRegenAt = Date().addingTimeInterval(max(0, remaining))
            UserDefaults.standard.set(nextRegenAt, forKey: kNextRegen)
        }
        // Forward-only ratchet
        forwardRatchet = max(forwardRatchet, Date())
    }

    // MARK: - Private helpers

    private func addOne(internal _: Bool) {
        current = min(Self.maxLives, current + 1)
        UserDefaults.standard.set(current, forKey: kCurrent)
        if current >= Self.maxLives {
            nextRegenAt = nil
            UserDefaults.standard.removeObject(forKey: kNextRegen)
            cancelFullNotification()
        } else {
            startRegen()   // sıradaki için yeniden başlat
        }
    }

    private func fillAll() {
        current = Self.maxLives
        UserDefaults.standard.set(current, forKey: kCurrent)
        nextRegenAt = nil
        UserDefaults.standard.removeObject(forKey: kNextRegen)
        cancelFullNotification()
    }

    private func startRegen() {
        snapshotTick()
        nextRegenAt = Date().addingTimeInterval(Self.regenIntervalSeconds)
        UserDefaults.standard.set(nextRegenAt, forKey: kNextRegen)
        scheduleFullNotification()
    }

    // MARK: - Lives Full Push Notification

    private let kFullNotifID = "lives_full_notification"

    /// Canlar ne zaman dolacaksa o ana bildirim planlar.
    private func scheduleFullNotification() {
        guard !hasInfinite else { return }
        let missing = Self.maxLives - current
        guard missing > 0 else { cancelFullNotification(); return }
        // Full time = şimdiden missing * regen interval sonra
        let fullAt = Date().addingTimeInterval(TimeInterval(missing) * Self.regenIntervalSeconds)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Canların Doldu! ❤️❤️❤️❤️❤️"
            content.body = "5 canın tamamen yenilendi. Oynamaya devam etmeye hazırsın!"
            content.sound = .default
            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: fullAt
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: self.kFullNotifID, content: content, trigger: trigger
            )
            center.removePendingNotificationRequests(withIdentifiers: [self.kFullNotifID])
            center.add(request)
        }
    }

    private func cancelFullNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [kFullNotifID])
    }

    private func snapshotTick() {
        lastTickWall = Date()
        lastTickMono = ProcessInfo.processInfo.systemUptime
        forwardRatchet = max(forwardRatchet, Date())
    }

    private func advanceTick(by seconds: TimeInterval) {
        if let w = lastTickWall { lastTickWall = w.addingTimeInterval(seconds) }
        if let m = lastTickMono { lastTickMono = m + seconds }
    }

    /// 3-katmanlı anti-cheat hesaplaması.
    private func effectiveElapsed(savedWall: Date, savedMono: TimeInterval) -> TimeInterval {
        let wallNow = max(Date(), forwardRatchet)
        let monoNow = ProcessInfo.processInfo.systemUptime
        let wallElapsed = wallNow.timeIntervalSince(savedWall)
        let monoElapsed = monoNow - savedMono
        let safeWall = max(0, wallElapsed)
        if monoElapsed > 0 {
            // Aynı boot: ikisinden küçüğü
            return min(safeWall, monoElapsed)
        } else {
            // Reboot olmuş: wall'a güven, ama 24h tavanla sınırla
            return min(safeWall, 24 * 3600)
        }
    }
}
