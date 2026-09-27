import XCTest

/// Captures App Store screenshots. Runs only when TEST_RUNNER_KANA_SHOT_DIR is set:
///   TEST_RUNNER_KANA_SHOT_DIR=/path xcodebuild test -only-testing:kanaUITests/StoreScreenshotTests ...
final class StoreScreenshotTests: XCTestCase {

    private var app: XCUIApplication!
    private var directory: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let directory = ProcessInfo.processInfo.environment["KANA_SHOT_DIR"] else {
            throw XCTSkip("KANA_SHOT_DIR is not set")
        }
        self.directory = directory
        continueAfterFailure = false
        app = XCUIApplication()
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
        // Answering starts a fresh question, so the capture shows an untouched question.
        answers.element(boundBy: 0).tap()
        usleep(600_000)
        save("01-question")

        app.swipeDown()
        sleep(1)
        save("02-menu")

        let chartButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Kana chart")).firstMatch
        XCTAssertTrue(chartButton.waitForExistence(timeout: 5))
        chartButton.tap()
        XCTAssertTrue(app.otherElements["kanaChart"].waitForExistence(timeout: 5))
        sleep(1)
        save("03-chart")
    }
}
