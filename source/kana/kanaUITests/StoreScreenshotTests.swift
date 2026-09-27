import XCTest

/// Captures App Store screenshots. Runs only when TEST_RUNNER_KANA_SHOT_DIR is set:
///   TEST_RUNNER_KANA_SHOT_DIR=/path TEST_RUNNER_KANA_SHOT_LANG=ja \
///     xcodebuild test -only-testing:kanaUITests/StoreScreenshotTests ...
/// KANA_SHOT_LANG selects the app language (en, ja, zh-Hans, zh-Hant, ko); default en.
final class StoreScreenshotTests: XCTestCase {

    private var app: XCUIApplication!
    private var directory: String!
    private var language = "en"

    override func setUpWithError() throws {
        try super.setUpWithError()
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment["KANA_SHOT_DIR"] else {
            throw XCTSkip("KANA_SHOT_DIR is not set")
        }
        self.directory = directory
        language = environment["KANA_SHOT_LANG"] ?? "en"
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let cancel = springboard.buttons["Cancel"]
        if cancel.waitForExistence(timeout: 3) {
            cancel.tap()
        }
    }

    private func save(_ name: String) {
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try? app.screenshot().pngRepresentation.write(to: url)
    }

    func testCaptureStoreScreenshots() {
        let answers = app.collectionViews.firstMatch.cells
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        // Tap answers until the question changes: a correct answer starts a fresh,
        // untouched question with a full timer, which is what the capture should show.
        let questionLabel = app.staticTexts["questionLabel"]
        let firstQuestion = questionLabel.label
        for index in 0..<4 {
            answers.element(boundBy: index).tap()
            usleep(300_000)
            if questionLabel.label != firstQuestion { break }
        }
        save("01-question")

        app.buttons["menuToggle"].tap()
        sleep(1)
        save("02-menu")

        let chartButton = app.buttons["chartMenu"]
        XCTAssertTrue(chartButton.waitForExistence(timeout: 5))
        chartButton.tap()
        XCTAssertTrue(app.otherElements["kanaChart"].waitForExistence(timeout: 5))
        sleep(1)
        save("03-chart")
    }
}
