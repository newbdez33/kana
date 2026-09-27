import XCTest
import StoreKitTest
@testable import kana

@available(iOS 17.0, *)
@MainActor
final class StoreTests: XCTestCase {

    private var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
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

    func testProductIsAvailable() async {
        await Store.shared.loadProduct()
        XCTAssertEqual(Store.shared.coffeeProduct?.id, Store.coffeeProductID)
        XCTAssertEqual(Store.shared.coffeeProduct?.type, .nonConsumable)
    }

    func testPurchaseRemovesAds() async throws {
        XCTAssertFalse(Store.shared.adsRemoved)

        let purchased = try await Store.shared.purchaseCoffee()

        XCTAssertTrue(purchased)
        XCTAssertTrue(Store.shared.adsRemoved)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "user.purchase.adsRemoved"))
    }

    func testRestoreFindsPurchaseMadeOutsideTheApp() async throws {
        XCTAssertFalse(Store.shared.adsRemoved)
        try await session.buyProduct(identifier: Store.coffeeProductID)

        let restored = try await Store.shared.restore()

        XCTAssertTrue(restored)
        XCTAssertTrue(Store.shared.adsRemoved)
    }

    func testRestoreWithoutPurchaseKeepsAds() async throws {
        let restored = try await Store.shared.restore()

        XCTAssertFalse(restored)
        XCTAssertFalse(Store.shared.adsRemoved)
    }
}
