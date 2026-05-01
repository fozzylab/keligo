# Keligo — Project Context

## Stack
- iOS 17+, SwiftUI, Xcode 16, Swift 5.9
- StoreKit 2, ActivityKit (iOS 16.1+), GameKit, AVFoundation
- No third-party dependencies (AdMob stub only)
- Bundle ID: `com.fozzylabs.keligo` | App Group: `group.com.fozzylabs.keligo`

## Singletons (never recreate, always `.shared`)
- `JetonManager` — in-app currency
- `StatsManager` — all stats + XP + streaks
- `LivesManager` — 5-heart system, 30min regen
- `AdManager` — interstitial/rewarded stub (caps enforced)
- `IAPManager` — StoreKit 2 products
- `SoundManager` — AVAudioPlayer preloaded CAF files
- `AchievementManager`, `DailyWordManager`, `WeeklyChallengeManager`, `ChapterManager`

## Environment (injected at root in `KeligoApp.swift`)
`SettingsViewModel`, `StatsManager`, `AchievementManager`, `JetonManager`, `IAPManager`

## Critical Patterns
```swift
// Share sheet (NEVER use .sheet — causes white screen)
presentShareSheet(_ items: [Any])  // global func in DailyGameView.swift

// Ternary background with mixed types
.background(condition ? AnyShapeStyle(gradient) : AnyShapeStyle(material), in: RoundedRectangle(...))

// Deterministic daily word seed
var rng = SeededRNG(seed: UInt64(year*10000 + month*100 + day))

// Turkish vowels
let turkishVowels: Set<Character> = ["A","E","I","İ","O","Ö","U","Ü"]

// Color literal (Swift shorthand breaks)
Color(red: 1.0, green: 0.45, blue: 0.10)  // NOT Color(red:1,.45,.10)
```

## Simulator Guards
```swift
#if !targetEnvironment(simulator)
// iCloud, AdMob, etc.
#endif
```

## Economy (quick ref)
| Action | Jeton |
|---|---|
| Win | +15 |
| Daily | +25 |
| Streak ×5 | +50 |
| Harf Al | −100 |
| Sesli Harf | −200 |
| Can refill ×1 | −50 |
| Can refill full | −200 |

## Sounds — `Keligo/Sounds/*.caf`
`correct` `wrong` `win` `lose` `hint` `button_tap` `skip`

## Do Not
- Use `AudioServicesPlaySystemSound` (replaced by AVFoundation)
- Nest `.sheet` inside `.sheet`
- Use `git add -A` (repo has `.DS_Store`, raw wav files)
- Touch `WordList.swift` seed logic without regression check
