import UIKit
import GoogleMobileAds

final class PracticeView: UIView {
    let scrollView = UIScrollView()
    let statisticsView = StatisticsView()
    let questionLabel = QuestionGlyphLabel()
    let feedbackView = PracticeFeedbackView()
    let menuContainer = UIView()
    let bannerView = BannerView()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: AnswerGridLayout())
    private let content = PracticeContentView()
    private let prompt = UIView()
    private(set) var bannerHeight: NSLayoutConstraint!
    private var menuHeight: NSLayoutConstraint!
    private var promptMinimumHeight: NSLayoutConstraint!
    private var glyphMaximumHeight: NSLayoutConstraint!

    var isMenuExpanded = false {
        didSet {
            menuHeight.constant = isMenuExpanded ? 80 : 0
            promptMinimumHeight.constant = isMenuExpanded ? 100 : 160
            glyphMaximumHeight.constant = isMenuExpanded ? -16 : -80
            feedbackView.isHidden = isMenuExpanded
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .kanaKeyGrayColor()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(content)
        content.question.addSubview(scrollView)
        scrollView.addSubview(prompt)
        prompt.addSubview(menuContainer)
        prompt.addSubview(statisticsView)
        prompt.addSubview(feedbackView)
        prompt.addSubview(questionLabel)
        prompt.addSubview(bannerView)
        content.answers.addSubview(collectionView)

        questionLabel.font = UIFont(name: "Hosofuwafont", size: 155)
        questionLabel.textColor = .kanaBlackColor()
        questionLabel.textAlignment = .center
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.1
        questionLabel.accessibilityIdentifier = "questionLabel"
        collectionView.backgroundColor = .white
        collectionView.isScrollEnabled = false
        collectionView.accessibilityIdentifier = "answerGrid"
        menuContainer.clipsToBounds = true
        bannerView.clipsToBounds = true

        for child in [scrollView, content, prompt, menuContainer, statisticsView, questionLabel, bannerView, collectionView, feedbackView] {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        let labelArea = UILayoutGuide()
        prompt.addLayoutGuide(labelArea)
        menuHeight = menuContainer.heightAnchor.constraint(equalToConstant: 0)
        bannerHeight = bannerView.heightAnchor.constraint(equalToConstant: 0)
        promptMinimumHeight = labelArea.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        glyphMaximumHeight = questionLabel.heightAnchor.constraint(lessThanOrEqualTo: labelArea.heightAnchor, constant: -80)
        let viewportHeight = prompt.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        viewportHeight.priority = .defaultHigh
        let labelWidth = questionLabel.widthAnchor.constraint(equalTo: prompt.widthAnchor, multiplier: 0.35)
        labelWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: content.question.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: content.question.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: content.question.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: content.question.trailingAnchor),
            prompt.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            prompt.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            prompt.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            prompt.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            viewportHeight,
            menuContainer.topAnchor.constraint(equalTo: prompt.topAnchor),
            menuContainer.leadingAnchor.constraint(equalTo: prompt.leadingAnchor),
            menuContainer.trailingAnchor.constraint(equalTo: prompt.trailingAnchor),
            menuHeight,
            statisticsView.topAnchor.constraint(equalTo: menuContainer.bottomAnchor, constant: 12),
            statisticsView.leadingAnchor.constraint(equalTo: prompt.leadingAnchor),
            statisticsView.trailingAnchor.constraint(equalTo: prompt.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: prompt.bottomAnchor),
            bannerView.leadingAnchor.constraint(equalTo: prompt.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: prompt.trailingAnchor),
            bannerHeight,
            labelArea.topAnchor.constraint(equalTo: statisticsView.bottomAnchor),
            labelArea.bottomAnchor.constraint(equalTo: bannerView.topAnchor),
            promptMinimumHeight,
            feedbackView.topAnchor.constraint(equalTo: labelArea.topAnchor),
            feedbackView.bottomAnchor.constraint(equalTo: labelArea.bottomAnchor),
            feedbackView.leadingAnchor.constraint(equalTo: prompt.leadingAnchor),
            feedbackView.trailingAnchor.constraint(equalTo: prompt.trailingAnchor),
            questionLabel.centerXAnchor.constraint(equalTo: prompt.centerXAnchor),
            questionLabel.centerYAnchor.constraint(equalTo: labelArea.centerYAnchor),
            questionLabel.widthAnchor.constraint(equalTo: questionLabel.heightAnchor),
            glyphMaximumHeight,
            questionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 240),
            labelWidth,
            collectionView.topAnchor.constraint(equalTo: content.answers.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: content.answers.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: content.answers.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: content.answers.trailingAnchor)
        ])
    }
}

private final class PracticeContentView: UIView {
    let question = UIView()
    let answers = UIView()
    private var divisions: [CGRect] = []
    private var previousBounds = CGRect.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        question.backgroundColor = .kanaKeyGrayColor()
        answers.backgroundColor = .white
        question.accessibilityIdentifier = "questionPane"
        answers.accessibilityIdentifier = "answerPane"
        addSubview(question)
        addSubview(answers)
        setNeedsUpdateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        if #available(iOS 27.1, *) {
            // UIKit tracks this query and invalidates constraints when the fold changes.
            let frames = reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
            if frames != divisions {
                divisions = frames
                setNeedsLayout()
            }
        }
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds != previousBounds {
            previousBounds = bounds
            setNeedsUpdateConstraints()
        }
        let layout = PracticeLayout(
            bounds: bounds,
            prefersColumns: traitCollection.horizontalSizeClass == .regular || traitCollection.verticalSizeClass == .compact,
            divisions: divisions,
            rightToLeft: effectiveUserInterfaceLayoutDirection == .rightToLeft
        )
        question.frame = layout.question
        answers.frame = layout.answers
    }
}

private final class AnswerGridLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }
}
