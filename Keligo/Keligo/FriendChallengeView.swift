import SwiftUI

// MARK: - Challenge encoder/decoder
// Simple Caesar cipher with offset 7 for the word, base64 the result

struct ChallengeCodec {
    static func encode(word: String) -> String {
        let upper = word.uppercased()
        let shifted = upper.unicodeScalars.map { scalar -> Character in
            let base: UInt32 = 65 // 'A'
            if scalar.value >= 65 && scalar.value <= 90 {
                return Character(UnicodeScalar((scalar.value - base + 7) % 26 + base)!)
            }
            return Character(scalar)
        }
        let encoded = String(shifted)
        // Add a checksum character (sum of char values mod 26 + 'A')
        let sum = upper.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let checkChar = Character(UnicodeScalar(UInt32(65 + (sum % 26)))!)
        let result = encoded + String(checkChar)
        // Format as XXX-XXX style
        if result.count >= 6 {
            let idx3 = result.index(result.startIndex, offsetBy: 3)
            let idx6 = result.index(result.startIndex, offsetBy: min(6, result.count))
            return String(result[result.startIndex..<idx3]) + "-" + String(result[idx3..<idx6])
                + (result.count > 6 ? "-" + String(result[idx6...]) : "")
        }
        return result
    }

    static func decode(code: String) -> String? {
        let clean = code.uppercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard clean.count >= 2 else { return nil }
        // Remove checksum (last char)
        let wordPart = String(clean.dropLast())
        let shifted = wordPart.unicodeScalars.map { scalar -> Character in
            let base: UInt32 = 65
            if scalar.value >= 65 && scalar.value <= 90 {
                let v = scalar.value < base + 7 ? scalar.value + 26 - 7 : scalar.value - 7
                return Character(UnicodeScalar(v)!)
            }
            return Character(scalar)
        }
        return String(shifted)
    }
}

// MARK: - Create challenge view

struct CreateChallengeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var wordInput = ""
    @State private var selectedCategory = "Meydan Okuma"
    @State private var generatedCode = ""
    @State private var error = ""

    var t: AppTheme { settings.theme }

    private var allCategories: [String] {
        ["Meydan Okuma"] + WordList.categories
    }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Instruction
                        VStack(spacing: 8) {
                            Text("🤝")
                                .font(.system(size: 56))
                            Text("Arkadaşına Meydan Oku")
                                .font(.title2.weight(.black))
                                .foregroundColor(t.primaryText)
                                .multilineTextAlignment(.center)
                            Text("Bir kelime seç, kodunu paylaş.\nArkadaşın bu kelimeyi tahmin etsin!")
                                .font(.subheadline)
                                .foregroundColor(t.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Word input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kelimen")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.secondaryText)

                            TextField("Türkçe kelime gir...", text: $wordInput)
                                .font(.title3.weight(.bold))
                                .foregroundColor(t.primaryText)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(t.surface, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: wordInput) { _, val in
                                    wordInput = val.uppercased()
                                    error = ""
                                    generatedCode = ""
                                }

                            if !error.isEmpty {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(t.wrong)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Category picker (optional hint)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori İpucu (opsiyonel)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.secondaryText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(allCategories, id: \.self) { cat in
                                        Button {
                                            selectedCategory = cat
                                            generatedCode = ""
                                        } label: {
                                            Text(cat)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(selectedCategory == cat ? .white : t.secondaryText)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(
                                                    selectedCategory == cat
                                                        ? AnyShapeStyle(t.accentGradient)
                                                        : AnyShapeStyle(t.surface),
                                                    in: Capsule()
                                                )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        // Generate button
                        Button {
                            generateCode()
                        } label: {
                            Label("Kod Oluştur", systemImage: "qrcode")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                        .disabled(wordInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(wordInput.isEmpty ? 0.5 : 1)

                        // Generated code
                        if !generatedCode.isEmpty {
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("Meydan Okuma Kodu")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(t.secondaryText)
                                    Text(generatedCode)
                                        .font(.system(size: 36, weight: .black, design: .monospaced))
                                        .foregroundColor(t.primaryText)
                                        .tracking(4)
                                    if selectedCategory != "Meydan Okuma" {
                                        Text("Kategori: \(selectedCategory)")
                                            .font(.caption)
                                            .foregroundColor(t.accent)
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(t.surface, in: RoundedRectangle(cornerRadius: 16))

                                Button {
                                    let cleanCode = generatedCode.replacingOccurrences(of: "-", with: "")
                                    let deepLink  = "keligo://challenge/\(cleanCode)"
                                    let catHint   = selectedCategory != "Meydan Okuma" ? "\n🗂️ Kategori ipucu: \(selectedCategory)" : ""
                                    let text = """
                                    🎯 Keligo'de sana meydan okuyorum!

                                    Kelimemi tahmin edebilir misin? 🤔\(catHint)

                                    👉 Uygulamada "Arkadaşa Sor" → "Kodu Gir" bölümüne git
                                    🔑 Kod: \(generatedCode)

                                    📲 Ya da bu linke dokun:
                                    \(deepLink)

                                    #Keligo
                                    """
                                    presentShareSheet([text])
                                } label: {
                                    Label("Kodu Paylaş", systemImage: "square.and.arrow.up")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                                        .foregroundColor(t.primaryText)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Meydan Oku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
        }
    }

    private func generateCode() {
        let word = wordInput.trimmingCharacters(in: .whitespaces)
        guard word.count >= 2 else { error = "En az 2 harf gerekli"; return }
        guard word.count <= 14 else { error = "En fazla 14 harf olabilir"; return }
        generatedCode = ChallengeCodec.encode(word: word)
    }
}

// MARK: - Play challenge view

struct PlayChallengeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    @State private var codeInput = ""
    @State private var decodedWord = ""
    @State private var error = ""
    @State private var vm: GameViewModel? = nil
    @State private var showGame = false

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                if showGame, let gameVM = vm {
                    GameBoardView(
                        vm: gameVM,
                        theme: t,
                        modeLabel: "🤝 Arkadaş Meydan Okuma",
                        onBack: {
                            showGame = false
                            vm = nil
                            codeInput = ""
                            decodedWord = ""
                        }
                    ) {
                        challengeGameOverOverlay(gameVM: gameVM)
                    }
                    .transition(.move(edge: .trailing))
                } else {
                    VStack(spacing: 28) {
                        VStack(spacing: 10) {
                            Text("🔑")
                                .font(.system(size: 56))
                            Text("Kodu Gir")
                                .font(.title2.weight(.black))
                                .foregroundColor(t.primaryText)
                            Text("Arkadaşının paylaştığı kodu gir\nve kelimesini tahmin et!")
                                .font(.subheadline)
                                .foregroundColor(t.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meydan Okuma Kodu")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(t.secondaryText)

                            TextField("ABC-DEF-G", text: $codeInput)
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(t.primaryText)
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(16)
                                .background(t.surface, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: codeInput) { _, _ in error = "" }

                            if !error.isEmpty {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(t.wrong)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        Button { startChallenge() } label: {
                            Label("Oyunu Başlat", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .shadow(color: t.accent.opacity(0.4), radius: 12, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                        .disabled(codeInput.isEmpty)
                        .opacity(codeInput.isEmpty ? 0.5 : 1)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Meydan Okuma Oyna")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showGame)
        }
    }

    private func startChallenge() {
        guard let word = ChallengeCodec.decode(code: codeInput), word.count >= 2 else {
            error = "Geçersiz kod. Lütfen tekrar kontrol et."
            return
        }
        let entry = WordEntry(word: word, category: "Meydan Okuma")
        let gameVM = GameViewModel(settings: settings, stats: stats, fixedEntry: entry)
        vm = gameVM
        withAnimation(.easeInOut) { showGame = true }
    }

    // Game over overlay specific to friend challenges
    @ViewBuilder
    private func challengeGameOverOverlay(gameVM: GameViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(gameVM.gameState == .won ? "🎉" : "💀")
                    .font(.system(size: 64))

                Text(gameVM.gameState == .won ? "Tebrikler!" : "Olmadı!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(gameVM.gameState == .won
                     ? "Kelimeyi \(gameVM.wrongGuesses) hatayla buldun!"
                     : "Kelime: \(gameVM.currentWord)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                // Share result button
                Button {
                    let won = gameVM.gameState == .won
                    let emoji = won ? "🟩" : "🟥"
                    let wrongRow = (0..<gameVM.maxWrongGuesses).map {
                        $0 < gameVM.wrongGuesses ? "⬛" : "⬜"
                    }.joined()
                    let text = """
                    🤝 Arkadaşın meydan okumasını \(won ? "kazandım" : "kaybettim")!
                    \(emoji) \(wrongRow)
                    \(won ? "\(gameVM.wrongGuesses) hata ile çözdüm 💪" : "Çözemedim 😅")
                    #Keligo
                    """
                    presentShareSheet([text])
                } label: {
                    Label("Sonucu Paylaş", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    showGame = false
                    vm = nil
                } label: {
                    Text("Kapat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Friend challenge hub

struct FriendChallengeView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCreate = false
    @State private var showPlay   = false

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                RadialGradient(colors: [t.glowColor, .clear], center: .top, startRadius: 0, endRadius: 300)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("🤝")
                        .font(.system(size: 72))
                        .padding(.top, 40)

                    Text("Arkadaşa Sor")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(t.primaryText)

                    Text("Birbirinize kelime sorun, kodu paylaşın!")
                        .font(.subheadline)
                        .foregroundColor(t.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 14) {
                        Button { showCreate = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(t.accentGradient)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Meydan Oku")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(t.primaryText)
                                    Text("Bir kelime seç ve kodu oluştur")
                                        .font(.caption)
                                        .foregroundColor(t.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(t.secondaryText)
                            }
                            .padding(18)
                            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button { showPlay = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "key.fill")
                                    .font(.title2)
                                    .foregroundStyle(t.accentGradient)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Kodu Gir")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(t.primaryText)
                                    Text("Arkadaşının kodunu girerek oyna")
                                        .font(.caption)
                                        .foregroundColor(t.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(t.secondaryText)
                            }
                            .padding(18)
                            .background(t.cardMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Arkadaşa Sor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
            .sheet(isPresented: $showCreate) { CreateChallengeView() }
            .sheet(isPresented: $showPlay)   { PlayChallengeView() }
        }
    }
}

// MARK: - Deep link entry point (URL scheme: keligo://challenge/CODE)
// ⚠️ URL scheme'i aktif etmek için: Xcode → Target → Info → URL Types → "+" → URL Schemes: keligo

struct DeepLinkChallengeView: View {
    let code: String
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var jetons: JetonManager
    @Environment(\.dismiss) private var dismiss

    @State private var vm: GameViewModel? = nil
    @State private var showGame = false
    @State private var errorMessage = ""

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                if showGame, let gameVM = vm {
                    GameBoardView(
                        vm: gameVM,
                        theme: t,
                        modeLabel: "🤝 Meydan Okuma",
                        onBack: { dismiss() }
                    ) {
                        InfiniteGameOverView(vm: gameVM, theme: t, onBack: { dismiss() })
                    }
                } else {
                    VStack(spacing: 24) {
                        Text("🔑").font(.system(size: 64)).padding(.top, 40)
                        Text("Meydan Okuma").font(.title2.bold()).foregroundColor(t.primaryText)
                        Text("Kod: \(code)")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundColor(t.accent)
                            .padding(16)
                            .background(t.surface, in: RoundedRectangle(cornerRadius: 12))

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.caption).foregroundColor(.red)
                        }

                        Button { startGame() } label: {
                            Label("Oyna!", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
            .onAppear { startGame() }
            .animation(.easeInOut(duration: 0.3), value: showGame)
        }
    }

    private func startGame() {
        guard let word = ChallengeCodec.decode(code: code), word.count >= 2 else {
            errorMessage = "Geçersiz kod."
            return
        }
        let entry = WordEntry(word: word, category: "Meydan Okuma")
        vm = GameViewModel(settings: settings, stats: stats, fixedEntry: entry)
        withAnimation { showGame = true }
    }
}
