import GameKit
import UIKit
import Combine

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    private override init() {}

    @Published var isAuthenticated = false
    @Published var authViewController: UIViewController? = nil

    static let speedLeaderboardID = "keligo_tr_speed_leaderboard"
    static let xpLeaderboardID   = "keligo_tr_xp_weekly"   // ← App Store Connect'te bu ID'yi oluştur

    // MARK: - Authentication

    func authenticate() {
        #if targetEnvironment(simulator)
        // Game Center does not work in Simulator — skip to avoid noisy logs.
        return
        #else
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, _ in
            DispatchQueue.main.async {
                if let vc {
                    self?.authViewController = vc
                } else if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.authViewController = nil
                } else {
                    self?.isAuthenticated = false
                }
            }
        }
        #endif
    }

    // MARK: - Leaderboard

    func submitSpeedScore(_ score: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(
            score, context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.speedLeaderboardID]
        ) { _ in }
    }

    /// Submit total XP to the weekly XP leaderboard.
    func submitXP(_ xp: Int) {
        #if targetEnvironment(simulator)
        return
        #else
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(
            xp, context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.xpLeaderboardID]
        ) { _ in }
        #endif
    }

    /// Present the Game Center leaderboard UI for weekly XP.
    func showXPLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKAccessPoint.shared.trigger(state: .leaderboards) {}
    }

    func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKAccessPoint.shared.trigger(state: .leaderboards) {}
    }

    // MARK: - Achievements

    func reportAchievement(id: String, percent: Double = 100) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let a = GKAchievement(identifier: id)
        a.percentComplete = percent
        a.showsCompletionBanner = true
        GKAchievement.report([a]) { _ in }
    }
}
