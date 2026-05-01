import SwiftUI

// MARK: - Zen Mode

struct ZenModeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @StateObject private var vm: GameViewModel
    let onBack: () -> Void
    
    init(settings: SettingsViewModel, stats: StatsManager, onBack: @escaping () -> Void) {
        self.onBack = onBack
        _vm = StateObject(wrappedValue: GameViewModel(
            settings: settings, stats: stats,
            categoryFilter: nil, kidsMode: false, countsAgainstLives: false
        ))
    }
    
    var body: some View {
        GameBoardView(vm: vm, theme: settings.theme, modeLabel: "☯️ Zen Mod", onBack: onBack) {
            ZenGameOverView(vm: vm, theme: settings.theme, onBack: onBack)
        }
    }
}

struct ZenGameOverView: View {
    @ObservedObject var vm: GameViewModel
    let theme: AppTheme
    let onBack: () -> Void
    
    private var isWon: Bool { vm.gameState == .won }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(isWon ? "✨ Zen" : "🍃 Zen")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                if !isWon {
                    Text(vm.currentWord)
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(2)
                }
                
                Text(isWon ? "Kelimeyle bütünleştin." : "Bir sonraki kelime seni bekliyor.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button {
                    vm.startNewGame()
                } label: {
                    Label("Devam Et", systemImage: "infinity")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3)))
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button {
                    onBack()
                } label: {
                    Text("Ana Menü")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(28)
            .modifier(GlassSurface(cornerRadius: 28, intensity: 0.6, borderGlow: .white, innerGlow: true))
            .padding(.horizontal, 24)
        }
    }
}
