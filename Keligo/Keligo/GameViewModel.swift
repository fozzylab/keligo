import Foundation
import Combine

enum GameState { case playing, won, lost }

private let turkishVowels: Set<Character> = ["A","E","I","İ","O","Ö","U","Ü"]

class GameViewModel: ObservableObject {
    @Published var currentWord: String = ""
    @Published var category: String = ""
    @Published var guessedLetters: Set<Character> = []
    @Published var wrongGuesses: Int = 0
    @Published var gameState: GameState = .playing
    @Published var hintsRemaining: Int = 2
    @Published var maxWrongGuesses: Int = 6
    @Published var lastCorrectLetter: Character? = nil
    @Published var hintUsed: Bool = false
    @Published var guessHistory: [(letter: Character, wasCorrect: Bool)] = []
    /// Kelime ipucu — 50 jeton ile açılır, oyun boyunca saklı kalır
    @Published var wordHintRevealed: Bool = false

    private let settings: SettingsViewModel
    let stats: StatsManager
    private let sound = SoundManager.shared
    private var fixedEntry: WordEntry?
    private var categoryFilter: String?
    private var kidsMode: Bool
    /// `true` ise kayıp anında `LivesManager.shared.loseOne()` çağrılır.
    /// Sonsuz / Çocuk modunda true, Daily / Chapter / Speed'de false.
    private var countsAgainstLives: Bool

    // MARK: - Computed state

    var canSkip: Bool { fixedEntry == nil }

    var hasUnrevealedVowels: Bool {
        currentWord.contains { turkishVowels.contains($0) && !guessedLetters.contains($0) }
    }

    var displayWord: [Character] {
        currentWord.map { guessedLetters.contains($0) ? $0 : "_" }
    }

    var wrongLetters: [Character] {
        guessedLetters.filter { $0 != " " && !currentWord.contains($0) }.sorted()
    }

    /// Kelime için ipucu metni (varsa). nil ise bu kelimede ipucu yok.
    var wordHintText: String? { WordList.hint(for: currentWord) }

    /// İpucu butonu gösterilsin mi?
    var canBuyHint: Bool { wordHintText != nil && !wordHintRevealed && gameState == .playing }

    // MARK: - Init

    init(settings: SettingsViewModel, stats: StatsManager,
         fixedEntry: WordEntry? = nil, categoryFilter: String? = nil,
         kidsMode: Bool = false, countsAgainstLives: Bool = false) {
        self.settings = settings
        self.stats = stats
        self.fixedEntry = fixedEntry
        self.categoryFilter = categoryFilter
        self.kidsMode = kidsMode
        self.countsAgainstLives = countsAgainstLives
        startNewGame()
    }

    // MARK: - Public game actions

    func startNewGame() {
        let entry = fixedEntry ?? WordList.random(
            for: settings.difficulty,
            category: categoryFilter,
            minLength: settings.wordLengthMin,
            maxLength: settings.wordLengthMax,
            kidsMode: kidsMode || settings.kidsMode
        )
        setupGame(entry)
    }

    func loadWord(_ entry: WordEntry) {
        setupGame(entry)
    }

    func guess(_ letter: Character) {
        guard gameState == .playing, !guessedLetters.contains(letter) else { return }
        performGuess(letter, playFeedback: true)
    }

    func useHint() {
        guard hintsRemaining > 0, gameState == .playing else { return }
        guard let hint = unguessedPool().randomElement() else { return }
        hintsRemaining -= 1
        hintUsed = true
        syncSound()
        sound.playHint()
        performGuess(hint, playFeedback: false)
    }

    // MARK: - Jeton purchases

    /// Kelime ipucunu açar (50 🪙). Kelimede ipucu yoksa false döner.
    @discardableResult
    func buyHint() -> Bool {
        guard wordHintText != nil, !wordHintRevealed, gameState == .playing else { return false }
        guard JetonManager.shared.spend(JetonManager.costHint) else { return false }
        hintUsed = true
        wordHintRevealed = true
        syncSound()
        sound.playHint()
        Task { @MainActor in AppPromptManager.shared.notifyHintSpent(amount: JetonManager.costHint) }
        return true
    }

    @discardableResult
    func buyVowel() -> Bool {
        let unrevealed = Set(currentWord.filter { turkishVowels.contains($0) && !guessedLetters.contains($0) })
        guard !unrevealed.isEmpty else { return false }
        guard JetonManager.shared.spend(JetonManager.costVowel) else { return false }
        hintUsed = true
        syncSound()
        sound.playHint()
        for v in unrevealed { guessedLetters.insert(v) }
        lastCorrectLetter = unrevealed.first
        if displayWord.allSatisfy({ $0 != "_" }) {
            gameState = .won
            sound.playWin()
            stats.recordWin(category: category)
            recordHistory(mode: "Sonsuz")
        }
        Task { @MainActor in AppPromptManager.shared.notifyHintSpent(amount: JetonManager.costVowel) }
        return true
    }

    @discardableResult
    func buyLetter() -> Bool {
        let pool = unguessedPool()
        guard !pool.isEmpty else { return false }
        guard JetonManager.shared.spend(JetonManager.costLetter) else { return false }
        hintUsed = true
        syncSound()
        sound.playHint()
        performGuess(pool.randomElement()!, playFeedback: false)
        Task { @MainActor in AppPromptManager.shared.notifyHintSpent(amount: JetonManager.costLetter) }
        return true
    }

    func skipWord() {
        guard canSkip else { return }
        guard JetonManager.shared.spend(JetonManager.costSkip) else { return }
        syncSound()
        sound.playButtonTap()
        startNewGame()
    }

    // MARK: - Private helpers

    private func setupGame(_ entry: WordEntry) {
        maxWrongGuesses = settings.difficulty.maxWrongGuesses
        hintsRemaining  = settings.difficulty.hintCount
        currentWord     = entry.word
        category        = entry.category
        wrongGuesses    = 0
        gameState       = .playing
        lastCorrectLetter = nil
        hintUsed        = false
        wordHintRevealed = false

        var initial: Set<Character> = []
        if currentWord.contains(" ") { initial.insert(" ") }

        let letters    = Set(currentWord.filter { $0 != " " })
        let vowels     = letters.filter {  turkishVowels.contains($0) }
        let consonants = letters.filter { !turkishVowels.contains($0) }

        switch settings.difficulty {
        case .easy:
            // Reveal 1 random vowel + 1 random consonant upfront
            if let v = vowels.shuffled().first     { initial.insert(v) }
            if let c = consonants.shuffled().first { initial.insert(c) }
        case .normal:
            // Reveal 1 random vowel
            if let v = vowels.shuffled().first { initial.insert(v) }
        case .hard:
            break
        }

        guessedLetters = initial
        guessHistory = []
    }

    /// Pool of unrevealed letters — prefers consonants so hints feel useful.
    private func unguessedPool() -> [Character] {
        let all = Set(currentWord.filter { $0 != " " && !guessedLetters.contains($0) })
        let consonants = all.filter { !turkishVowels.contains($0) }
        return Array(consonants.isEmpty ? all : consonants)
    }

    func undo() {
        guard !guessHistory.isEmpty, gameState == .playing else { return }
        guard JetonManager.shared.spend(JetonManager.costUndo) else { return }
        let last = guessHistory.removeLast()
        guessedLetters.remove(last.letter)
        if !last.wasCorrect && wrongGuesses > 0 {
            wrongGuesses -= 1
        }
        syncSound()
        sound.playHint()
        Task { @MainActor in AppPromptManager.shared.notifyHintSpent(amount: JetonManager.costUndo) }
    }

    var canUndo: Bool {
        !guessHistory.isEmpty && gameState == .playing
    }

    // MARK: - Continue After Loss (2026 monetization)
    
    func continueAfterLoss() {
        guard gameState == .lost, wrongGuesses > 0 else { return }
        wrongGuesses -= 1
        gameState = .playing
        SoundManager.shared.playHint()
    }
    
    // MARK: - Rewarded ad helpers

    var canWatchRewardedAd: Bool {
        gameState == .playing && revealableLetterExists
    }

    private var revealableLetterExists: Bool {
        currentWord.unicodeScalars.contains { scalar in
            let ch = Character(scalar)
            return !guessedLetters.contains(ch)
        }
    }

    func watchRewardedAdReward() {
        let unguessed = currentWord.filter { !guessedLetters.contains($0) }
        guard let letter = unguessed.randomElement() else { return }
        guess(letter)
    }

    // MARK: - Game history recording

    private func recordHistory(mode: String) {
        let entry = GameHistoryEntry(
            word: currentWord, category: category,
            won: gameState == .won, wrongCount: wrongGuesses,
            maxWrong: maxWrongGuesses, mode: mode
        )
        stats.addHistory(entry)
    }

    private func performGuess(_ letter: Character, playFeedback: Bool) {
        guessedLetters.insert(letter)
        let wasCorrect = currentWord.contains(letter)
        guessHistory.append((letter: letter, wasCorrect: wasCorrect))
        syncSound()

        if !currentWord.contains(letter) {
            wrongGuesses += 1
            if playFeedback { sound.playWrong() }
            if wrongGuesses >= maxWrongGuesses {
                gameState = .lost
                sound.playLose()
                stats.recordLoss()
                recordHistory(mode: "Sonsuz")
                settings.recordAdaptiveResult(won: false)
                if countsAgainstLives {
                    LivesManager.shared.loseOne()
                }
            }
        } else {
            lastCorrectLetter = letter
            if playFeedback { sound.playCorrect() }
            if displayWord.allSatisfy({ $0 != "_" }) {
                gameState = .won
                sound.playWin()
                stats.recordWin(category: category)
                recordHistory(mode: "Sonsuz")
                settings.recordAdaptiveResult(won: true)
            }
        }
    }

    private func syncSound() {
        sound.soundEnabled  = settings.soundEnabled
        sound.hapticEnabled = settings.hapticEnabled
    }
}
