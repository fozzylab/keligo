// ⚠️ iCloud sync için Xcode → Signing & Capabilities → iCloud (Key-value storage) gerekli
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var achievements: AchievementManager
    @StateObject private var iap = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false

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
                            if settings.soundEnabled {
                                Divider().background(t.secondaryText.opacity(0.3))
                                settingsRow(icon: "speaker.wave.3.fill", title: "Ses Seviyesi") {
                                    Slider(value: $settings.soundVolume, in: 0.1...1.0, step: 0.1)
                                        .frame(width: 120)
                                        .tint(t.accent)
                                        .onChange(of: settings.soundVolume) { _, v in
                                            SoundManager.shared.globalVolume = Float(v)
                                        }
                                }
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "iphone.radiowaves.left.and.right", title: "Titreşim") {
                                Toggle("", isOn: $settings.hapticEnabled).labelsHidden()
                            }
                            if settings.hapticEnabled {
                                Divider().background(t.secondaryText.opacity(0.3))
                                settingsRow(icon: "waveform", title: "Titreşim Yoğunluğu") {
                                    Menu {
                                        ForEach(HapticRichness.allCases) { r in
                                            Button(r.displayName) { settings.hapticRichness = r }
                                        }
                                    } label: {
                                        Text(settings.hapticRichness.displayName)
                                            .font(.subheadline).foregroundColor(t.accent)
                                    }
                                }
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "bell.fill", title: "Günlük Hatırlatıcı") {
                                Toggle("", isOn: $settings.dailyNotification).labelsHidden()
                            }
                            if settings.dailyNotification {
                                Divider().background(t.secondaryText.opacity(0.3))
                                settingsRow(icon: "clock.fill", title: "Hatırlatıcı Saati") {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: {
                                                var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
                                                c.hour = settings.notificationHour
                                                c.minute = settings.notificationMinute
                                                return Calendar.current.date(from: c) ?? Date()
                                            },
                                            set: { date in
                                                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                                                settings.notificationHour   = c.hour   ?? 9
                                                settings.notificationMinute = c.minute ?? 0
                                                if settings.dailyNotification {
                                                    NotificationManager.shared.scheduleDailyReminder(
                                                        hour: settings.notificationHour,
                                                        minute: settings.notificationMinute
                                                    )
                                                }
                                            }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .tint(t.accent)
                                }
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

                        // 2026: SPATIAL UI
                        sectionHeader("🪐 Spatial UI")
                        VStack(spacing: 0) {
                            settingsRow(icon: "cube.transparent", title: "Spatial UI") {
                                Toggle("", isOn: $settings.spatialUIEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "wind", title: "Ambient Yoğunluğu") {
                                Slider(value: $settings.ambientIntensity, in: 0.1...1.0, step: 0.1)
                                    .frame(width: 120)
                                    .tint(t.accent)
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "bolt.shield", title: "Mikro-İnteraksiyon") {
                                Menu {
                                    ForEach(MicroInteractionLevel.allCases) { level in
                                        Button(level.displayName) { settings.microInteractionLevel = level }
                                    }
                                } label: {
                                    Text(settings.microInteractionLevel.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(t.accent)
                                }
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "eye.slash", title: "Hareket Güvenli Modu") {
                                Toggle("", isOn: $settings.motionSafeMode).labelsHidden()
                            }
                        }
                        .background(t.surface).cornerRadius(12).padding(.horizontal)

                        // 2026: KİŞİSELLEŞTİRME
                        sectionHeader("🧠 Kişiselleştirme")
                        VStack(spacing: 0) {
                            settingsRow(icon: "brain.head.profile", title: "AI Asistan") {
                                Toggle("", isOn: $settings.aiAssistantEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "eye", title: "Renk Filtresi") {
                                Menu {
                                    ForEach(ColorVisionFilter.allCases) { filter in
                                        Button(filter.displayName) { settings.colorVisionFilter = filter }
                                    }
                                } label: {
                                    Text(settings.colorVisionFilter.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(t.accent)
                                }
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "waveform", title: "Haptic Zenginliği") {
                                Menu {
                                    ForEach(HapticRichness.allCases) { richness in
                                        Button(richness.displayName) { settings.hapticRichness = richness }
                                    }
                                } label: {
                                    Text(settings.hapticRichness.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(t.accent)
                                }
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "mic.fill", title: "Sesli Kontrol") {
                                Toggle("", isOn: $settings.voiceControlEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "moon.fill", title: "Odak Modu (Focus)") {
                                Toggle("", isOn: $settings.focusModeEnabled).labelsHidden()
                            }
                            Divider().background(t.secondaryText.opacity(0.3))
                            settingsRow(icon: "livephoto", title: "Live Activity") {
                                Toggle("", isOn: $settings.dynamicIslandLiveActivity).labelsHidden()
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
                .foregroundColor(isSelected ? theme.accent : theme.primaryText)
            if locked {
                Text(requirement)
                    .font(.system(size: 8))
                    .foregroundColor(theme.secondaryText)
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
