import XCTest

final class KeligoScreenshots: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "true"]
    }

    @MainActor
    func testWinScreen() throws {
        let screenshotDir = "/Users/fatihozer/Desktop/ios-game/screenshots"

        app.launch()
        Thread.sleep(forTimeInterval: 4.5)

        // Go to Sonsuz Mod
        let sonsuzMod = app.staticTexts["Sonsuz Mod"]
        guard sonsuzMod.waitForExistence(timeout: 5) else { return }
        sonsuzMod.tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Tap "Tüm Kategorilerle Oyna"
        let playBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'ile Oyna' OR label CONTAINS 'Kategorilerle'")).firstMatch
        guard playBtn.waitForExistence(timeout: 3) else { return }
        playBtn.tap()
        Thread.sleep(forTimeInterval: 1.5)

        // Buy letters repeatedly to reveal all and win
        var wonGame = false
        for attempt in 0..<25 {
            // Check if we already won
            let kazandinText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Kazandın' OR label CONTAINS 'Tebrik' OR label CONTAINS 'KAZANDIN'")).firstMatch
            if kazandinText.exists {
                Thread.sleep(forTimeInterval: 0.5)
                takeScreenshot(name: "WIN_screen", dir: screenshotDir)
                wonGame = true
                break
            }

            let harfAlBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Harf Al'")).firstMatch
            if harfAlBtn.exists && harfAlBtn.isEnabled && harfAlBtn.isHittable {
                harfAlBtn.tap()
                Thread.sleep(forTimeInterval: 0.8)
            } else {
                print("Harf Al not available at attempt \(attempt)")
                break
            }
        }

        if !wonGame {
            takeScreenshot(name: "WIN_screen_attempt", dir: screenshotDir)
        }
        print("Win screen attempt done, won=\(wonGame)")
    }

    @MainActor
    func testAchievementsAndDaily() throws {
        let screenshotDir = "/Users/fatihozer/Desktop/ios-game/screenshots"

        app.launch()
        Thread.sleep(forTimeInterval: 4.5)

        // Navigate to Achievements via trophy button
        let trophyBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'trophy'")).firstMatch
        if trophyBtn.waitForExistence(timeout: 3) {
            trophyBtn.tap()
            Thread.sleep(forTimeInterval: 1.5)
            takeScreenshot(name: "ACHIEVEMENTS", dir: screenshotDir)
            let closeBtn = app.buttons["Kapat"]
            if closeBtn.waitForExistence(timeout: 2) { closeBtn.tap() }
            Thread.sleep(forTimeInterval: 0.8)
        }

        // Navigate to Daily mode — tapping the card opens the calendar sheet
        let dailyCard = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Günlük Kelime' AND label CONTAINS 'Her gün'")
        ).firstMatch
        if dailyCard.waitForExistence(timeout: 3), dailyCard.isHittable {
            dailyCard.tap()
            Thread.sleep(forTimeInterval: 2.0)

            // The sheet that opens IS the calendar (shows day cells 1-31 + "Bugünü Oyna!")
            // Take CALENDAR_view screenshot now
            takeScreenshot(name: "CALENDAR_view", dir: screenshotDir)

            // Now tap "Bugünü Oyna!" to enter the actual game
            let playTodayBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Bugünü Oyna'")
            ).firstMatch
            if playTodayBtn.waitForExistence(timeout: 3), playTodayBtn.isHittable {
                playTodayBtn.tap()
                Thread.sleep(forTimeInterval: 2.5)
                takeScreenshot(name: "DAILY_game", dir: screenshotDir)
            } else {
                // Already in game or different layout — take screenshot anyway
                takeScreenshot(name: "DAILY_game", dir: screenshotDir)
            }
        }

        print("=== Achievement + Daily screenshots done ===")
    }

    private func takeScreenshot(name: String, dir: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let data = screenshot.pngRepresentation
        let url = URL(fileURLWithPath: "\(dir)/\(name).png")
        try? data.write(to: url)
        print("Saved: \(url.path)")
    }
}
