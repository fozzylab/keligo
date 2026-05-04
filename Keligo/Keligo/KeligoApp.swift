import SwiftUI
import GoogleMobileAds

@main
struct KeligoApp: App {
    @StateObject private var settings     = SettingsViewModel()
    @StateObject private var stats        = StatsManager()
    @StateObject private var achievements = AchievementManager.shared
    @StateObject private var jetons       = JetonManager.shared
    @StateObject private var iap          = IAPManager.shared
    @StateObject private var ai           = AIPersonalizationEngine.shared
    @StateObject private var vip          = VIPManager.shared
    @StateObject private var season       = SeasonManager.shared

    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingChallengeCode: String? = nil
    @State private var showChallengeFromURL = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(achievements)
                .environmentObject(jetons)
                .environmentObject(iap)
                .environmentObject(ai)
                .environmentObject(vip)
                .environmentObject(season)
                .onAppear {
                    MobileAds.shared.start { _ in }
                    GameCenterManager.shared.authenticate()
                    NotificationManager.shared.checkStatus { status in
                        DispatchQueue.main.async {
                            if status == .authorized { settings.dailyNotification = true }
                        }
                    }
                }
                .onOpenURL { url in
                    // keligo://challenge/ABCDEFG
                    guard url.scheme == "keligo",
                          url.host == "challenge",
                          let rawCode = url.pathComponents.dropFirst().first
                    else { return }
                    // Reformat as ABC-DEF-G if needed
                    let clean = rawCode.uppercased().replacingOccurrences(of: "-", with: "")
                    if clean.count >= 6 {
                        let a = String(clean.prefix(3))
                        let b = String(clean.dropFirst(3).prefix(3))
                        let c = String(clean.dropFirst(6))
                        pendingChallengeCode = c.isEmpty ? "\(a)-\(b)" : "\(a)-\(b)-\(c)"
                    } else {
                        pendingChallengeCode = rawCode
                    }
                    showChallengeFromURL = true
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        LivesManager.shared.recomputeRegen()
                    }
                }
                .sheet(isPresented: $showChallengeFromURL, onDismiss: { pendingChallengeCode = nil }) {
                    if let code = pendingChallengeCode {
                        DeepLinkChallengeView(code: code)
                            .environmentObject(settings)
                            .environmentObject(stats)
                            .environmentObject(achievements)
                            .environmentObject(jetons)
                            .environmentObject(ai)
                            .environmentObject(vip)
                            .environmentObject(season)
                    }
                }
        }
    }
}
