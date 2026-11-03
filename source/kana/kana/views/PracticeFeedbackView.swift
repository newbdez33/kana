import UIKit

final class PracticeFeedbackView: UIView {
    private let combo = UILabel()
    private let stageName = UILabel()
    private let message = UILabel()
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let ring = CAShapeLayer()
    private var messageTimer: Timer?
    private var stage = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(ring)
        ring.fillColor = UIColor.clear.cgColor
        for label in [combo, stageName, message] {
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .kanaAccentColor
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            addSubview(label)
        }
        stageName.textAlignment = .right
        message.textAlignment = .center
        message.alpha = 0
        combo.accessibilityIdentifier = "currentStreak"
        stageName.accessibilityIdentifier = "feedbackStage"
        message.accessibilityIdentifier = "feedbackMessage"
        progress.trackTintColor = UIColor.kanaSecondaryColor.withAlphaComponent(0.12)
        addSubview(progress)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = max(0, bounds.width - 40)
        combo.frame = CGRect(x: 20, y: 10, width: width * 0.5, height: 18)
        stageName.frame = CGRect(x: 20 + width * 0.5, y: 10, width: width * 0.5, height: 18)
        progress.frame = CGRect(x: 20, y: 33, width: width, height: 2)
        message.frame = CGRect(x: 20, y: bounds.height - 26, width: width, height: 18)
        let diameter = max(0, min(bounds.width * 0.64, bounds.height - 88))
        ring.path = UIBezierPath(ovalIn: CGRect(x: (bounds.width - diameter) / 2,
                                              y: (bounds.height - diameter) / 2 + 6,
                                              width: diameter, height: diameter)).cgPath
    }

    func update(streak: Int, remaining: TimeInterval, active: Bool) {
        stage = PracticeFeedback.stage(for: streak)
        combo.text = String(format: NSLocalizedString("FeedbackCombo", comment: ""), streak)
        stageName.text = NSLocalizedString("FeedbackStage\(stage)", comment: "")
        progress.progress = Float(max(0, min(1, remaining / AppConfig.questionTimeLimit)))
        progress.progressTintColor = active && remaining < 2 && stage >= 2 ? .kanaAccentColor : .kanaSecondaryColor
        ring.strokeColor = UIColor.kanaAccentColor.withAlphaComponent(stage == 0 ? 0.035 : 0.06 + Double(stage) * 0.025).cgColor
        ring.lineWidth = CGFloat(1 + stage)
        alpha = active ? 1 : 0.65
    }

    func show(_ event: FeedbackEvent, reducedMotion: Bool) {
        stop()
        let key: String
        switch event.kind {
        case .record: key = "FeedbackRecord"
        case .milestone: key = "FeedbackStage\(event.stage)"
        case .broken: key = "FeedbackTryAgain"
        case .correction: key = "FeedbackCorrection"
        case .hit: key = "FeedbackCombo"
        }
        message.text = String(format: NSLocalizedString(key, comment: ""), event.streak)
        message.alpha = 1
        messageTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: false) { [weak self] _ in self?.message.alpha = 0 }
        if !reducedMotion && event.strength != nil {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [0.25, 1, 1]
            animation.duration = 0.25
            ring.add(animation, forKey: "impact")
            combo.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            UIView.animate(withDuration: 0.25) { self.combo.transform = .identity }
        }
        if event.kind == .record || event.kind == .milestone {
            UIAccessibility.post(notification: .announcement, argument: message.text)
        }
    }

    func beat(reducedMotion: Bool) {
        guard !reducedMotion else { return }
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0.35, 1]
        animation.duration = 0.25
        ring.add(animation, forKey: "beat")
    }

    func stop() {
        messageTimer?.invalidate()
        messageTimer = nil
        message.alpha = 0
        ring.removeAllAnimations()
        combo.layer.removeAllAnimations()
        combo.transform = .identity
    }
}
