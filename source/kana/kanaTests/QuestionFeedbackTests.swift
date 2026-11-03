import XCTest
@testable import kana

@MainActor
final class QuestionFeedbackTests: XCTestCase {
    func testWrongAnswerAndTimeoutKeepTheBannerTrigger() {
        let controller = BannerTrackingQuestionController()
        var time: TimeInterval = 100
        controller.now = { time }
        controller.loadViewIfNeeded()
        controller.feedbackSettings = FeedbackSettings(sound: false, rhythm: false, haptics: false)
        defer { controller.timer?.invalidate() }
        time += 1
        controller.answerAction(index: controller.findCorrectAnswerIndex())
        XCTAssertEqual(controller.bannerRequests, 0)
        let correct = controller.findCorrectAnswerIndex()
        controller.answerAction(index: (correct + 1) % 4)
        XCTAssertEqual(controller.bannerRequests, 1)
        controller.answerAction(index: correct)
        XCTAssertEqual(controller.bannerRequests, 1)
        time += AppConfig.questionTimeLimit
        controller.answerAction(index: controller.findCorrectAnswerIndex())
        XCTAssertEqual(controller.bannerRequests, 2)
    }

    func testFortyCorrectAnswersKeepTheDeadlineAndFourChoices() {
        let defaults = UserDefaults.standard
        let previousStreak = defaults.integer(forKey: AppConfig.keyCurrentCombo)
        let previousBest = defaults.integer(forKey: AppConfig.keyBestCombo)
        defaults.set(0, forKey: AppConfig.keyCurrentCombo)
        defaults.set(10, forKey: AppConfig.keyBestCombo)
        let controller = QuestionViewController()
        var time: TimeInterval = 100
        controller.now = { time }
        controller.loadViewIfNeeded()
        controller.feedbackSettings = FeedbackSettings(sound: false, rhythm: false, haptics: false, reducedMotion: true)
        defer {
            controller.timer?.invalidate()
            defaults.set(previousStreak, forKey: AppConfig.keyCurrentCombo)
            defaults.set(previousBest, forKey: AppConfig.keyBestCombo)
        }
        for streak in 1...40 {
            time += 0.2
            controller.answerAction(index: controller.findCorrectAnswerIndex())
            XCTAssertEqual(defaults.integer(forKey: AppConfig.keyCurrentCombo), streak)
            XCTAssertEqual(controller.currentAnswers.count, 4)
            XCTAssertEqual(controller.currentQuestionStartTime, time)
        }
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "feedback-stage4"
        attachment.lifetime = .keepAlways
        add(attachment)
        time += AppConfig.questionTimeLimit
        controller.answerAction(index: controller.findCorrectAnswerIndex())
        XCTAssertTrue(controller.isShowingCorrectAnswer)
        XCTAssertEqual(defaults.integer(forKey: AppConfig.keyCurrentCombo), 0)
    }

    func testBackgroundAndMenuPausesDoNotResumeEachOther() {
        let controller = QuestionViewController()
        var time: TimeInterval = 100
        controller.now = { time }
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        time += 1
        controller.setMenuExpanded(true)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        time += 10
        controller.setMenuExpanded(false)
        XCTAssertNil(controller.timer)
        let question = controller.currentQuestioKana
        controller.answerAction(index: controller.findCorrectAnswerIndex())
        XCTAssertEqual(controller.currentQuestioKana, question)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertTrue(controller.timer?.isValid == true)
        XCTAssertEqual(time - controller.currentQuestionStartTime, 1)
    }

    func testCorrectionDoesNotCountAsAnAnswerOrStreak() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "Question", bundle: .main).instantiateInitialViewController() as? QuestionViewController)
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        controller.currentQuestionStartTime -= 1
        let correct = controller.findCorrectAnswerIndex()
        controller.answerAction(index: (correct + 1) % 4)
        let count = StatStore.shared.totalCount
        controller.answerAction(index: correct)
        XCTAssertEqual(StatStore.shared.totalCount, count)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: AppConfig.keyCurrentCombo), 0)
    }

    func testLateTapCannotExtendStreakBeforeTimerCallback() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "Question", bundle: .main).instantiateInitialViewController() as? QuestionViewController)
        controller.loadViewIfNeeded()
        defer { controller.timer?.invalidate() }
        controller.currentQuestionStartTime -= AppConfig.questionTimeLimit
        controller.answerAction(index: controller.findCorrectAnswerIndex())
        XCTAssertTrue(controller.isShowingCorrectAnswer)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: AppConfig.keyCurrentCombo), 0)
    }
}

private final class BannerTrackingQuestionController: QuestionViewController {
    var bannerRequests = 0
    override func showBanner() { bannerRequests += 1 }
}
