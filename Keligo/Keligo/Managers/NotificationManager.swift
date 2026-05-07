import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let dailyID = "keligo_daily_reminder"
    private let lastScheduledKey = "notifLastScheduled"
    private let appGroupID = "group.com.fozzylabs.keligo"

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
                if granted { self.scheduleDailyReminder() }
            }
        }
    }

    // MARK: - Reschedule if needed (call from onAppear each launch)

    func rescheduleIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = defaults.object(forKey: lastScheduledKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if lastDay >= today { return } // already scheduled today
        }

        checkStatus { status in
            guard status == .authorized else { return }
            self.scheduleDailyReminder()
        }
    }

    // MARK: - Schedule

    /// Varsayılan saat (09:00) ile bildirim planla
    func scheduleDailyReminder() {
        scheduleDailyReminder(hour: 9, minute: 0)
    }

    /// Özel saat/dakika ile bildirim planla
    func scheduleDailyReminder(hour: Int, minute: Int) {
        cancelDailyReminder()

        // Save today as last scheduled date
        UserDefaults.standard.set(Date(), forKey: lastScheduledKey)

        // Read streak from App Group
        let streak = UserDefaults(suiteName: appGroupID)?.integer(forKey: "currentStreak") ?? 0

        // Use today's word category as a hint
        let todayWord = DailyWordManager.shared.todayWord
        let category = todayWord.category
        let letterCount = todayWord.word.filter { $0 != " " }.count

        // Build streak suffix
        let streakSuffix = streak > 0 ? " 🔥 \(streak) günlük serin var!" : ""

        let messages: [(title: String, body: String)] = [
            ("Keligo 🎯", "Bugünün \(category) kategorisindeki \(letterCount) harfli kelimesini buldun mu?\(streakSuffix)"),
            ("Günlük meydan okuma! ⚔️", "\(category) dünyasından \(letterCount) harfli bir kelime seni bekliyor.\(streakSuffix)"),
            ("Serini koru! 🔥", "Bugün oynamazsan serin sıfırlanır. \(category) kategorisinde \(letterCount) harfli kelime var!"),
            ("Keligo 📅", "Yeni gün, yeni kelime! Bugünkü ipucu: \(category), \(letterCount) harf.\(streakSuffix)"),
        ]

        let picked = messages.randomElement()!
        let content = UNMutableNotificationContent()
        content.title = picked.title
        content.body = picked.body
        content.sound = .default
        content.badge = 1

        var dc = DateComponents()
        dc.hour = hour; dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyID])
    }

    // MARK: - Status

    func checkStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }
}
