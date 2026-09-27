import XCTest
@testable import kana

@MainActor
final class StatisticsViewTests: XCTestCase {
    func testEmptyStatisticsDoNotShowZeroSecondAverages() {
        let view = StatisticsView()
        view.update(totalCount: 0, averageTime: 0, recentTime: 0, bestCombo: 0)
        XCTAssertEqual(metric("statTotal", in: view)?.accessibilityValue, "0")
        XCTAssertEqual(metric("statAverage", in: view)?.accessibilityValue, "—")
        XCTAssertEqual(metric("statRecent", in: view)?.accessibilityValue, "—")
    }

    func testStatisticsExposeLocalizedValuesToVoiceOver() {
        let view = StatisticsView()
        view.update(totalCount: 128, averageTime: 1.825, recentTime: 1.46, bestCombo: 24)
        let time = String.localizedStringWithFormat(.statSeconds, 1.825.formatted(.number.precision(.fractionLength(2))))
        XCTAssertEqual(metric("statAverage", in: view)?.accessibilityValue, time)
        XCTAssertEqual(metric("statBest", in: view)?.accessibilityValue, "24")
        XCTAssertEqual(metric("statRecent", in: view)?.accessibilityLabel,
                       String.localizedStringWithFormat(.statRecent, AppConfig.statisticsLastCount))
    }

    private func metric(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        return view.subviews.lazy.compactMap { self.metric(identifier, in: $0) }.first
    }
}
