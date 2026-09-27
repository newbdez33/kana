import XCTest
@testable import kana

final class StatStoreTests: XCTestCase {

    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stats-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func testEmptyStoreReportsZero() {
        let store = StatStore(fileURL: fileURL)
        XCTAssertEqual(store.totalCount, 0)
        XCTAssertEqual(store.totalAvgTime, 0)
        XCTAssertEqual(store.lastAvgTime, 0)
    }

    func testAveragesAndTimeoutsAreIgnored() {
        let store = StatStore(fileURL: fileURL)
        store.add(cost: 2, isCorrect: true)
        store.add(cost: 4, isCorrect: false)
        store.add(cost: 0, isCorrect: false) // timeout: not counted

        XCTAssertEqual(store.totalCount, 2)
        XCTAssertEqual(store.totalAvgTime, 3, accuracy: 0.0001)
        XCTAssertEqual(store.lastAvgTime, 3, accuracy: 0.0001)
    }

    func testLastAverageOnlyUsesMostRecentAnswers() {
        let store = StatStore(fileURL: fileURL)
        for _ in 0..<AppConfig.statisticsLastCount {
            store.add(cost: 1, isCorrect: true)
        }
        store.add(cost: 3, isCorrect: true)

        XCTAssertEqual(store.totalCount, AppConfig.statisticsLastCount + 1)
        // The oldest 1s answer dropped out of the recent window.
        let expected = (Double(AppConfig.statisticsLastCount - 1) * 1 + 3) / Double(AppConfig.statisticsLastCount)
        XCTAssertEqual(store.lastAvgTime, expected, accuracy: 0.0001)
    }

    func testStatisticsPersistAcrossInstances() {
        StatStore(fileURL: fileURL).add(cost: 2.5, isCorrect: true)

        let reloaded = StatStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.totalCount, 1)
        XCTAssertEqual(reloaded.totalAvgTime, 2.5, accuracy: 0.0001)
    }
}
