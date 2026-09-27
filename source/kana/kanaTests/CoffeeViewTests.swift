import XCTest
@testable import kana

@MainActor
final class CoffeeViewTests: XCTestCase {

    private var store: TestCoffeeStore!
    private var controller: CoffeeViewController!

    override func setUp() async throws {
        store = TestCoffeeStore()
        controller = CoffeeViewController(store: store)
        controller.loadViewIfNeeded()
        await settle()
    }

    private func settle() async {
        for _ in 0..<10 { await Task.yield() }
    }

    func testPriceIsVisibleBeforePurchase() {
        XCTAssertTrue(controller.purchaseButton.isEnabled)
        XCTAssertTrue(controller.purchaseButton.configuration?.title?.contains("¥300") == true)
        XCTAssertEqual(store.purchaseCount, 0)
    }

    func testPurchaseButtonKeepsItsMarginsAtDifferentWidths() {
        for width: CGFloat in [320, 393, 768] {
            controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            let frame = controller.purchaseButton.convert(controller.purchaseButton.bounds, to: controller.view)
            XCTAssertGreaterThanOrEqual(frame.minX, 28)
            XCTAssertLessThanOrEqual(frame.maxX, width - 28)
        }
    }

    func testUnavailablePriceOffersRetry() async {
        store.coffeePrice = nil
        controller = CoffeeViewController(store: store)
        controller.loadViewIfNeeded()
        await settle()
        XCTAssertEqual(controller.purchaseButton.configuration?.title, .retry)
        XCTAssertFalse(controller.statusLabel.isHidden)
        XCTAssertTrue(controller.restoreButton.isEnabled)

        store.nextPrice = "$2.99"
        controller.purchaseAction()
        await settle()
        XCTAssertTrue(controller.purchaseButton.configuration?.title?.contains("$2.99") == true)
        XCTAssertTrue(controller.statusLabel.isHidden)
        XCTAssertEqual(store.purchaseCount, 0)
    }

    func testPurchaseShowsThanksAndRemovesRestore() async {
        controller.purchaseAction()
        XCTAssertFalse(controller.purchaseButton.isEnabled)
        XCTAssertFalse(controller.restoreButton.isEnabled)
        await settle()

        XCTAssertEqual(controller.purchaseButton.configuration?.title, .continuePractice)
        XCTAssertTrue(controller.restoreButton.isHidden)
        XCTAssertEqual(store.purchaseCount, 1)
    }

    func testCancelledPurchaseCanBeRetried() async {
        store.outcome = .cancelled
        controller.purchaseAction()
        await settle()

        XCTAssertTrue(controller.purchaseButton.isEnabled)
        XCTAssertFalse(controller.restoreButton.isHidden)
        XCTAssertTrue(controller.statusLabel.isHidden)
        XCTAssertFalse(store.adsRemoved)
    }

    func testPendingPurchaseShowsApprovalMessage() async {
        store.outcome = .pending
        controller.purchaseAction()
        await settle()

        XCTAssertFalse(controller.purchaseButton.isEnabled)
        XCTAssertEqual(controller.statusLabel.text, .coffeePendingMessage)
        XCTAssertFalse(controller.statusLabel.isHidden)
        XCTAssertFalse(store.adsRemoved)

        store.adsRemoved = true
        NotificationCenter.default.post(name: .adsRemovedDidChange, object: nil)
        XCTAssertTrue(controller.purchaseButton.isEnabled)
        XCTAssertEqual(controller.purchaseButton.configuration?.title, .continuePractice)
        XCTAssertTrue(controller.statusLabel.isHidden)
    }

    func testOwnedPurchaseDoesNotLoadOrOfferAnotherPurchase() async {
        store.adsRemoved = true
        let initialLoads = store.loadCount
        controller = CoffeeViewController(store: store)
        controller.loadViewIfNeeded()
        await settle()

        XCTAssertEqual(store.loadCount, initialLoads)
        XCTAssertEqual(controller.purchaseButton.configuration?.title, .continuePractice)
        XCTAssertTrue(controller.restoreButton.isHidden)
    }

    func testRestoredPurchaseShowsThanks() async {
        controller.restoreAction()
        await settle()
        XCTAssertEqual(controller.purchaseButton.configuration?.title, .continuePractice)
        XCTAssertTrue(controller.restoreButton.isHidden)
    }
}

@MainActor
private final class TestCoffeeStore: CoffeeStore {
    var adsRemoved = false
    var coffeePrice: String? = "¥300"
    var nextPrice: String?
    var outcome = CoffeePurchaseOutcome.purchased
    var purchaseCount = 0
    var loadCount = 0

    func loadProduct() async {
        loadCount += 1
        if let nextPrice { coffeePrice = nextPrice }
    }

    func purchaseCoffee() async throws -> CoffeePurchaseOutcome {
        purchaseCount += 1
        if outcome == .purchased { adsRemoved = true }
        return outcome
    }

    func restore() async throws -> Bool {
        adsRemoved = true
        return true
    }
}
