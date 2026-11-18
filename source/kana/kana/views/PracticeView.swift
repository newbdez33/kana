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
    private let questionPane = UIView()
    private let answerPane = UIView()
    private var divisions: [CGRect] = []
    private let prompt = UIView()
    private(set) var bannerHeight: NSLayoutConstraint!
    private var menuHeight: NSLayoutConstraint!
    private var promptMinimumHeight: NSLayoutConstraint!
    private var glyphMaximumHeight: NSLayoutConstraint!
    private var bannerLeft: NSLayoutConstraint!
    private var bannerRight: NSLayoutConstraint!
    private var occlusions: [CGRect] = []
    private var previousBounds = CGRect.zero

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
        questionPane.backgroundColor = .kanaKeyGrayColor()
        answerPane.backgroundColor = .white
        questionPane.accessibilityIdentifier = "questionPane"
        answerPane.accessibilityIdentifier = "answerPane"
        addSubview(questionPane)
        addSubview(answerPane)
        questionPane.addSubview(scrollView)
        scrollView.addSubview(prompt)
        prompt.addSubview(menuContainer)
        prompt.addSubview(statisticsView)
        prompt.addSubview(feedbackView)
        prompt.addSubview(questionLabel)
        questionPane.addSubview(bannerView)
        answerPane.addSubview(collectionView)

        questionLabel.font = UIFont(name: "Hosofuwafont", size: 155)
        questionLabel.textColor = .kanaBlackColor()
        questionLabel.textAlignment = .center
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.1
        questionLabel.accessibilityIdentifier = "questionLabel"
        collectionView.backgroundColor = .white
        collectionView.isScrollEnabled = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.accessibilityIdentifier = "answerGrid"
        menuContainer.clipsToBounds = true
        bannerView.clipsToBounds = true

        for child in [scrollView, prompt, menuContainer, statisticsView, questionLabel, bannerView, collectionView, feedbackView] {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        let labelArea = UILayoutGuide()
        prompt.addLayoutGuide(labelArea)
        menuHeight = menuContainer.heightAnchor.constraint(equalToConstant: 0)
        bannerHeight = bannerView.heightAnchor.constraint(equalToConstant: 0)
        promptMinimumHeight = labelArea.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        glyphMaximumHeight = questionLabel.heightAnchor.constraint(lessThanOrEqualTo: labelArea.heightAnchor, constant: -80)
        let viewportHeight = prompt.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        // Shrink the glyph before making the prompt taller than its viewport.
        viewportHeight.priority = UILayoutPriority(999)
        bannerLeft = bannerView.leftAnchor.constraint(equalTo: questionPane.leftAnchor)
        bannerRight = bannerView.rightAnchor.constraint(equalTo: questionPane.rightAnchor)
        let labelWidth = questionLabel.widthAnchor.constraint(equalTo: prompt.widthAnchor, multiplier: 0.35)
        labelWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: questionPane.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bannerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: questionPane.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: questionPane.trailingAnchor),
            prompt.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            prompt.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            prompt.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            prompt.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            viewportHeight,
            menuContainer.topAnchor.constraint(equalTo: prompt.topAnchor),
            menuContainer.leadingAnchor.constraint(equalTo: questionPane.safeAreaLayoutGuide.leadingAnchor),
            menuContainer.trailingAnchor.constraint(equalTo: questionPane.safeAreaLayoutGuide.trailingAnchor),
            menuHeight,
            statisticsView.topAnchor.constraint(equalTo: menuContainer.bottomAnchor, constant: 12),
            statisticsView.leadingAnchor.constraint(equalTo: questionPane.safeAreaLayoutGuide.leadingAnchor),
            statisticsView.trailingAnchor.constraint(equalTo: questionPane.safeAreaLayoutGuide.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: questionPane.bottomAnchor),
            bannerLeft,
            bannerRight,
            bannerHeight,
            labelArea.topAnchor.constraint(equalTo: statisticsView.bottomAnchor),
            labelArea.bottomAnchor.constraint(equalTo: prompt.bottomAnchor),
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
            collectionView.topAnchor.constraint(equalTo: answerPane.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: answerPane.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: answerPane.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: answerPane.trailingAnchor)
        ])
        setNeedsUpdateConstraints()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsUpdateConstraints()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

    override func updateConstraints() {
        if #available(iOS 27.1, *) {
            // UIKit invalidates these queries when system UI or the fold moves.
            let divisions = reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
            let regions = reservedRegions(kind: .occlusion).map(\.frame)
            if self.divisions != divisions || occlusions != regions {
                self.divisions = divisions
                occlusions = regions
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
            safeArea: bounds.inset(by: safeAreaInsets),
            prefersColumns: traitCollection.horizontalSizeClass == .regular || traitCollection.verticalSizeClass == .compact,
            divisions: divisions,
            occlusions: occlusions,
            rightToLeft: effectiveUserInterfaceLayoutDirection == .rightToLeft
        )
        questionPane.frame = layout.question
        answerPane.frame = layout.answers
        let pane = layout.question
        let banner = CGRect(x: pane.minX, y: pane.maxY - bannerHeight.constant,
                            width: pane.width, height: bannerHeight.constant)
        let available = PracticeLayout.horizontalFrame(in: banner, avoiding: occlusions)
        bannerLeft.constant = available.minX - pane.minX
        bannerRight.constant = available.maxX - pane.maxX
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

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        if let context = context as? UICollectionViewFlowLayoutInvalidationContext,
           collectionView?.bounds.size != newBounds.size {
            context.invalidateFlowLayoutDelegateMetrics = true
        }
        return context
    }
}
