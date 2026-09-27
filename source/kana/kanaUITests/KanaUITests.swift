import XCTest

final class KanaUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        dismissSystemSignInPromptIfPresent()
    }

    /// The simulator asks for an Apple Account when StoreKit is used without a
    /// StoreKit configuration; a device with an account never shows this.
    private func dismissSystemSignInPromptIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let cancel = springboard.buttons["Cancel"]
        if cancel.waitForExistence(timeout: 3) {
            cancel.tap()
        }
    }

    private func attach(_ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        // Optional plain PNG export for scripted runs: TEST_RUNNER_KANA_SHOT_DIR=/path xcodebuild test ...
        if let directory = ProcessInfo.processInfo.environment["KANA_SHOT_DIR"] {
            let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: url)
        }
    }

    func testQuestionScreenShowsStatisticsAndAnswers() {
        let answers = app.collectionViews.firstMatch.cells
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(answers.count, 4)
        XCTAssertTrue(app.otherElements["statTotal"].exists)
        XCTAssertTrue(app.otherElements["statAverage"].exists)
        XCTAssertTrue(app.otherElements["statRecent"].exists)
        XCTAssertTrue(app.otherElements["statBest"].exists)
        attach("question")
    }

    func testTimeoutRevealsAnswerAndBanner() {
        let answers = app.collectionViews.firstMatch.cells
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        // No answer within the 5 second limit counts as incorrect and shows the banner slot.
        sleep(8)
        attach("timeout-with-banner")
        // Answering moves on to the next question and hides the banner again.
        answers.element(boundBy: 0).tap()
        sleep(1)
        attach("next-question")
    }

    func testMenuOpensKanaChart() {
        XCTAssertTrue(app.collectionViews.firstMatch.cells.firstMatch.waitForExistence(timeout: 10))
        app.swipeDown()
        sleep(1)
        let chartButton = app.buttons["chartMenu"]
        XCTAssertTrue(chartButton.waitForExistence(timeout: 5))
        chartButton.tap()
        let chart = app.otherElements["kanaChart"]
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(chart.collectionViews.firstMatch.cells.count, 20)
        attach("chart")
    }

    func testMenuOpensSupportAndReturnsToPractice() {
        XCTAssertTrue(app.collectionViews.firstMatch.cells.firstMatch.waitForExistence(timeout: 10))
        app.buttons["menuToggle"].tap()
        let coffee = app.buttons["coffeeMenu"]
        XCTAssertTrue(coffee.waitForExistence(timeout: 5))
        XCTAssertTrue(coffee.isHittable)
        attach("menu")
        coffee.tap()
        XCTAssertTrue(app.otherElements["coffeeSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["coffeePurchase"].exists)
        XCTAssertTrue(app.buttons["coffeeRestore"].isHittable)
        attach("support")
        app.buttons["coffeeClose"].tap()
        XCTAssertTrue(app.buttons["menuToggle"].isHittable)
        app.buttons["menuToggle"].tap()
        XCTAssertFalse(app.buttons["coffeeMenu"].isHittable)
    }
}
