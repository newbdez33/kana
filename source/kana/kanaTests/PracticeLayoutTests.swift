import XCTest
import CoreGraphics
@testable import kana

final class PracticeLayoutTests: XCTestCase {
    func testSideStatusBarDoesNotReserveTheWholeAnswerEdge() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 678)
        let safeArea = CGRect(x: 0, y: 0, width: 382, height: 644)
        let status = CGRect(x: 382, y: 0, width: 84, height: 170)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea,
                                    prefersColumns: false, occlusions: [status])
        XCTAssertEqual(layout.question.width, bounds.width)
        XCTAssertEqual(layout.answers.width, bounds.width)
        XCTAssertEqual(layout.answers.maxY, safeArea.maxY)
        XCTAssertFalse(layout.answers.intersects(status))
    }

    func testLeadingStatusBarAlsoReleasesTheSpaceBelowIt() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 678)
        let safeArea = CGRect(x: 84, y: 0, width: 382, height: 644)
        let status = CGRect(x: 0, y: 0, width: 84, height: 170)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea,
                                    prefersColumns: false, occlusions: [status], rightToLeft: true)
        XCTAssertEqual(layout.answers.minX, bounds.minX)
        XCTAssertEqual(layout.question.width, bounds.width)
        XCTAssertFalse(layout.answers.intersects(status))
    }

    func testUnexplainedSafeAreaInsetsRemainReserved() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 678)
        let safeArea = CGRect(x: 28, y: 12, width: 354, height: 612)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea, prefersColumns: false)
        XCTAssertEqual(layout.question.union(layout.answers), safeArea)
    }

    func testAdditionalSideInsetsAreNotRemovedByTheStatusBar() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 678)
        let safeArea = CGRect(x: 0, y: 12, width: 298, height: 612)
        let status = CGRect(x: 382, y: 0, width: 84, height: 170)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea,
                                    prefersColumns: false, occlusions: [status])
        XCTAssertEqual(layout.question.union(layout.answers), safeArea)
    }

    func testAnswerPaneAvoidsAStatusBarThatReachesItsRows() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 260)
        let safeArea = CGRect(x: 0, y: 0, width: 382, height: 226)
        let status = CGRect(x: 382, y: 0, width: 84, height: 170)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea,
                                    prefersColumns: false, occlusions: [status])
        XCTAssertEqual(layout.answers.maxX, status.minX)
        XCTAssertFalse(layout.answers.intersects(status))
    }

    func testReclaimingTheSideDoesNotMoveTheFold() {
        let bounds = CGRect(x: 0, y: 0, width: 951, height: 669)
        let safeArea = CGRect(x: 0, y: 0, width: 867, height: 635)
        let fold = CGRect(x: 459, y: 0, width: 33, height: 669)
        let status = CGRect(x: 867, y: 0, width: 84, height: 170)
        let layout = PracticeLayout(bounds: bounds, safeArea: safeArea, prefersColumns: true,
                                    divisions: [fold], occlusions: [status])
        XCTAssertEqual(layout.answers.maxX, fold.minX)
        XCTAssertEqual(layout.question.minX, fold.maxX)
        XCTAssertEqual(layout.question.maxX, bounds.maxX)
        XCTAssertFalse(layout.answers.intersects(status))
    }

    func testBannerAvoidsOcclusionsOnlyAtItsOwnHeight() {
        let status = CGRect(x: 382, y: 0, width: 84, height: 170)
        let highBanner = CGRect(x: 0, y: 140, width: 466, height: 60)
        let lowBanner = highBanner.offsetBy(dx: 0, dy: 100)
        XCTAssertEqual(PracticeLayout.horizontalFrame(in: highBanner, avoiding: [status]).maxX, status.minX)
        XCTAssertEqual(PracticeLayout.horizontalFrame(in: lowBanner, avoiding: [status]), lowBanner)
    }

    func testOverlappingOcclusionsKeepTheSameFreeIntervalInEitherOrder() {
        let bounds = CGRect(x: 0, y: 0, width: 466, height: 200)
        let status = CGRect(x: 382, y: 0, width: 84, height: 170)
        let camera = CGRect(x: 400, y: 29, width: 37, height: 37)
        let available = PracticeLayout.horizontalFrame(in: bounds, avoiding: [status, camera])
        XCTAssertEqual(available.maxX, status.minX)
        XCTAssertEqual(available, PracticeLayout.horizontalFrame(in: bounds, avoiding: [camera, status]))
    }

    func testCompactPortraitKeepsQuestionAboveAllAnswers() {
        let bounds = CGRect(x: 0, y: 0, width: 382, height: 678)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: false)
        XCTAssertEqual(layout.question.minY, bounds.minY)
        XCTAssertEqual(layout.answers.maxY, bounds.maxY)
        XCTAssertEqual(layout.question.maxY, layout.answers.minY)
        XCTAssertEqual(layout.answers.width, bounds.width)
    }

    func testWideWindowPlacesAnswersBeforeQuestion() {
        let bounds = CGRect(x: 0, y: 0, width: 867, height: 669)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: true)
        XCTAssertEqual(layout.answers.minX, bounds.minX)
        XCTAssertEqual(layout.answers.maxX, layout.question.minX)
        XCTAssertEqual(layout.question.width, layout.answers.width)
        XCTAssertEqual(layout.question.height, bounds.height)
    }

    func testBookFoldUsesPhysicalPositionRatherThanWindowCenter() {
        let bounds = CGRect(x: 0, y: 0, width: 867, height: 669)
        let fold = CGRect(x: 459, y: -20, width: 33, height: 720)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: true, divisions: [fold])
        XCTAssertEqual(layout.answers.maxX, fold.minX)
        XCTAssertEqual(layout.question.minX, fold.maxX)
        XCTAssertEqual(layout.question.maxX, bounds.maxX)
        XCTAssertFalse(layout.question.intersects(fold))
        XCTAssertFalse(layout.answers.intersects(fold))
    }

    func testInactiveFoldWithZeroWidthKeepsPanesOnTheirOwnSides() {
        let fold = CGRect(x: 475.5, y: 0, width: 0, height: 669)
        let layout = PracticeLayout(bounds: CGRect(x: 0, y: 0, width: 867, height: 669),
                                    prefersColumns: true, divisions: [fold])
        XCTAssertEqual(layout.answers.maxX, 475.5)
        XCTAssertEqual(layout.question.minX, 475.5)
    }

    func testTabletopKeepsAnswersBelowTheFold() {
        let bounds = CGRect(x: 0, y: 0, width: 669, height: 772)
        let fold = CGRect(x: -20, y: 375, width: 720, height: 34)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: false, divisions: [fold])
        XCTAssertEqual(layout.question.maxY, fold.minY)
        XCTAssertEqual(layout.answers.minY, fold.maxY)
        XCTAssertFalse(layout.answers.intersects(fold))
    }

    func testSplitViewUsesRemainingSpaceWhenFoldTouchesAnEdge() {
        let bounds = CGRect(x: 0, y: 0, width: 382, height: 669)
        let fold = CGRect(x: 370, y: 0, width: 35, height: 669)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: false, divisions: [fold])
        XCTAssertEqual(layout.question.width, 370)
        XCTAssertEqual(layout.answers.width, 370)
        XCTAssertEqual(layout.question.maxY, layout.answers.minY)
    }

    func testRightToLeftChangesReadingOrderWithoutMovingFold() {
        let fold = CGRect(x: 459, y: 0, width: 33, height: 669)
        let layout = PracticeLayout(bounds: CGRect(x: 0, y: 0, width: 867, height: 669),
                                    prefersColumns: true, divisions: [fold], rightToLeft: true)
        XCTAssertEqual(layout.question.maxX, fold.minX)
        XCTAssertEqual(layout.answers.minX, fold.maxX)
    }

    func testNonzeroOriginAndOutOfBoundsRegion() {
        let bounds = CGRect(x: 20, y: 30, width: 382, height: 600)
        let outside = CGRect(x: 900, y: 0, width: 20, height: 900)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: false, divisions: [outside])
        XCTAssertEqual(layout.question.origin, bounds.origin)
        XCTAssertEqual(layout.answers.maxY, bounds.maxY)
        XCTAssertTrue(bounds.contains(layout.question))
        XCTAssertTrue(bounds.contains(layout.answers))
    }

    func testShortLandscapeKeepsFourLargeAnswerTargets() {
        let layout = PracticeLayout(bounds: CGRect(x: 0, y: 0, width: 640, height: 280),
                                    prefersColumns: true)
        XCTAssertEqual(layout.answers.width / 2, 160)
        XCTAssertEqual(layout.answers.height / 2, 140)
        XCTAssertEqual(layout.question.height, 280)
    }

    func testFoldAtLeadingEdgeKeepsBothPanesOutsideTheRegion() {
        let bounds = CGRect(x: 0, y: 0, width: 391.5, height: 669)
        let fold = CGRect(x: -16.5, y: 0, width: 33, height: 669)
        let layout = PracticeLayout(bounds: bounds, prefersColumns: false, divisions: [fold])
        XCTAssertEqual(layout.question.minX, fold.maxX)
        XCTAssertEqual(layout.answers.minX, fold.maxX)
        XCTAssertEqual(layout.answers.maxX, bounds.maxX)
        XCTAssertFalse(layout.question.intersects(fold))
        XCTAssertFalse(layout.answers.intersects(fold))
    }
}
