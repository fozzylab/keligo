# HangmanTR — Proje Mimarisi

iOS 17+, SwiftUI, Xcode 16. Türkçe Hangman oyunu.
Bundle ID: `com.yourcompany.hangmantr` (App Store Connect'te güncellenmeli)
App Group: `group.com.yourcompany.hangmantr` (WidgetKit için)

---

## Dosya Haritası

### Çekirdek Yöneticiler (Singleton / ObservableObject)

| Dosya | Sorumluluk |
|---|---|
| `JetonManager.swift` | In-app para birimi. `earn()`, `spend()`, `canAfford()`. UserDefaults'a kaydeder. |
| `StatsManager.swift` | Tüm istatistikler: totalGames, wins, streak, XP/level, categoryWins, bestWord, 30-day calendar, gameHistory (son 50 oyun). `recordWin(category:wrongCount:maxWrong:)` ve `recordLoss(category:)`. |
| `DailyWordManager.swift` | Günlük kelime (tarih bazlı deterministik seçim). `word(for: Date)` herhangi bir tarih için çalışır. `markPlayed(date:won:wrongCount:)` jeton+widget sync sadece bugün için. `calendarDates(for:)` takvim grid'i için. `costPastDay = 30`. |
| `WeeklyChallengeManager.swift` | Haftalık meydan okuma. ISO week bazlı seed. 7 kelime/hafta. `weekWord(for:)`, `weekDates()`, `weekProgress()`, `claimBonus()` (300J). |
| `ChapterManager.swift` | Bölüm verileri ve yıldız kayıtları. `words(for:)`, `recordResult(chapterId:wins:total:)`. |
| `AchievementManager.swift` | Başarım kontrolü. `check(stats:chapters:wrongCount:hintUsed:)`. Tema kilitleri buradan. |
| `IAPManager.swift` | StoreKit 2. Ürünler: jetons500/1500/5000, removeAds, sinemaPack, bilimPack. `isPackUnlocked(_ packId:)`. `handleTransaction()` ile UserDefaults'a `pack_sinema_unlocked` / `pack_bilim_unlocked` yazar. |
| `NotificationManager.swift` | Günlük 09:00 bildirimi. |
| `GameCenterManager.swift` | Game Center auth ve skor gönderimi. |
| `SoundManager.swift` | Ses efektleri. |

### View'lar

| Dosya | Ne gösterir |
|---|---|
| `ContentView.swift` | Root router. `GameBoardView` (tüm modlar paylaşır), `GameContainerView`, `KeyButton` (KeyboardStyle destekli), `JetonActionButton`, `GuessHistoryView`. Rewarded ad butonu GameBoardView içinde. |
| `MainMenuView.swift` | Ana menü. `quickStartCard`, `modeSection`, `heroSection`, `statsStrip`. Tüm mod sheet/overlay'leri buradan açılır. iPad'de 2-sütunlu grid. |
| `DailyGameView.swift` | Günlük mod + tarih parametreli. `AlreadyPlayedView` (zaten oynandıysa gösterilir, replay engellenir). `DailyGameOverView` (streak protection butonu içerir). `presentShareSheet()` global fonksiyon buradadır. |
| `DailyCalendarView.swift` | Aylık takvim grid'i. Geçmiş günler 30J ile oynanabilir. Kilitli/oynanmış/bugün hücre stilleri. `DayResultSheet` sonuç popup'ı. |
| `WeeklyChallengeView.swift` | Haftalık 7-gün listesi. İlerleme bar. Tüm hafta bitince 300J ödül butonu. |
| `ChapterGameView.swift` | Bölüm modu. `ChapterGameOverView`, `ChapterSummaryView`. |
| `SpeedModeView.swift` | Hız modu. `SpeedGameState` ObservableObject. 30/60/90s seçim. |
| `ChapterSelectView.swift` | Bölüm seçimi. Kilitli/açık bölümler, yıldız gösterimi. |
| `StatsView.swift` | İstatistikler. XP/level, 30-day calendar, category bars, oyun geçmişi butonu. |
| `GameHistoryView.swift` | Son 50 oyun listesi. Kelime, kategori, sonuç, tarih, hata sayısı. |
| `SettingsView.swift` | Klavye tarzı (glass/flat/minimal/colorful), tema, zorluk, ses, bildirim, kelime filtresi, iCloud sync. |
| `OnboardingView.swift` | 5 sayfalık onboarding. Sayfa 3: mod seçimi. |
| `AchievementsView.swift` | Başarım listesi. |
| `FriendChallengeView.swift` | Arkadaşa Sor. Caesar cipher (offset 7). `CreateChallengeView` + `PlayChallengeView` + `DeepLinkChallengeView`. URL scheme: `hangmantr://challenge/CODE`. `presentShareSheet()` kullanır (beyaz ekran yok). |
| `IAPStoreView.swift` | Jeton Mağazası (IAPManager.swift içinde tanımlı). |
| `PremiumPacksView.swift` | Sinema & Bilim premium kelime paketleri. |
| `SplashView.swift` | Açılışta 2.1s animasyonlu karşılama ekranı. `ContentView`'da `showSplash` state ile yönetilir. |

### Yardımcı Dosyalar

| Dosya | İçerik |
|---|---|
| `AppTheme.swift` | `AppTheme` enum + `KeyboardStyle` enum (glass/flat/minimal/colorful). `isDark`, `accent`, `cardMaterial`, `accentGradient`, `glowColor`. |
| `WordList.swift` | ~950+ kelime, 22 kategori. Kategoriler: Hayvanlar, Meslekler, Yiyecekler, Şehirler, Mitoloji, Meyveler, Taşıtlar, Gezegenler, Sanat, Tarih, Bitkiler, **Spor, Müzik, Coğrafya, Teknoloji** (yeni). Premium: Sinema, Bilim. `random(for:category:minLength:maxLength:kidsMode:)` ile O(1) seçim. |
| `HangmanDrawing.swift` | Canvas-based adam çizimi. |
| `ShareCardView.swift` | `GameShareCard` + `ChapterShareCard`. `renderShareImage<V>()` → UIImage. |
| `ConfettiView.swift` | Kazanma animasyonu. |
| `SettingsViewModel.swift` | `soundEnabled`, `hapticEnabled`, `theme`, `difficulty`, `preferredMode`, `speedDuration`, `wordLengthMin/Max`, `kidsMode`, `dailyNotification`, `iCloudSync`, `keyboardStyle`. |

---

## ViewModel

### GameViewModel
- `fixedEntry: WordEntry?` — nil ise sonsuz mod (random), değilse daily/chapter/challenge
- `kidsMode: Bool` — 3-6 harf filtresi
- `canSkip: Bool` — fixedEntry == nil ise true
- `guessHistory: [(letter, wasCorrect)]`
- `canWatchRewardedAd: Bool` — oyun devam ediyor + tahmin edilmemiş doğru harf var
- `watchRewardedAdReward()` — rastgele doğru harf açar (AdMob stub)
- **Jeton aksiyonları:** `buyVowel()` 200J, `buyLetter()` 100J, `skipWord()` 50J, `undo()` 100J
- `startNewGame()` → `WordList.random(for:category:minLength:maxLength:kidsMode:)`

### WeeklyChallengeManager
- ISO week bazlı seed: `year * 100 + weekOfYear`
- Her günün kelimesi: `wordIndex = (weekSeed * 7 + dayOffset) % WordList.words.count`
- UserDefaults: `"weekly_YYYY_WW_D_won"`, `"weekly_YYYY_WW_bonus"`
- `claimBonus()` → 300J, bir kez

### SpeedGameState
- Ayrı `ObservableObject`, `GameViewModel` kullanmaz

---

## Ekonomi

```
Kazanma: +10J | Günlük: +25J | Her 5 galibiyet serisi: +50J
Haftalık tüm: +300J
Geçmiş gün oynama: -30J
Sesli harf: -200J | Harf al / Geri al: -100J | Pas: -50J | Seri koruma: -50J
```

Streak Milestone Ödülleri:
- 3 gün → 30J | 7 gün → 100J | 14 gün → 200J | 30 gün → 500J | 50 gün → 750J | 100 gün → 1500J

XP: Galibiyet +20 (+hata bonusu max 18) | Mağlubiyet +5
Level: `Int((-1 + sqrt(1 + 8·xp/100)) / 2) + 1`

---

## Kritik Pattern'ler

### Environment Injection (HangmanTRApp.swift)
```swift
.environmentObject(settings)   // SettingsViewModel
.environmentObject(stats)       // StatsManager
.environmentObject(achievements) // AchievementManager
.environmentObject(jetons)      // JetonManager
.environmentObject(iap)         // IAPManager
```

### Share Sheet (beyaz ekran yok!)
```swift
// DailyGameView.swift'te global fonksiyon — tüm dosyalardan erişilir
func presentShareSheet(_ items: [Any]) {
    // UIWindowScene → rootVC → topMost → present(UIActivityViewController)
}
// ASLA .sheet { ShareSheet(...) } kullanma — nested sheet'te beyaz ekran olur
```

### AnyShapeStyle pattern (ternary ile Material/Color)
```swift
.background(
    condition ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.cardMaterial),
    in: RoundedRectangle(cornerRadius: 16)
)
```

### Daily/Weekly Kelime Seçimi (Deterministik)
```swift
// Aynı tarih → her zaman aynı kelime
let seed = UInt64(year * 10000 + month * 100 + day)
var rng = SeededRNG(seed: seed)
let word = WordList.words.randomElement(using: &rng)!
```

### Streak Protection
`recordLoss()` → `streakBeforeLoss = currentStreak` kaydeder.
`useStreakProtection()` → 50J harcar, `currentStreak = streakBeforeLoss` restore eder.
`DailyGameOverView`'de kayıp sonrası buton gösterilir.

### Türkçe Sesli Harfler
```swift
private let turkishVowels: Set<Character> = ["A","E","I","İ","O","Ö","U","Ü"]
```

### Color Literal (Swift shorthand çalışmaz!)
```swift
// YANLIŞ: Color(red:1,.45,.10)
// DOĞRU:
Color(red: 1.0, green: 0.45, blue: 0.10)
```

### iPad Layout
```swift
@Environment(\.horizontalSizeClass) var sizeClass
var isIPad: Bool { sizeClass == .regular }
// MainMenuView modeSection: iPad'de LazyVGrid 2-sütun
// GameBoardView: hangmanSize iPad=220, iPhone=160
```

---

## Xcode'da Manuel Yapılması Gerekenler

1. **iCloud Key-Value Storage**: Target → Signing & Capabilities → iCloud → Key-value storage ✓
2. **URL Scheme**: Target → Info → URL Types → `hangmantr` (deep link için)
3. **App Group**: `group.com.yourcompany.hangmantr` (widget için)
4. **Bundle ID**: `com.yourcompany.hangmantr` → gerçek bundle ID ile değiştir
5. **AdMob**: SDK henüz eklenmedi — stub var, entegrasyon sonraya bırakıldı

---

## Easter Egg

⚰️ emojisine `MainMenuView`'da 10 kez hızlı (<1.5s aralıklı) dokunulunca:
- İlk kez: 100 jeton (`easterEggUnlocked` AppStorage ile bir kez)
- Her seferinde: `EasterEggToast` gösterilir
- `eggTapCount`, `eggLastTap`, `eggShake` state'leri kullanılır

## Davet Sistemi

`DavetView` (MainMenuView.swift içinde) — "Arkadaşını Davet Et" modu:
- Günlük bir kez paylaşınca 50 jeton (`davetUsedDate` AppStorage ile günlük reset)
- `presentShareSheet()` ile sistem share sheet açılır (beyaz ekran yok)
- App Store linki placeholder: `https://apps.apple.com/app/hangman-tr`

## Henüz Yapılmayanlar
- AdMob gerçek entegrasyonu (stub var)
- App icon ve screenshots
- App Store Connect ürün ID'leri gerçek bundle ID ile
- Push notification için APNs sertifikası
