import XCTest
import StoreKitTest
@testable import kana

/// Exports simulator captures through a host process. The host captures the screen
/// when a marker appears in KANA_SHOT_DIR, then removes that marker.
@available(iOS 17.0, *)
@MainActor
final class PurchaseScreenshotTests: XCTestCase {
    private var session: SKTestSession!
    private var directory: URL!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        guard let path = ProcessInfo.processInfo.environment["KANA_SHOT_DIR"] else {
            throw XCTSkip("KANA_SHOT_DIR is not set")
        }
        directory = URL(fileURLWithPath: path)
        session = try SKTestSession(configurationFileNamed: "Configuration")
        session.resetToDefaultState()
        session.storefront = "JPN"
        session.locale = Locale(identifier: "ja_JP")
        session.disableDialogs = true
        session.clearTransactions()
        Store.shared.start()
        await Store.shared.refreshEntitlements()
        await Store.shared.loadProduct()
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        await Store.shared.refreshEntitlements()
        try await super.tearDown()
    }

    private var question: QuestionViewController {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
        return window!.rootViewController as! QuestionViewController
    }

    private func snapshot(_ name: String) async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
        let marker = directory.appendingPathComponent("\(name).marker")
        try Data().write(to: marker)
        for _ in 0..<80 {
            try await Task.sleep(nanoseconds: 250_000_000)
            if !FileManager.default.fileExists(atPath: marker.path) { return }
        }
        XCTFail("The host did not capture \(name)")
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<80 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTFail("The expected UI state did not appear")
    }

    func testCaptureRedesign() async throws {
        let menu = try XCTUnwrap(question.menuController)
        question.setMenuExpanded(false)
        question.timer?.invalidate()
        question.hideBanner()
        question.isShowingCorrectAnswer = false
        question.questionLabel.text = "ね"
        question.currentAnswerLabels = ["ぬ", "ne", "れ", "ナ"]
        question.collectionView.reloadData()
        question.statisticsView.update(totalCount: 0, averageTime: 0, recentTime: 0, bestCombo: 0)
        try await snapshot("01-empty")

        // Fixed display values make the layout comparable across languages.
        question.statisticsView.update(totalCount: 128, averageTime: 1.82, recentTime: 1.46, bestCombo: 24)
        try await snapshot("02-practice")
        question.setMenuExpanded(true)
        try await snapshot("03-menu")

        menu.coffeeAction(menu.coffeeButton)
        try await waitUntil { menu.presentedViewController is CoffeeViewController }
        let coffee = try XCTUnwrap(menu.presentedViewController as? CoffeeViewController)
        try await waitUntil { coffee.purchaseButton.isEnabled && coffee.purchaseButton.configuration?.title?.contains(Store.shared.coffeePrice ?? "missing") == true }
        try await snapshot("04-coffee")

        if ProcessInfo.processInfo.environment["KANA_STORE_LISTING"] == "1" {
            menu.dismiss(animated: false)
            try await waitUntil { menu.presentedViewController == nil }
            menu.chartAction(menu.chartButton)
            try await waitUntil { menu.presentedViewController != nil }
            try await snapshot("05-chart")
            menu.dismiss(animated: false)
            return
        }

        coffee.purchaseAction()
        try await waitUntil { Store.shared.adsRemoved && coffee.purchaseButton.configuration?.title == .continuePractice }
        XCTAssertTrue(coffee.restoreButton.isHidden)
        try await snapshot("05-thanks")
        question.incorrect()
        XCTAssertEqual(question.adViewHeight.constant, 0)

        session.clearTransactions()
        await Store.shared.refreshEntitlements()
        session.askToBuyEnabled = true
        coffee.purchaseAction()
        try await waitUntil { coffee.statusLabel.text == .coffeePendingMessage }
        XCTAssertFalse(Store.shared.adsRemoved)
        try await snapshot("06-pending")
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: transaction.identifier)
        try await waitUntil { Store.shared.adsRemoved }
        XCTAssertEqual(coffee.purchaseButton.configuration?.title, .continuePractice)
        session.askToBuyEnabled = false

        session.clearTransactions()
        await Store.shared.refreshEntitlements()
        coffee.restoreAction()
        try await waitUntil { coffee.presentedViewController is UIAlertController }
        try await snapshot("07-restore-none")
        coffee.dismiss(animated: false)
        menu.dismiss(animated: false)
    }
}
