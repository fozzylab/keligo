# Gameplay Mechanics

## Core Loop (all modes)
1. Word selected → letters hidden as `_`
2. Player taps letter on keyboard
3. Correct → reveal in word; Wrong → `wrongCount++`, draw hangman part
4. Win: all letters revealed | Lose: `wrongCount == maxWrong` (default 6)
5. Result → record stats → jeton award → achievement check

## `GameViewModel` State Machine
```
idle → playing → [won | lost]
```
- `gameState: GameState` drives UI transitions
- `guessedLetters: Set<Character>` — prevents double-tap
- `wrongCount`, `maxWrong` — hangman progress
- `fixedEntry: WordEntry?` — nil = random (Sonsuz), set = daily/chapter/challenge

## Hint System (costs jetons)
| Hint | Cost | Effect |
|---|---|---|
| Harf Al | 100J | Reveal random unrevealed consonant |
| Sesli Harf | 200J | Reveal random unrevealed vowel |
| Geri Al | 75J | Un-guess last wrong letter |
| Pas | 50J | Skip word (Sonsuz only) |
| Rewarded Ad | free | Reveal 1 letter (cap: 5/day) |

## Lives System (Sonsuz / Hız / Çocuk only)
- Max 5 hearts; lose 1 per lost game
- Regen: 1 heart per 30 min (timer-based, anti-cheat protected)
- Refill: 50J (×1) or 200J (full) or rewarded ad (cap: 3/day)
- Daily / Bölüm / Haftalık modes are **lives-immune**

## Daily Word Rules
- Deterministic: same word for all users on same date (UTC+3 seed)
- One attempt per day; replay blocked after completion
- Past days unlockable for 30J (up to 30 days back)
- Daily word pool = **free categories only** (no premium packs)

## Streak Logic
- `currentStreak++` on any win; reset to 0 on loss
- Streak protection: spend 75J or watch ad (1/day) to restore after loss
- Milestones: 3/7/14/30/50/100 days → 30/100/250/600/1000/2000J bonus

## XP & Level
- Win: `+20 + max(0, maxWrong - wrongCount) * 3` (up to +38)
- Loss: +5 (consolation)
- Level formula: `Int((-1 + sqrt(1 + 8·xp/100)) / 2) + 1`

## Weekly Challenge
- 7 words, one per day, ISO week seed
- All 7 complete → claim 400J bonus (once per week)

## Speed Mode
- Separate `SpeedGameState` (not GameViewModel)
- 30 / 60 / 90s durations; unlimited skips; score = words solved
- High score tracked in `StatsManager.speedHighScore`

## Interstitial Ad Policy
- Every 4th game end (won or lost)
- Min 75s cooldown between ads
- First 3 games ever = ad-free
- Never after daily game; never if `isAdsRemoved`
