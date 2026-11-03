import Foundation

enum FeedbackKind: String {
    case hit, milestone, record, broken, correction
}

enum FeedbackStrength { case light, medium, heavy }

struct FeedbackEvent: Equatable {
    let kind: FeedbackKind
    let streak: Int
    let stage: Int

    var strength: FeedbackStrength? {
        switch kind {
        case .broken, .correction: return nil
        case .record: return .heavy
        case .milestone: return stage >= 3 ? .heavy : .medium
        case .hit: return stage >= 2 ? .medium : .light
        }
    }

    var soundName: String {
        switch kind {
        case .hit, .milestone, .record: return "feedback_\(kind.rawValue)_\(stage)"
        case .broken, .correction: return "feedback_\(kind.rawValue)"
        }
    }
}

struct PracticeFeedback {
    private var recordTarget: Int
    private var recordShown = false

    init(bestStreak: Int) { recordTarget = bestStreak }

    static func stage(for streak: Int) -> Int {
        [5, 10, 20, 30].filter { streak >= $0 }.count
    }

    static func bpm(for stage: Int) -> Int { [0, 0, 80, 100, 120][max(0, min(4, stage))] }

    mutating func correct(streak: Int) -> FeedbackEvent {
        let record = recordTarget >= 5 && streak > recordTarget && !recordShown
        if record { recordShown = true }
        let milestone = streak >= 5 && (streak == 5 || streak % 10 == 0)
        return FeedbackEvent(kind: record ? .record : milestone ? .milestone : .hit,
                             streak: streak, stage: Self.stage(for: streak))
    }

    mutating func broken(bestStreak: Int) -> FeedbackEvent {
        recordTarget = bestStreak
        recordShown = false
        return FeedbackEvent(kind: .broken, streak: 0, stage: 0)
    }
}

struct FeedbackSettings {
    var sound = true
    var rhythm = true
    var haptics = true
    var reducedMotion = false
}

struct FeedbackPulseGate {
    private var lastPulse: TimeInterval = -.infinity

    mutating func accept(at time: TimeInterval) -> Bool {
        guard time - lastPulse >= 0.18 else { return false }
        lastPulse = time
        return true
    }
}
