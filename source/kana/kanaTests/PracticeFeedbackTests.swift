import XCTest
@testable import kana

final class PracticeFeedbackTests: XCTestCase {
    func testRapidHapticsAreDroppedWithoutExtendingTheGate() {
        var gate = FeedbackPulseGate()
        XCTAssertTrue(gate.accept(at: 0))
        XCTAssertFalse(gate.accept(at: 0.1))
        XCTAssertFalse(gate.accept(at: 0.179))
        XCTAssertTrue(gate.accept(at: 0.18))
    }

    func testStageBoundariesAndRhythmCap() {
        for (streak, stage, bpm) in [(0, 0, 0), (4, 0, 0), (5, 1, 0), (9, 1, 0), (10, 2, 80),
                                      (19, 2, 80), (20, 3, 100), (29, 3, 100), (30, 4, 120), (100, 4, 120)] {
            XCTAssertEqual(PracticeFeedback.stage(for: streak), stage)
            XCTAssertEqual(PracticeFeedback.bpm(for: stage), bpm)
        }
    }

    func testRecordAppearsOncePerRunAndResetsAfterFailure() {
        var run = PracticeFeedback(bestStreak: 10)
        XCTAssertEqual(run.correct(streak: 10).kind, .milestone)
        XCTAssertEqual(run.correct(streak: 11).kind, .record)
        XCTAssertEqual(run.correct(streak: 12).kind, .hit)
        XCTAssertNil(run.broken(bestStreak: 12).strength)
        XCTAssertEqual(run.correct(streak: 13).kind, .record)
    }

    func testHapticStrengthAndShortRecordSuppression() {
        var run = PracticeFeedback(bestStreak: 0)
        XCTAssertEqual(run.correct(streak: 1).kind, .hit)
        XCTAssertEqual(run.correct(streak: 4).strength, .light)
        XCTAssertEqual(run.correct(streak: 5).strength, .medium)
        XCTAssertEqual(run.correct(streak: 11).strength, .medium)
        XCTAssertEqual(run.correct(streak: 20).strength, .heavy)
        XCTAssertEqual(run.correct(streak: 40).strength, .heavy)
        XCTAssertNil(FeedbackEvent(kind: .correction, streak: 0, stage: 0).strength)
    }

    @MainActor
    func testAllNativeSoundAssetsArePackaged() {
        for name in PracticeFeedbackPlayer.soundNames {
            XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "wav"), name)
        }
    }
}
