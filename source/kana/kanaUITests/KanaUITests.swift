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
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testQuestionScreenShowsStatisticsAndAnswers() {
        let answers = app.collectionViews.firstMatch.cells
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(answers.count, 4)
        XCTAssertTrue(app.staticTexts["Total:"].exists)
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

    func testMenuOffersCoffeeAndRestore() {
        XCTAssertTrue(app.collectionViews.firstMatch.cells.firstMatch.waitForExistence(timeout: 10))
        app.swipeUp()
        let coffee = app.buttons["☕ Buy me a coffee"]
        XCTAssertTrue(coffee.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Restore"].exists)
        attach("menu")
    }
}
