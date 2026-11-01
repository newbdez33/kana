import XCTest
import UIKit
@testable import kana

@MainActor
final class PracticeResizeTests: XCTestCase {
    func testResizeKeepsTheRunningTimer() throws {
        let controller = QuestionViewController()
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        let timer = try XCTUnwrap(controller.timer)
        let question = controller.currentQuestioKana
        for size in [CGSize(width: 382, height: 678), CGSize(width: 867, height: 669)] {
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.layoutIfNeeded()
            XCTAssertTrue(controller.timer === timer)
            XCTAssertTrue(timer.isValid)
            XCTAssertEqual(controller.currentQuestioKana, question)
        }
    }

    func testLayoutDrivenScrollDoesNotCloseTheMenu() {
        let controller = QuestionViewController()
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        controller.setMenuExpanded(true)
        controller.scrollView.contentOffset.y = 100
        controller.scrollViewDidScroll(controller.scrollView)
        XCTAssertNil(controller.timer)
        XCTAssertFalse(controller.menuController!.view.isHidden)
    }

    func testResizeKeepsQuestionAnswersAndPausedTimer() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "Question", bundle: .main)
            .instantiateInitialViewController() as? QuestionViewController)
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        controller.setMenuExpanded(true)
        let question = controller.currentQuestioKana
        let answers = controller.currentAnswers
        let labels = controller.currentAnswerLabels
        let start = controller.currentQuestionStartTime

        for size in [CGSize(width: 466, height: 678), CGSize(width: 951, height: 669),
                     CGSize(width: 669, height: 951), CGSize(width: 400, height: 320)] {
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            XCTAssertEqual(controller.currentQuestioKana, question)
            XCTAssertEqual(controller.currentAnswers, answers)
            XCTAssertEqual(controller.currentAnswerLabels, labels)
            XCTAssertEqual(controller.currentQuestionStartTime, start)
            XCTAssertNil(controller.timer)
            XCTAssertFalse(controller.menuController!.view.isHidden)
            XCTAssertEqual(controller.collectionView.numberOfItems(inSection: 0), 4)
        }

        controller.setMenuExpanded(false)
        XCTAssertTrue(controller.timer?.isValid == true)
    }

    func testPracticeRespectsEachSafeAreaEdge() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let controller = UIViewController()
        let practice = PracticeView()
        controller.view = practice
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 28, bottom: 20, right: 84)
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(practice.safeAreaInsets.left, 28)
        XCTAssertGreaterThanOrEqual(practice.safeAreaInsets.right, 84)
        let prompt = practice.scrollView.convert(practice.scrollView.bounds, to: practice)
        let answers = practice.collectionView.convert(practice.collectionView.bounds, to: practice)
        XCTAssertEqual(prompt.union(answers), controller.view.safeAreaLayoutGuide.layoutFrame)
    }

    func testChartUsesItsContainerWidth() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "Kana", bundle: .main)
            .instantiateInitialViewController() as? KanaViewController)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 382, height: 600)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        let header = controller.collectionView(collection, layout: collection.collectionViewLayout,
                                               referenceSizeForHeaderInSection: 0)
        let insets = collection.adjustedContentInset
        XCTAssertEqual(header.width, collection.bounds.width - insets.left - insets.right)
        let item = controller.collectionView(collection, layout: collection.collectionViewLayout,
                                             sizeForItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(item.width * 5 + 60, header.width, accuracy: 0.01)
    }
}
