// ⚠️ iCloud sync için Xcode → Signing & Capabilities → iCloud (Key-value storage) gerekli
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var achievements: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showReports = false
    @StateObject private var reporter = WordReportManager.shared

    var t: AppTheme { settings.theme }
    private let chapters = ChapterManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // KLAVYE TARZI
                        sectionHeader("Klavye Tarzi")
                        HStack(spacing: 10) {
                            ForEach(KeyboardStyle.allCases) { style in
                                Button { settings.keyboardStyle = style } label: {
                                    VStack(spacing: 6) {
                                        Text(style.icon).font(.title3)
                                        Text(style.displayName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(settings.keyboardStyle == style ? t.accent : t.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        settings.keyboardStyle == style
                                            ? AnyShapeStyle(t.accent.opacity(0.15))
                                            : AnyShapeStyle(t.surface),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.keyboardStyle == style ? t.accent : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal)

                        // TEMA
                        sectionHeader("Tema")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                let unlocked = achievements.isThemeUnlocked(theme, stats: stats, chapters: chapters)
                                ThemeCard(theme: theme, isSelected: settings.theme == theme, locked: !unlocked,
                                          requirement: achievements.unlockRequirement(theme))
                                    .onTapGesture {
                                        if unlocked { settings.theme = theme }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        // ZORLUK
                        sectionHeader("Zorluk")
                        HStack(spacing: 12) {
                            ForEach(Difficulty.allCases) { diff in
                                DifficultyCard(difficulty: diff, isSelected: settings.difficulty == diff)
                                    .onTapGesture { settings.difficulty = diff }
                            }
                        }
                        .padding(.horizontal)

                        // SES & TİTREŞİM
                        sectionHeader("Ses & Titreşim")
                        VStack(spacing: 0) {
                            settingsRow(icon: "speaker.wave.2.fill", title: "Ses Efektleri") {
                                Toggle("", isOn: $settings.soundEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "iphone.radiowaves.left.and.right", title: "Titreşim") {
                                Toggle("", isOn: $settings.hapticEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "bell.fill", title: "Günlük Hatırlatıcı (09:00)") {
                                Toggle("", isOn: $settings.dailyNotification).labelsHidden()
                            }
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        // OYUN
                        sectionHeader("Oyun")
                        VStack(spacing: 0) {
                            settingsRow(icon: "xmark.circle.fill", title: "Yanlış Harfleri Göster") {
                                Toggle("", isOn: $settings.showWrongLetters).labelsHidden()
                            }
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        // MOD & OYUN
                        sectionHeader("Mod & Oyun")
                        VStack(spacing: 0) {
                            // Preferred mode picker
                            HStack {
                                Image(systemName: "star.circle.fill").foregroundColor(t.accent).frame(width: 24)
                                Text("Varsayılan Mod").foregroundColor(t.primaryText)
                                Spacer()
                                Menu {
                                    Button("📅 Günlük Kelime") { settings.preferredMode = "daily" }
                                    Button("∞ Sonsuz Mod")    { settings.preferredMode = "infinite" }
                                    Button("📖 Bölüm Modu")   { settings.preferredMode = "chapter" }
                                    Button("⚡️ Hız Modu")     { settings.preferredMode = "speed" }
                                    Button("🧒 Çocuk Modu")   { settings.preferredMode = "kids" }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(modeDisplayName(settings.preferredMode))
                                            .font(.subheadline)
                                            .foregroundColor(t.accent)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(t.secondaryText)
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)

                            Divider().background(t.secondaryText.opacity(0.3))

                            // Speed duration
                            HStack {
                                Image(systemName: "timer").foregroundColor(t.accent).frame(width: 24)
                                Text("Hız Modu Süresi").foregroundColor(t.primaryText)
                                Spacer()
                                Picker("", selection: $settings.speedDuration) {
                                    Text("30 sn").tag(30)
                                    Text("60 sn").tag(60)
                                    Text("90 sn").tag(90)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)

                            Divider().background(t.secondaryText.opacity(0.3))

                            // Kids mode toggle
                            settingsRow(icon: "face.smiling.fill", title: "Çocuk Modu") {
                                Toggle("", isOn: $settings.kidsMode).labelsHidden()
                            }

                            Divider().background(t.secondaryText.opacity(0.3))

                            // Word length filter
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "textformat.size").foregroundColor(t.accent).frame(width: 24)
                                    Text("Kelime Uzunluğu").foregroundColor(t.primaryText)
                                    Spacer()
                                    Text("\(settings.wordLengthMin == 0 ? "Hepsi" : "\(settings.wordLengthMin)-\(settings.wordLengthMax) harf")")
                                        .font(.caption)
                                        .foregroundColor(t.secondaryText)
                                }
                                if settings.wordLengthMin > 0 {
                                    HStack(spacing: 12) {
                                        Text("Min: \(settings.wordLengthMin)")
                                            .font(.caption2).foregroundColor(t.secondaryText)
                                        Slider(value: Binding(
                                            get: { Double(settings.wordLengthMin) },
                                            set: { settings.wordLengthMin = Int($0) }
                                        ), in: 3...10, step: 1)
                                        .tint(t.accent)
                                    }
                                    HStack(spacing: 12) {
                                        Text("Max: \(settings.wordLengthMax)")
                                            .font(.caption2).foregroundColor(t.secondaryText)
                                        Slider(value: Binding(
                                            get: { Double(settings.wordLengthMax) },
                                            set: { settings.wordLengthMax = Int($0) }
                                        ), in: 5...20, step: 1)
                                        .tint(t.accent)
                                    }
                                }
                                Button(settings.wordLengthMin == 0 ? "Uzunluk Filtresi Ekle" : "Filtreyi Kaldır") {
                                    if settings.wordLengthMin == 0 {
                                        settings.wordLengthMin = 4
                                        settings.wordLengthMax = 8
                                    } else {
                                        settings.wordLengthMin = 0
                                        settings.wordLengthMax = 99
                                    }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(t.accent)
                                .padding(.leading, 28)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        // İSTATİSTİKLER
                        sectionHeader("İstatistikler")
                        VStack(spacing: 0) {
                            settingsRow(icon: "icloud.fill", title: "iCloud Senkronizasyon") {
                                Toggle("", isOn: Binding(
                                    get: { settings.iCloudSync },
                                    set: { val in
                                        settings.iCloudSync = val
                                        if val { stats.loadFromiCloud() }
                                    }
                                )).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "trash.fill", title: "İstatistikleri Sıfırla") {
                                Button { showResetAlert = true } label: {
                                    Text("Sıfırla").font(.subheadline).foregroundColor(.red)
                                }
                            }
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        // KELIME HATALARI
                        sectionHeader("Kelime Hataları")
                        VStack(spacing: 0) {
                            settingsRow(icon: "flag.fill", title: "Bekleyen Bildirimler") {
                                Button {
                                    showReports = true
                                } label: {
                                    HStack(spacing: 6) {
                                        if reporter.count > 0 {
                                            Text("\(reporter.count) adet")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("Temiz ✅")
                                                .font(.subheadline)
                                                .foregroundColor(t.secondaryText)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(t.secondaryText)
                                    }
                                }
                            }
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
            .alert("İstatistikleri Sıfırla", isPresented: $showResetAlert) {
                Button("Sıfırla", role: .destructive) { stats.reset() }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Tüm istatistikler silinecek.")
            }
            .sheet(isPresented: $showReports) {
                PendingReportsView()
                    .environmentObject(settings)
            }
        }
    }

    private func modeDisplayName(_ mode: String) -> String {
        switch mode {
        case "daily": return "Günlük Kelime"
        case "infinite": return "Sonsuz Mod"
        case "chapter": return "Bölüm Modu"
        case "speed": return "Hız Modu"
        case "kids": return "Çocuk Modu"
        default: return "Günlük Kelime"
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(t.secondaryText)
            Spacer()
        }
        .padding(.horizontal).padding(.top, 4)
    }

    @ViewBuilder
    private func settingsRow<T: View>(icon: String, title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(t.accent).frame(width: 24)
            Text(title).foregroundColor(t.primaryText)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let locked: Bool
    let requirement: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Text(theme.icon).font(.title2)
                if locked {
                    Color.black.opacity(0.5).clipShape(Circle())
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundColor(.white)
                }
            }
            Text(theme.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(locked ? .secondary : (isSelected ? theme.accent : .secondary))
            if locked {
                Text(requirement)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected && !locked ? theme.accent : Color.clear, lineWidth: 2)
        )
        .opacity(locked ? 0.7 : 1)
    }
}

struct DifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(difficulty.icon).font(.title2)
            Text(difficulty.displayName).font(.caption.weight(.semibold))
            Text("\(difficulty.maxWrongGuesses) hak").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(AchievementManager.shared)
}
