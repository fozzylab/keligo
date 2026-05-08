import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var jetons: JetonManager
    @StateObject private var chapters = ChapterManager.shared
    @Environment(\.horizontalSizeClass) var sizeClass

    private var isIPad: Bool { sizeClass == .regular }

    @AppStorage("preferredMode") private var preferredMode = "daily"

    @State private var showInfinite = false
    @State private var showChapterSelect = false
    @State private var showSpeed = false
    @State private var showKids = false
    @State private var showCategoryPicker = false
    @State private var showOutOfLives = false
    @State private var pendingInfiniteMode = false
    @State private var pendingKidsMode = false
    @State private var bonusClaimAnim = false
    @State private var bonusJustClaimed = false
    @State private var showBonusAdConfirm = false
    @StateObject private var lives = LivesManager.shared
    @StateObject private var iap = IAPManager.shared
    @StateObject private var prompts = AppPromptManager.shared
    @StateObject private var deal = DailyDealManager.shared
    @StateObject private var piggy = PiggyBankManager.shared
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showWordStats = false
    @State private var showAchievements = false
    @State private var showFriendChallenge = false
    @State private var showIAPStore = false
    @State private var showBattlePass = false
    @State private var showStarterPack = false

    @State private var showLivesInfo = false
    @State private var livesNow = Date()
    @State private var livesTimer: Timer? = nil
    @State private var showCalendar = false
    @State private var showWeekly = false
    @State private var showDavet = false
    @State private var showHowToPlay = false
    @State private var selectedCategory: String? = nil

    // MARK: - Piggy bank state
    @State private var piggyCollectToast: String? = nil
    @State private var showPiggyAdConfirm = false
    @State private var showPiggyFullSheet = false

    // MARK: - Easter egg state
    @State private var eggTapCount = 0
    @State private var eggLastTap = Date.distantPast
    @State private var showEggToast = false
    @State private var eggShake: CGFloat = 0
    @AppStorage("easterEggUnlocked") private var easterEggUnlocked = false

    var t: AppTheme { settings.theme }
    private let daily = DailyWordManager.shared
    private let weekly = WeeklyChallengeManager.shared

    @StateObject private var ai = AIPersonalizationEngine.shared
    
    var body: some View {
        ZStack {
            // Theme background always shown first (ensures light themes stay light)
            t.background.ignoresSafeArea()
            RadialGradient(
                colors: [t.glowColor, .clear],
                center: UnitPoint(x: 0.85, y: 0.05),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            // 2026: Generative ambient overlay (on top of theme bg, not replacing it)
            if settings.spatialUIEnabled {
                GenerativeBackground(mood: ai.suggestedAmbientMood, intensity: settings.ambientIntensity)
                    .ignoresSafeArea()
            }
            
            // Floating dust ambient layer (static, lightweight)
            if settings.spatialUIEnabled && settings.microInteractionLevel != .minimal {
                FloatingDust(color: t.accent, count: 8)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topNavBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        statsStrip
                        
                        if AdManager.shared.canShowRewarded(.jetonBonus) && !iap.isAdsRemoved {
                            dailyBonusCard
                        }
                        
                        // 2026: Battle Pass quick CTA
                        battlePassCTA
                        
                        modeSection
                        Text("v1.0")
                            .font(.caption2)
                            .foregroundColor(t.secondaryText.opacity(0.35))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .drawingGroup()
                }
            }

            // App prompt banner (premium upsell — düşük yoğunlukta)
            if let kind = prompts.current {
                VStack {
                    Spacer().frame(height: 80)
                    AppPromptBanner(
                        kind: kind, theme: t,
                        onCTA: {
                            prompts.dismiss()
                            showIAPStore = true
                        },
                        onDismiss: { prompts.dismiss() }
                    )
                    Spacer()
                }
                .zIndex(100)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: prompts.current)
            }

            // Achievement toast
            if let toast = achievements.pendingToast {
                VStack {
                    AchievementToast(achievement: toast, theme: t)
                        .padding(.top, 60)
                    Spacer()
                }
                .zIndex(99)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: achievements.pendingToast?.id)
            }

            // Kumbara toplandı toast'u
            if let piggyText = piggyCollectToast {
                VStack {
                    Spacer()
                    Text(piggyText)
                        .font(.subheadline.weight(.black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 14, y: 4)
                        .padding(.bottom, 120)
                }
                .zIndex(96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: piggyCollectToast)
            }

            // Easter egg toast
            if showEggToast {
                EasterEggToast()
                    .padding(.bottom, 120)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .zIndex(97)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showEggToast)
            }

            // Davet overlay
            if showDavet {
                DavetView(onBack: { withAnimation { showDavet = false } })
                    .transition(.move(edge: .trailing)).zIndex(2)
            }

            // Streak milestone toast
            if let milestone = stats.pendingMilestonToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Text("🔥")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(milestone.days) Günlük Seri!")
                                .font(.headline.weight(.black))
                                .foregroundColor(.white)
                            Text("+\(milestone.jetons) jeton ödülün!")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange.opacity(0.9))
                        }
                        Spacer()
                        Button { withAnimation { stats.dismissMilestoneToast() } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.orange, Color.red.opacity(0.8)],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .zIndex(98)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: milestone.days)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { stats.dismissMilestoneToast() }
                    }
                }
            }

            // Full-screen overlays
            if showInfinite {
                GameContainerView(settings: settings, stats: stats, categoryFilter: selectedCategory,
                                  onBack: { withAnimation(.easeInOut(duration: 0.3)) { showInfinite = false } })
                    .transition(.move(edge: .trailing)).zIndex(1)
            }
            if showChapterSelect {
                ChapterSelectView(onBack: { withAnimation(.easeInOut(duration: 0.3)) { showChapterSelect = false } })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .trailing)).zIndex(1)
            }
            if showSpeed {
                SpeedModeView(onBack: { withAnimation(.easeInOut(duration: 0.3)) { showSpeed = false } })
                    .transition(.move(edge: .trailing)).zIndex(1)
            }
            if showKids {
                GameContainerView(
                    settings: settings, stats: stats,
                    categoryFilter: nil, kidsMode: true,
                    onBack: { withAnimation(.easeInOut) { showKids = false } }
                )
                .transition(.move(edge: .trailing)).zIndex(1)
            }
        }
        .onAppear {
            lives.recomputeRegen()
            prompts.notifyChapterStateChanged()
            deal.refreshIfNeeded()   // gece yarısı geçtiyse kartı temizle
        }
        .animation(.easeInOut(duration: 0.3), value: showInfinite)
        .animation(.easeInOut(duration: 0.3), value: showChapterSelect)
        .animation(.easeInOut(duration: 0.3), value: showSpeed)
        .animation(.easeInOut(duration: 0.3), value: showKids)
        .animation(.easeInOut(duration: 0.3), value: showWeekly)
        .animation(.easeInOut(duration: 0.3), value: showDavet)
        .sheet(isPresented: $showOutOfLives, onDismiss: {
            lives.recomputeRegen()
            let hasLives = lives.current > 0 || lives.hasInfinite
            if pendingInfiniteMode {
                pendingInfiniteMode = false
                if hasLives { showCategoryPicker = true }
            } else if pendingKidsMode {
                pendingKidsMode = false
                if hasLives { showKids = true }
            }
        }) {
            OutOfLivesSheet()
                .environmentObject(settings)
                .environmentObject(jetons)
        }
        // Can bilgisi — timer ile canlı güncellenen sheet
        .sheet(isPresented: $showLivesInfo) {
            LivesInfoSheet(
                lives: lives,
                onRefill: { showOutOfLives = true },
                onDismiss: { showLivesInfo = false }
            )
            .environmentObject(settings)
            .environmentObject(jetons)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        // Kumbara: reklam izle → birikimi topla
        .alert("🐷 Kumbaranı Aç!", isPresented: $showPiggyAdConfirm) {
            Button("Reklamı İzle") {
                Task {
                    let ok = await AdManager.shared.presentRewarded(.jetonBonus)
                    if ok {
                        let earned = piggy.collect()
                        withAnimation(.spring()) {
                            piggyCollectToast = "+\(earned) 🟡 kumbara açıldı!"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                            withAnimation { piggyCollectToast = nil }
                        }
                    }
                }
            }
            Button("Sonra", role: .cancel) {}
        } message: {
            Text("Kısa bir reklam izledikten sonra kumbaranızdaki \(piggy.balance) jeton hesabınıza aktarılır.")
        }
        // Kumbara dolu: normal topla veya 2x kazan
        .confirmationDialog("🐷 Kumbara Doldu!", isPresented: $showPiggyFullSheet, titleVisibility: .visible) {
            Button("2x Kazan — \(piggy.balance * 2) 🟡 (Reklam İzle)") {
                Task {
                    let ok = await AdManager.shared.presentRewarded(.jetonBonus)
                    if ok {
                        let earned = piggy.collectDouble()
                        withAnimation(.spring()) {
                            piggyCollectToast = "+\(earned) 🟡 2x kumbara bonusu!"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                            withAnimation { piggyCollectToast = nil }
                        }
                    }
                }
            }
            Button("Normal Topla — \(piggy.balance) 🟡") {
                let earned = piggy.collect()
                withAnimation(.spring()) {
                    piggyCollectToast = "+\(earned) 🟡 kumbara açıldı!"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                    withAnimation { piggyCollectToast = nil }
                }
            }
            Button("Sonra", role: .cancel) {}
        } message: {
            Text("Kumbaranız doldu! Reklam izleyerek \(piggy.balance * 2) jeton (2x) kazanabilirsiniz.")
        }
        .alert("Reklam izle, +\(JetonManager.rewardJetonAdBonus) jeton kazan", isPresented: $showBonusAdConfirm) {
            Button("İzle") {
                Task {
                    let ok = await AdManager.shared.presentRewarded(.jetonBonus)
                    if ok {
                        JetonManager.shared.earn(JetonManager.rewardJetonAdBonus)
                        withAnimation(.spring()) { bonusJustClaimed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { bonusJustClaimed = false }
                        }
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("📺 Kısa bir reklam sonrası hesabına \(JetonManager.rewardJetonAdBonus) jeton eklenir. Günde sadece 1 kez verilir.")
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showStats) { StatsView() }
        .sheet(isPresented: $showWordStats) {
            WordStatsView()
                .environmentObject(settings)
                .environmentObject(stats)
        }
        .sheet(isPresented: $showAchievements) { AchievementsView() }
        .sheet(isPresented: $showHowToPlay) { HowToPlayView().environmentObject(settings) }
        .sheet(isPresented: $showFriendChallenge) { FriendChallengeView() }
        .sheet(isPresented: $showIAPStore) { IAPStoreView() }
        .sheet(isPresented: $showBattlePass) { BattlePassView() }
        .sheet(isPresented: $showStarterPack) { StarterPackView() }

        .sheet(isPresented: $showCalendar) {
            DailyCalendarView()
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(jetons)
        }
        .sheet(isPresented: $showWeekly) {
            WeeklyChallengeView()
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(jetons)
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(selected: $selectedCategory) {
                showCategoryPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut) { showInfinite = true }
                }
            }
        }
    }

    // MARK: - Top nav

    private var topNavBar: some View {
        HStack {
            navButton(icon: "chart.bar.fill") { showStats = true }
            Spacer()
            navButton(icon: "text.magnifyingglass") { showWordStats = true }
            Spacer()
            navButton(icon: "trophy.fill") { showAchievements = true }
            Spacer()
            navButton(icon: "questionmark.circle.fill") { showHowToPlay = true }
            Spacer()
            navButton(icon: "gearshape.fill") { showSettings = true }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(t.accentGradient)
                .frame(width: 46, height: 46)
                .background(t.cardFill, in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 10) {
            // Keligo logo — floating 3D tiles with spatial depth
            ZStack {
                Circle()
                    .fill(t.accent.opacity(0.07))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                    .breathe(intensity: 0.4, speed: 5.0)

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(["K","E","L"], id: \.self) { letter in
                            HeroLetterTile(letter: letter, accent: t.accent)
                                .spatialDepth(4, perspective: 0.2)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(["İ","G","O"], id: \.self) { letter in
                            HeroLetterTile(letter: letter, accent: t.accent)
                                .spatialDepth(3, perspective: 0.2)
                        }
                    }
                }
                .ambientGlow(t.accent, intensity: 0.15, radius: 12)
                .modifier(ShakeEffect(animatableData: eggShake))
                .onTapGesture { handleEggTap() }
            }
            .padding(.top, 12)

            Text("Kelime Bulma Oyunu")
                .font(.subheadline.weight(.medium))
                .foregroundColor(t.secondaryText)

            if stats.currentStreak > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("\(stats.currentStreak) galibiyet serisi!")
                        .font(.caption.weight(.bold))
                        .foregroundColor(t.primaryText)
                    if stats.shieldActive {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(t.cardFill, in: Capsule())
                .overlay(Capsule().stroke(
                    stats.shieldActive
                        ? Color.cyan.opacity(0.40)
                        : Color.orange.opacity(t.isDark ? 0.12 : 0.25),
                    lineWidth: 1))
                .padding(.top, 4)
            }

            // Kalkan satın al / aktif göster
            if stats.currentStreak >= 1 {
                if stats.shieldActive {
                    HStack(spacing: 5) {
                        Image(systemName: "shield.fill").foregroundColor(.cyan)
                        Text("Kalkan Aktif — Serin korunuyor")
                            .font(.caption.weight(.bold)).foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                    .padding(.top, 2)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.3)) { _ = stats.activateShield() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "shield")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(jetons.canAfford(JetonManager.costShield) ? .cyan : t.secondaryText)
                            Text("Kalkan Al")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.primaryText)
                            HStack(spacing: 2) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7)).foregroundColor(.yellow)
                                Text("\(JetonManager.costShield)")
                                    .font(.caption.weight(.bold)).foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(t.cardFill, in: Capsule())
                        .overlay(Capsule().stroke(
                            Color.cyan.opacity(jetons.canAfford(JetonManager.costShield) ? 0.30 : 0.10),
                            lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!jetons.canAfford(JetonManager.costShield))
                    .opacity(jetons.canAfford(JetonManager.costShield) ? 1.0 : 0.45)
                    .padding(.top, 2)
                }
            }

            // Kumbara butonu (eğer birikim varsa)
            if !piggy.isEmpty {
                Button {
                    if piggy.isFull {
                        showPiggyFullSheet = true
                    } else {
                        showPiggyAdConfirm = true
                    }
                } label: {
                    HStack(spacing: 7) {
                        Text(piggy.isFull ? "🐷" : "🐖")
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(piggy.balance) jeton birikti!")
                                .font(.caption.weight(.black))
                                .foregroundColor(piggy.isFull ? .yellow : t.primaryText)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.12))
                                    Capsule()
                                        .fill(piggy.isFull
                                              ? LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                              : LinearGradient(colors: [t.accent, t.accent.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * piggy.progress)
                                        .animation(.spring(response: 0.5), value: piggy.progress)
                                }
                            }
                            .frame(height: 4)
                        }
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(t.secondaryText)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(
                        piggy.isFull
                            ? AnyShapeStyle(Color.yellow.opacity(0.18))
                            : AnyShapeStyle(t.cardFill),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(piggy.isFull ? Color.yellow.opacity(0.50) : t.cardStroke, lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }

            // Jeton + Can pill'leri yan yana
            HStack(spacing: 10) {
                // Jeton — tıklayınca mağazaya git
                Button { showIAPStore = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("\(jetons.balance)")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(t.primaryText)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(t.cardFill, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.yellow.opacity(t.isDark ? 0.10 : 0.20), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())

                // Can — tıklayınca bilgi/dolum ekranı
                Button {
                    if lives.current == 0 && !lives.hasInfinite {
                        showOutOfLives = true
                    } else {
                        showLivesInfo = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: lives.hasInfinite ? "infinity.circle.fill" : "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                        if lives.hasInfinite {
                            Text("∞").font(.subheadline.weight(.bold))
                                .foregroundColor(t.primaryText)
                        } else {
                            Text("\(lives.current)/\(LivesManager.maxLives)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(t.primaryText)
                        }
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(t.cardFill, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.red.opacity(t.isDark ? 0.10 : 0.20), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .onAppear { lives.recomputeRegen() }
    }

    // MARK: - Mode cards

    private var modeSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            modeSectionContent
        }
    }

    @ViewBuilder
    private var modeSectionContent: some View {
        // ── Ana Oyun Modları (üst sıra) ──
        GameModeCard(
            icon: "infinity",
            title: "Sonsuz Mod",
            subtitle: selectedCategory.map { "Kategori: \($0)" } ?? "Tüm kategoriler",
            gradient: [Color(red: 0.20, green: 0.45, blue: 1.00), Color(red: 0.45, green: 0.75, blue: 1.00)],
            theme: t
        ) {
            lives.recomputeRegen()
            if lives.current > 0 || lives.hasInfinite {
                showCategoryPicker = true
            } else {
                pendingInfiniteMode = true
                showOutOfLives = true
            }
        }

        GameModeCard(
            icon: "flag.checkered",
            title: "Bölüm Modu",
            subtitle: "\(chapters.chapters.filter { (chapters.stars[$0.id] ?? 0) > 0 }.count)/\(chapters.chapters.count) bölüm",
            gradient: [Color(red: 0.65, green: 0.15, blue: 1.00), Color(red: 1.00, green: 0.38, blue: 0.82)],
            theme: t
        ) { showChapterSelect = true }

        GameModeCard(
            icon: "calendar",
            title: "Günlük Kelime",
            subtitle: daily.hasPlayedToday ? "Bugün oynadın ✓" : "Her gün yeni kelime",
            gradient: [Color(red: 1.00, green: 0.45, blue: 0.10), Color(red: 1.00, green: 0.75, blue: 0.15)],
            badge: daily.hasPlayedToday ? nil : "YENİ",
            theme: t
        ) { showCalendar = true }

        GameModeCard(
            icon: "bolt.fill",
            title: "Hız Modu",
            subtitle: stats.speedHighScore > 0 ? "Rekor: \(stats.speedHighScore)" : "60 saniye",
            gradient: [Color(red: 1.00, green: 0.18, blue: 0.18), Color(red: 1.00, green: 0.58, blue: 0.10)],
            theme: t
        ) { showSpeed = true }

        // ── Özel Modlar (alt sıra) ──
        GameModeCard(
            icon: "face.smiling.fill",
            title: "Çocuk Modu",
            subtitle: "Kısa kelimeler",
            gradient: [Color(red: 0.10, green: 0.75, blue: 0.40), Color(red: 0.20, green: 0.95, blue: 0.55)],
            theme: t
        ) {
            lives.recomputeRegen()
            if lives.current > 0 || lives.hasInfinite {
                showKids = true
            } else {
                pendingKidsMode = true
                showOutOfLives = true
            }
        }

        GameModeCard(
            icon: "calendar.badge.exclamationmark",
            title: "Haftalık",
            subtitle: weekly.weekProgress() > 0 ? "\(weekly.weekProgress())/7" : "Yeni!",
            gradient: [Color(red: 0.10, green: 0.75, blue: 0.55), Color(red: 0.20, green: 0.95, blue: 0.70)],
            badge: weekly.isWeekComplete() && !weekly.weekBonusClaimed() ? "ÖDÜL" : nil,
            theme: t
        ) { showWeekly = true }

        GameModeCard(
            icon: "person.2.fill",
            title: "Arkadaşa Sor",
            subtitle: "Kod paylaş",
            gradient: [Color(red: 0.20, green: 0.60, blue: 0.85), Color(red: 0.10, green: 0.85, blue: 0.75)],
            theme: t
        ) { showFriendChallenge = true }

        GameModeCard(
            icon: "bag.fill",
            title: "Premium Mağaza",
            subtitle: "Temalar, jeton ve daha fazlası",
            gradient: [Color(red: 1.00, green: 0.75, blue: 0.00), Color(red: 1.00, green: 0.45, blue: 0.00)],
            badge: iap.isAdsRemoved ? nil : "PRO",
            theme: t
        ) { showIAPStore = true }
    }

    // MARK: - Easter egg

    private func handleEggTap() {
        SoundManager.shared.playButtonTap()
        let now = Date()
        // Reset if tapped too slowly (> 1.5 s gap)
        if now.timeIntervalSince(eggLastTap) > 1.5 { eggTapCount = 0 }
        eggLastTap = now
        eggTapCount += 1

        // Shake every 2 taps
        if eggTapCount % 2 == 0 {
            withAnimation(.linear(duration: 0.4)) { eggShake += 1 }
        }

        if eggTapCount >= 10 && !showEggToast {
            eggTapCount = 0
            if !easterEggUnlocked {
                easterEggUnlocked = true
                JetonManager.shared.earn(100)
            }
            withAnimation { showEggToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation { showEggToast = false }
            }
        }
    }

    // MARK: - Quick Start

    // MARK: - Daily bonus rewarded card

    private var dailyBonusCard: some View {
        Button {
            showBonusAdConfirm = true
        } label: {
            HStack(spacing: 12) {
                Text(bonusJustClaimed ? "✅" : "🎁")
                    .font(.title2)
                    .frame(width: 38, height: 38)
                    .background(Color.green.opacity(t.isDark ? 0.10 : 0.18), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(bonusJustClaimed ? "+\(JetonManager.rewardJetonAdBonus) jeton kazandın!" : "Günlük Bonus")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Text(bonusJustClaimed ? "Yarın tekrar gel" : "Reklam izle, +\(JetonManager.rewardJetonAdBonus) jeton kazan")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }
                Spacer()
                if !bonusJustClaimed {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(t.isDark ? 0.07 : 0.13), Color.green.opacity(t.isDark ? 0.02 : 0.05)],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(t.isDark ? 0.15 : 0.30), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(bonusJustClaimed)
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(spacing: 10) {
            miniStatCard(icon: "gamecontroller.fill", value: stats.totalGames, label: "Oyun")
            miniStatCard(icon: "trophy.fill", value: stats.wins, label: "Galibiyet")
            miniStatCard(icon: "flame.fill", value: stats.bestStreak, label: "En İyi Seri")
        }
    }

    private func miniStatCard(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(t.accentGradient)
            AnimatedCounter(value: value, font: .title3.bold(), color: t.primaryText)
            Text(label)
                .font(.caption2)
                .foregroundColor(t.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.cardStroke, lineWidth: 1))
    }
    
    // MARK: - Battle Pass CTA
    
    private var battlePassCTA: some View {
        Button {
            showBattlePass = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sezonluk Ödüller")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(t.primaryText)
                    Text("Oyna, XP kazan, ödülleri topla!")
                        .font(.caption)
                        .foregroundColor(t.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(t.secondaryText)
            }
            .padding(14)
            .glassSurface(cornerRadius: 16, intensity: 0.7, borderGlow: .purple, innerGlow: true)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Hero Letter Tile

private struct HeroLetterTile: View {
    let letter: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: accent.opacity(0.5), radius: 8, y: 3)

            Text(letter)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Game mode card

struct GameModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    var badge: String? = nil
    let theme: AppTheme
    let action: () -> Void

    @EnvironmentObject var settings: SettingsViewModel
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                        .shadow(color: gradient.first?.opacity(theme.isDark ? 0.15 : 0.35) ?? .clear, radius: theme.isDark ? 4 : 8, y: theme.isDark ? 2 : 4)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .center, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Color.red, in: Capsule())
                    }
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardStroke, lineWidth: 1))
            .shadow(color: theme.cardShadow, radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Achievement toast

struct AchievementToast: View {
    let achievement: Achievement
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 14) {
            Text(achievement.icon).font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text("Başarım Açıldı!")
                    .font(.caption.weight(.black))
                    .foregroundColor(theme.isDark ? .yellow : Color(red: 0.75, green: 0.55, blue: 0.00))
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.primaryText)
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.yellow.opacity(theme.isDark ? 0.15 : 0.35), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }
}

// MARK: - Easter Egg Toast

struct EasterEggToast: View {
    var body: some View {
        HStack(spacing: 14) {
            Text("🎉").font(.largeTitle)
            VStack(alignment: .leading, spacing: 3) {
                Text("Gizli Hazine!")
                    .font(.headline.weight(.black))
                    .foregroundColor(.white)
                Text("Keligo ikonuna 10 kez dokundun — 100 jeton kazandın!")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(red: 0.55, green: 0.10, blue: 0.90), Color(red: 0.90, green: 0.20, blue: 0.55)],
                           startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .shadow(color: .purple.opacity(0.5), radius: 16, y: 6)
        .padding(.horizontal, 20)
    }
}

// MARK: - Davet (Referral) View

struct DavetView: View {
    var onBack: () -> Void
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var jetons: JetonManager

    @AppStorage("davetUsed") private var davetUsed = false
    @AppStorage("davetUsedDate") private var davetUsedDate = ""
    @State private var showShareSheet = false

    var t: AppTheme { settings.theme }

    private var todayString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var canEarnToday: Bool { davetUsedDate != todayString }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.55, green: 0.25, blue: 0.95).opacity(0.25), .clear],
                center: .top, startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button { onBack() } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(t.accentGradient)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Arkadaşını Davet Et")
                        .font(.headline)
                        .foregroundColor(t.primaryText)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 14) {
                            Text("🎁")
                                .font(.system(size: 72))
                                .shadow(color: .purple.opacity(0.4), radius: 16)
                                .padding(.top, 28)

                            Text("Arkadaşını Davet Et,\nJeton Kazan!")
                                .font(.title2.weight(.black))
                                .foregroundColor(t.primaryText)
                                .multilineTextAlignment(.center)

                            Text("Her gün uygulamayı paylaşarak\n50 jeton kazanabilirsin.")
                                .font(.subheadline)
                                .foregroundColor(t.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        // How it works
                        VStack(spacing: 12) {
                            DavetStepRow(icon: "square.and.arrow.up", color: .purple,
                                         title: "Uygulamayı Paylaş",
                                         desc: "Arkadaşlarına App Store linkini gönder")
                            DavetStepRow(icon: "person.fill.checkmark", color: .blue,
                                         title: "Arkadaşın İndirsin",
                                         desc: "Her yeni oyuncu keligo dünyasını keşfeder")
                            DavetStepRow(icon: "circle.fill", color: .yellow,
                                         title: "Sen 50 Jeton Kazan",
                                         desc: "Her gün bir kez jeton ödülünü al")
                        }
                        .padding(16)
                        .background(t.surface, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)

                        // Daily reward status
                        HStack(spacing: 10) {
                            Image(systemName: canEarnToday ? "gift.fill" : "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(canEarnToday ? .yellow : t.correct)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(canEarnToday ? "Bugünkü ödülün seni bekliyor" : "Bugün ödül aldın")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(t.primaryText)
                                Text(canEarnToday ? "Paylaşınca 50 jeton kazanırsın" : "Yarın tekrar paylaşabilirsin")
                                    .font(.caption)
                                    .foregroundColor(t.secondaryText)
                            }
                            Spacer()
                            Text("+50 🟡")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.yellow)
                                .opacity(canEarnToday ? 1 : 0.4)
                        }
                        .padding(16)
                        .background(t.cardFill, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Share button
                        Button {
                            if canEarnToday {
                                davetUsedDate = todayString
                                davetUsed = true
                                JetonManager.shared.earn(50)
                            }
                            presentShareSheet(shareItems())
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                Text(canEarnToday ? "Paylaş ve 50 Jeton Kazan" : "Yine de Paylaş")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color(red: 0.55, green: 0.25, blue: 0.95),
                                                        Color(red: 0.95, green: 0.35, blue: 0.65)],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .foregroundColor(.white)
                            .shadow(color: .purple.opacity(0.45), radius: 12, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }

    private func shareItems() -> [Any] {
        let text = """
🎮 Türkçe Kelime Bulma Oyunu — Keligo'yi dene!

📅 Günlük kelimeler, 🏁 bölüm modu, ⚡️ hız modu ve çok daha fazlası!

App Store'dan ücretsiz indir 👇
https://apps.apple.com/app/keligo
"""
        return [text]
    }
}

struct DavetStepRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    @EnvironmentObject var settings: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.theme.primaryText)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(settings.theme.secondaryText)
            }
            Spacer()
        }
    }
}

// MARK: - Category picker

struct CategoryPickerView: View {
    @Binding var selected: String?
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    var onStart: () -> Void

    @StateObject private var iap = IAPManager.shared
    @State private var showIAPStore = false

    var t: AppTheme { settings.theme }
    private var categories: [String] { ["Tümü"] + WordList.categories + WordList.premiumCategories }

    private let categoryIcons: [String: String] = [
        "Tümü": "🎲", "Hayvanlar": "🦁", "Meslekler": "💼",
        "Yiyecekler": "🍜", "Şehirler": "🏙️", "Spor": "⚽️",
        "Doğa": "🌿", "Teknoloji": "💻", "Müzik": "🎵",
        "Bilim": "🔬", "Ülkeler": "🌍", "Mitoloji": "⚡️",
        "Meyveler": "🍎", "Taşıtlar": "🚗", "Uzay": "🚀",
        "Sanat": "🎨", "Tarih": "📜", "Bitkiler": "🌸",
        "Sebzeler": "🥦", "Coğrafya": "🗺️", "Markalar": "🏷️",
        "Günlük": "🗓️",
        // Premium
        "Sinema": "🎬", "Bilim+": "🔬", "Tarih+": "📜",
        "Spor+": "🏆", "Müzik+": "🎼",
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                t.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(categories, id: \.self) { cat in
                            let isPremium = WordList.premiumCategories.contains(cat)
                            let isLocked = isPremium && !iap.isPackUnlocked(WordList.packId(for: cat) ?? "")
                            let isSelected = cat == "Tümü" ? selected == nil : selected == cat

                            Button {
                                if isLocked {
                                    showIAPStore = true
                                } else {
                                    selected = cat == "Tümü" ? nil : cat
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Text(categoryIcons[cat] ?? "📚")
                                            .font(.title2)
                                            .opacity(isLocked ? 0.45 : 1.0)
                                        if isLocked {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.black.opacity(0.55), in: Circle())
                                                .offset(x: 14, y: -10)
                                        }
                                    }
                                    HStack(spacing: 4) {
                                        Text(cat)
                                            .font(.subheadline.weight(.semibold))
                                            .multilineTextAlignment(.center)
                                        if isPremium {
                                            Text("PRO")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 4).padding(.vertical, 1)
                                                .background(Color.yellow.opacity(0.85), in: Capsule())
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    isSelected
                                        ? AnyShapeStyle(t.accentGradient)
                                        : AnyShapeStyle(t.cardFill),
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .foregroundColor(isSelected ? .white : (isLocked ? t.secondaryText : t.primaryText))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isSelected ? Color.clear :
                                            (isPremium ? Color.yellow.opacity(0.4) : Color.white.opacity(0.08)),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
                .sheet(isPresented: $showIAPStore) {
                    IAPStoreView()
                        .environmentObject(settings)
                        .environmentObject(JetonManager.shared)
                }

                // Bottom gradient fade + start button
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [t.background.opacity(0), t.background],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 32)

                    Button(action: onStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text(selected != nil ? "\(selected!) ile Oyna" : "Tüm Kategorilerle Oyna")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.white)
                        .shadow(color: t.accent.opacity(0.4), radius: 12, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .background(t.background)
                }
            }
            .navigationTitle("Kategori Seç")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(SettingsViewModel())
        .environmentObject(StatsManager())
        .environmentObject(AchievementManager.shared)
        .environmentObject(JetonManager.shared)
}
