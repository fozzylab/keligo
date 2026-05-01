# Architecture

## Layer Map
```
KeligoApp.swift
  └─ SplashView → FozzyLabsIntroView → OnboardingView → MainMenuView
       └─ [mode sheets] → ContentView (GameBoardView)
```

## Data Flow
- Singletons own state, Views observe via `@EnvironmentObject` / `@ObservedObject`
- `GameViewModel` owns active game; created fresh per session
- `UserDefaults` = primary persistence; `NSUbiquitousKeyValueStore` = iCloud mirror

## Key Files by Concern
| Concern | File |
|---|---|
| Game UI (board + keyboard) | `ContentView.swift` |
| Main menu + mode routing | `MainMenuView.swift` |
| Daily calendar sheet | `DailyCalendarView.swift` |
| Hangman canvas | `KeligoDrawing.swift` |
| Theme + keyboard style | `AppTheme.swift` |
| All settings state | `SettingsViewModel.swift` |
| Word data (22 cats, 950+ words) | `WordList.swift` |

## Game Modes & Entry Points
| Mode | View | VM |
|---|---|---|
| Sonsuz | `ContentView` via `GameContainerView` | `GameViewModel(fixedEntry: nil)` |
| Günlük | `DailyGameView` | `GameViewModel(fixedEntry: dailyWord)` |
| Bölüm | `ChapterGameView` | `GameViewModel(fixedEntry: chapterWord)` |
| Hız | `SpeedModeView` | `SpeedGameState` (own ObservableObject) |
| Çocuk | `ContentView` | `GameViewModel(kidsMode: true)` |
| Haftalık | `WeeklyChallengeView` | `GameViewModel(fixedEntry: weekWord)` |

## IAP Products
`jetons500/1500/5000` · `removeAds` · `unlimitedLives` · `premiumBundle`
`sinemaPack` · `bilimPack` · `tarihPlusPack` · `sporYildizlariPack` · `muzikProPack` · `themePackPremium`

## Widget / Live Activity
- `KeligoWidgetExtension/` — home screen widgets (streak, daily word)
- `KeligoLiveActivityWidget.swift` — lock screen live activity (daily mode only)
- Attributes: `DailyWordActivityAttributes` in `LiveActivity.swift`

## Lives Anti-Cheat (3 layers)
1. Forward-only wall clock ratchet
2. `ProcessInfo.systemUptime` cross-check (same boot)
3. iCloud KV anchor (cross-device)
