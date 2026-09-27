import XCTest
import StoreKitTest
@testable import kana

/// Drives the real purchase UI inside the app (hosted test) with a StoreKit test
/// session so that a host-side script can take simulator screenshots.
/// Protocol: the test writes `<name>.marker` into KANA_SHOT_DIR and waits until the
/// host deletes it (after `xcrun simctl io screenshot`). Skipped unless
/// TEST_RUNNER_KANA_SHOT_DIR is set.
@available(iOS 17.0, *)
@MainActor
final class PurchaseScreenshotTests: XCTestCase {

    private var session: SKTestSession!
    private var directory: URL!

    override func setUp() async throws {
        try await super.setUp()
        guard let path = ProcessInfo.processInfo.environment["KANA_SHOT_DIR"] else {
            throw XCTSkip("KANA_SHOT_DIR is not set")
        }
        directory = URL(fileURLWithPath: path)
        session = try SKTestSession(configurationFileNamed: "Configuration")
        session.disableDialogs = true
        session.clearTransactions()
        UserDefaults.standard.removeObject(forKey: "user.purchase.adsRemoved")
        await Store.shared.refreshEntitlements()
    }

    override func tearDown() async throws {
        session.clearTransactions()
        try await super.tearDown()
    }

    private var question: QuestionViewController {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
        return window!.rootViewController as! QuestionViewController
    }

    private func revealMenu() {
        let vc = question
        vc.constraintQuestionTop.constant = 80
        vc.menuController?.setExpanded(true)
        vc.view.layoutIfNeeded()
    }

    private func snapshot(_ name: String) async {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let marker = directory.appendingPathComponent("\(name).marker")
        FileManager.default.createFile(atPath: marker.path, contents: nil)
        for _ in 0..<60 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !FileManager.default.fileExists(atPath: marker.path) { return }
        }
    }

    private func waitForAlert(on controller: UIViewController) async -> UIAlertController? {
        for _ in 0..<40 {
            if let alert = controller.presentedViewController as? UIAlertController { return alert }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        return nil
    }

    func testAPurchaseAndRestoreFlow() async throws {
        let menu = try XCTUnwrap(question.menuController)
        revealMenu()
        await snapshot("01-menu")

        // Purchase through the real button; the test session confirms the sheet silently.
        menu.coffeeAction(menu.coffeeButton)
        let thanks = await waitForAlert(on: menu)
        XCTAssertNotNil(thanks)
        XCTAssertTrue(Store.shared.adsRemoved)
        await snapshot("03-thanks")
        thanks?.dismiss(animated: false)
        try? await Task.sleep(nanoseconds: 400_000_000)
        await snapshot("04-menu-after-purchase")

        // A wrong answer no longer shows the banner slot.
        question.incorrect()
        await snapshot("05-wrong-answer-no-ad")

        // Fresh install without a purchase: restore finds nothing.
        session.clearTransactions()
        await Store.shared.refreshEntitlements()
        XCTAssertFalse(Store.shared.adsRemoved)
        question.nextQuestion()
        revealMenu()
        menu.restoreAction(menu.restoreButton)
        let none = await waitForAlert(on: menu)
        XCTAssertNotNil(none)
        await snapshot("06-restore-none")
        none?.dismiss(animated: false)
    }

    func testBPurchaseSheet() async throws {
        let menu = try XCTUnwrap(question.menuController)
        revealMenu()
        session.disableDialogs = false
        // The system confirmation sheet stays up until a person taps it, so this
        // purchase is left pending and only photographed.
        menu.coffeeAction(menu.coffeeButton)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        await snapshot("02-purchase-sheet")
    }
}
