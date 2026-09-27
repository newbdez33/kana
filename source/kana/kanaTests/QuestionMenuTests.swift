import XCTest
@testable import kana

@MainActor
final class QuestionMenuTests: XCTestCase {
    func testMenuPausesQuestionAndResumesWhenClosed() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "Question", bundle: .main).instantiateInitialViewController() as? QuestionViewController)
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        XCTAssertTrue(controller.timer?.isValid == true)

        controller.setMenuExpanded(true)
        XCTAssertNil(controller.timer)
        XCTAssertFalse(controller.menuController!.view.isHidden)

        controller.setMenuExpanded(false)
        XCTAssertTrue(controller.timer?.isValid == true)
        XCTAssertTrue(controller.menuController!.view.isHidden)
    }
}
