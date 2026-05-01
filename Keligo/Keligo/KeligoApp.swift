import SwiftUI

@main
struct KeligoApp: App {
    @StateObject private var settings     = SettingsViewModel()
    @StateObject private var stats        = StatsManager()
    @StateObject private var achievements = AchievementManager.shared
    @StateObject private var jetons       = JetonManager.shared
    @StateObject private var iap          = IAPManager.shared

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
                .onAppear {
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
                .sheet(isPresented: $showChallengeFromURL, onDismiss: { pendingChallengeCode = nil }) {
                    if let code = pendingChallengeCode {
                        DeepLinkChallengeView(code: code)
                            .environmentObject(settings)
                            .environmentObject(stats)
                            .environmentObject(achievements)
                            .environmentObject(jetons)
                    }
                }
        }
    }
}
