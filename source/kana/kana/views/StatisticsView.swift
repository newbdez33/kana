import UIKit

final class StatisticsView: UIView {

    let menuButton = UIButton(type: .system)
    private let total = MetricView(title: .statAnswers, identifier: "statTotal")
    private let average = MetricView(title: .statAverage, identifier: "statAverage")
    private let recent = MetricView(
        title: String.localizedStringWithFormat(.statRecent, AppConfig.statisticsLastCount),
        identifier: "statRecent"
    )
    private let best = MetricView(title: .statBest, identifier: "statBest", accented: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        let title = UILabel()
        title.text = String.practice.uppercased()
        title.font = .systemFont(ofSize: 11, weight: .semibold)
        title.textColor = .kanaSecondaryColor
        title.accessibilityTraits = .header

        menuButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        menuButton.tintColor = .kanaBlackColor()
        menuButton.accessibilityLabel = .menu
        menuButton.accessibilityIdentifier = "menuToggle"

        let header = UIStackView(arrangedSubviews: [title, UIView(), menuButton])
        header.alignment = .center
        let metrics = UIStackView(arrangedSubviews: [total, average, recent, best])
        metrics.distribution = .fillEqually
        metrics.alignment = .top
        metrics.spacing = 8

        let divider = UIView()
        divider.backgroundColor = UIColor.kanaBlackColor().withAlphaComponent(0.09)
        let content = UIStackView(arrangedSubviews: [header, metrics, divider])
        content.axis = .vertical
        content.spacing = 8
        content.setCustomSpacing(20, after: metrics)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        let preferredWidth = content.widthAnchor.constraint(equalTo: widthAnchor, constant: -40)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            content.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            preferredWidth,
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44),
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    func update(totalCount: Int, averageTime: Double, recentTime: Double, bestCombo: Int) {
        total.setValue(totalCount.formatted())
        updateTime(average, value: averageTime, hasAnswers: totalCount > 0)
        updateTime(recent, value: recentTime, hasAnswers: totalCount > 0)
        best.setValue(bestCombo.formatted())
    }

    private func updateTime(_ metric: MetricView, value: Double, hasAnswers: Bool) {
        guard hasAnswers else {
            metric.setValue("—")
            return
        }
        let number = value.formatted(.number.precision(.fractionLength(2)))
        metric.setValue(String.localizedStringWithFormat(.statSeconds, number), number: number)
    }
}

private final class MetricView: UIStackView {

    private let valueLabel = UILabel()

    init(title: String, identifier: String, accented: Bool = false) {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .fill
        spacing = 5
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityIdentifier = identifier

        valueLabel.font = .monospacedDigitSystemFont(ofSize: 25, weight: .medium)
        valueLabel.textColor = accented ? .kanaAccentColor : .kanaBlackColor()
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let caption = UILabel()
        caption.text = title
        caption.font = .systemFont(ofSize: 11, weight: .medium)
        caption.textColor = .kanaSecondaryColor
        caption.numberOfLines = 2
        addArrangedSubview(valueLabel)
        addArrangedSubview(caption)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String, number: String? = nil) {
        if let number {
            let text = NSMutableAttributedString(string: value, attributes: [
                .font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.kanaSecondaryColor
            ])
            text.addAttributes([.font: valueLabel.font!, .foregroundColor: UIColor.kanaBlackColor()],
                               range: (value as NSString).range(of: number))
            valueLabel.attributedText = text
        } else {
            valueLabel.attributedText = nil
            valueLabel.text = value
        }
        accessibilityValue = value
    }
}
