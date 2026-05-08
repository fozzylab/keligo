import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
// Firebase paketleri SPM ile eklendikten sonra aşağıdaki iki satırın başındaki // kaldır:
// import Firebase
// import FirebaseCrashlytics

@main
struct KeligoApp: App {

    init() {
        // FirebaseApp.configure()   // ← Firebase SPM eklenince bu satırı aç
    }
    @StateObject private var settings     = SettingsViewModel()
    @StateObject private var stats        = StatsManager()
    @StateObject private var achievements = AchievementManager.shared
    @StateObject private var jetons       = JetonManager.shared
    @StateObject private var iap          = IAPManager.shared
    @StateObject private var ai           = AIPersonalizationEngine.shared
    @StateObject private var vip          = VIPManager.shared
    @StateObject private var season       = SeasonManager.shared
    @StateObject private var adManager    = AdManager.shared

    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingChallengeCode: String? = nil
    @State private var showChallengeFromURL = false
    @State private var showIAPStore = false
    @State private var showAdErrorAlert = false

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
                    requestTrackingAndStartAds()
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
                        // App Open Ad — her ön plana gelişte göster (reklam yoksa atlar)
                        Task { await AdManager.shared.presentAppOpenAd() }
                    }
                }
                .onChange(of: adManager.errorMessage) { _, newError in
                    if newError != nil {
                        showAdErrorAlert = true
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
                .sheet(isPresented: $showIAPStore) {
                    IAPStoreView()
                        .environmentObject(settings)
                        .environmentObject(stats)
                        .environmentObject(achievements)
                        .environmentObject(jetons)
                        .environmentObject(iap)
                        .environmentObject(ai)
                        .environmentObject(vip)
                        .environmentObject(season)
                }
                .alert("Reklam Yüklenemedi", isPresented: $showAdErrorAlert) {
                    Button("Mağazaya Git") {
                        showIAPStore = true
                        adManager.errorMessage = nil
                    }
                    Button("Tamam") {
                        adManager.errorMessage = nil
                    }
                } message: {
                    Text(adManager.errorMessage ?? "Şu anda videolar gösterilemiyor.")
                }
        }
    }

    // ATT izni splash bittikten sonra (onAppear'dan ~1s sonra) istenir.
    // Kullanıcı izin verirse kişiselleştirilmiş reklam, vermezse genel reklam gösterilir.
    private func requestTrackingAndStartAds() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    #if DEBUG
                    MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["ec83e2b236748a7044a22abd065b23e7"]
                    #endif
                    MobileAds.shared.start { _ in
                        // MobileAds hazır — şimdi preload başlat ve ilk App Open Ad'ı göster
                        Task { @MainActor in
                            AdManager.shared.startPreloadingAndShowOpenAd()
                        }
                    }
                }
            }
        }
    }
}
