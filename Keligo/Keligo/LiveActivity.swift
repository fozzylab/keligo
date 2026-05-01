import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Günlük kelime için Live Activity attributes.
/// Hem ana app (start/update/end) hem widget extension (UI render) kullanır.
@available(iOS 16.1, *)
struct DailyWordActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable {
        /// Kelime maskeleme (örn: "M__VA")
        var maskedWord: String
        /// Kategori adı
        var category: String
        /// Doğru tahmin sayısı / toplam harf sayısı
        var revealedLetters: Int
        var totalLetters: Int
        /// Kalan yanlış hakkı (5 → 0)
        var wrongRemaining: Int
        var maxWrong: Int
        /// Oyun durumu (string olarak — Hashable)
        var status: String   // "playing" | "won" | "lost"
    }

    /// Sabit veri — başladığında verilir, sonra değişmez.
    var startedAt: Date
    var dateLabel: String   // "26 Nisan"
}

/// Live Activity başlatma / güncelleme / bitirme.
@available(iOS 16.1, *)
@MainActor
final class KeligoLiveActivityManager {
    static let shared = KeligoLiveActivityManager()
    private init() {}

    #if canImport(ActivityKit)
    private var activity: Activity<DailyWordActivityAttributes>?

    func start(maskedWord: String, category: String, totalLetters: Int, maxWrong: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Eski activity varsa sonlandır
        if let existing = activity {
            Task { await existing.end(nil, dismissalPolicy: .immediate) }
        }
        let attrs = DailyWordActivityAttributes(
            startedAt: Date(),
            dateLabel: dateLabel()
        )
        let initial = DailyWordActivityAttributes.State(
            maskedWord: maskedWord, category: category,
            revealedLetters: 0, totalLetters: totalLetters,
            wrongRemaining: maxWrong, maxWrong: maxWrong,
            status: "playing"
        )
        do {
            let a = try Activity.request(
                attributes: attrs,
                content: ActivityContent(state: initial, staleDate: nil),
                pushType: nil
            )
            self.activity = a
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    func update(maskedWord: String, revealed: Int, total: Int, wrongRemaining: Int) {
        guard let activity else { return }
        let state = DailyWordActivityAttributes.State(
            maskedWord: maskedWord,
            category: activity.attributes.dateLabel.isEmpty ? "" : activity.content.state.category,
            revealedLetters: revealed, totalLetters: total,
            wrongRemaining: wrongRemaining, maxWrong: activity.content.state.maxWrong,
            status: "playing"
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end(won: Bool) {
        guard let activity else { return }
        let currentState = activity.content.state
        let finalState = DailyWordActivityAttributes.State(
            maskedWord: currentState.maskedWord,
            category: currentState.category,
            revealedLetters: currentState.revealedLetters,
            totalLetters: currentState.totalLetters,
            wrongRemaining: currentState.wrongRemaining,
            maxWrong: currentState.maxWrong,
            status: won ? "won" : "lost"
        )
        Task {
            await activity.update(ActivityContent(state: finalState, staleDate: nil))
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await activity.end(nil, dismissalPolicy: .after(.now + 30))
        }
        self.activity = nil
    }

    private func dateLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: Date())
    }
    #else
    func start(maskedWord: String, category: String, totalLetters: Int, maxWrong: Int) {}
    func update(maskedWord: String, revealed: Int, total: Int, wrongRemaining: Int) {}
    func end(won: Bool) {}
    #endif
}
