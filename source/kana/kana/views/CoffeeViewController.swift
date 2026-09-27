import UIKit

final class CoffeeViewController: UIViewController {

    let purchaseButton = UIButton(type: .system)
    let restoreButton = UIButton(type: .system)
    let statusLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let illustration = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let benefitLabel = UILabel()
    private let termsLabel = UILabel()
    private let store: CoffeeStore
    private var isLoading = false
    private var operation: Operation?
    private var isPending = false

    private enum Operation {
        case purchase, restore
    }

    init(store: CoffeeStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(store: Store.shared)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .kanaPaperColor
        view.accessibilityIdentifier = "coffeeSheet"
        overrideUserInterfaceStyle = .light
        buildContent()
        NotificationCenter.default.addObserver(self, selector: #selector(updateContent), name: .adsRemovedDidChange, object: nil)
        updateContent()
        if !store.adsRemoved { loadProduct() }
    }

    private func buildContent() {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)), for: .normal)
        closeButton.tintColor = .kanaSecondaryColor
        closeButton.backgroundColor = UIColor.kanaBlackColor().withAlphaComponent(0.05)
        closeButton.layer.cornerRadius = 22
        closeButton.accessibilityLabel = .close
        closeButton.accessibilityIdentifier = "coffeeClose"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        illustration.contentMode = .center
        illustration.tintColor = .kanaAccentColor
        illustration.backgroundColor = UIColor.kanaAccentColor.withAlphaComponent(0.07)
        illustration.layer.cornerRadius = 48
        illustration.isAccessibilityElement = false
        let illustrationRow = UIStackView(arrangedSubviews: [illustration])
        illustrationRow.alignment = .center
        illustrationRow.axis = .vertical

        let badge = UIImageView(image: UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11)))
        badge.contentMode = .center
        badge.tintColor = .white
        badge.backgroundColor = .kanaAccentColor
        badge.layer.cornerRadius = 14
        badge.layer.borderColor = UIColor.kanaPaperColor.cgColor
        badge.layer.borderWidth = 4
        badge.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(badge)

        titleLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .systemFont(ofSize: 28, weight: .semibold))
        titleLabel.textColor = .kanaBlackColor()
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityIdentifier = "coffeeTitle"
        messageLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        messageLabel.textColor = .kanaSecondaryColor
        benefitLabel.font = .preferredFont(forTextStyle: .subheadline)
        benefitLabel.textColor = .kanaSecondaryColor
        termsLabel.text = .coffeeTerms
        termsLabel.font = .preferredFont(forTextStyle: .caption1)
        termsLabel.textColor = .kanaSecondaryColor
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .kanaSecondaryColor
        statusLabel.accessibilityIdentifier = "coffeeStatus"
        for label in [titleLabel, messageLabel, benefitLabel, termsLabel, statusLabel] {
            label.numberOfLines = 0
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
        }

        let benefitIcon = UIImageView(image: UIImage(systemName: "checkmark.circle"))
        benefitIcon.tintColor = .kanaAccentColor
        benefitIcon.contentMode = .scaleAspectFit
        let benefitRow = UIStackView(arrangedSubviews: [UIView(), benefitIcon, benefitLabel, UIView()])
        benefitRow.alignment = .center
        benefitRow.spacing = 8
        let benefit = UIStackView(arrangedSubviews: [divider(), benefitRow, divider()])
        benefit.axis = .vertical
        benefit.spacing = 16

        purchaseButton.accessibilityIdentifier = "coffeePurchase"
        purchaseButton.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        restoreButton.setTitle(.restore, for: .normal)
        restoreButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        restoreButton.titleLabel?.adjustsFontForContentSizeCategory = true
        restoreButton.tintColor = .kanaSecondaryColor
        restoreButton.accessibilityIdentifier = "coffeeRestore"
        restoreButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)

        let footer = UILabel()
        footer.text = "五 十 音"
        footer.font = UIFont(name: "HiraginoMinchoProN-W3", size: 17) ?? .systemFont(ofSize: 17, weight: .light)
        footer.textColor = UIColor.kanaSecondaryColor.withAlphaComponent(0.45)
        footer.textAlignment = .center
        footer.isAccessibilityElement = false
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        let content = UIStackView(arrangedSubviews: [illustrationRow, titleLabel, messageLabel, benefit, purchaseButton, termsLabel, statusLabel, restoreButton, spacer, footer])
        content.axis = .vertical
        content.spacing = 12
        content.setCustomSpacing(24, after: illustrationRow)
        content.setCustomSpacing(28, after: messageLabel)
        content.setCustomSpacing(26, after: benefit)
        content.setCustomSpacing(4, after: termsLabel)
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        let preferredWidth = content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -56)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            content.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 380),
            content.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -56),
            content.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor, constant: -32),
            preferredWidth,
            illustration.widthAnchor.constraint(equalToConstant: 96),
            illustration.heightAnchor.constraint(equalToConstant: 96),
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),
            badge.trailingAnchor.constraint(equalTo: illustration.trailingAnchor),
            badge.bottomAnchor.constraint(equalTo: illustration.bottomAnchor),
            benefitIcon.widthAnchor.constraint(equalToConstant: 18),
            benefitIcon.heightAnchor.constraint(equalToConstant: 18),
            benefitRow.arrangedSubviews[0].widthAnchor.constraint(equalTo: benefitRow.arrangedSubviews[3].widthAnchor),
            purchaseButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            restoreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 8)
        ])
    }

    private func divider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.kanaBlackColor().withAlphaComponent(0.1)
        view.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return view
    }

    @objc private func updateContent() {
        let purchased = store.adsRemoved
        if purchased { isPending = false }
        titleLabel.text = purchased ? .coffeeThanks : .coffee
        messageLabel.text = purchased ? .thanksMessage : .coffeeMessage
        benefitLabel.text = purchased ? .coffeeSupported : .coffeeBenefit
        illustration.image = UIImage(systemName: purchased ? "heart" : "cup.and.saucer", withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .ultraLight))
        statusLabel.text = purchased ? nil : isPending ? .coffeePendingMessage : (!isLoading && store.coffeePrice == nil ? .coffeeUnavailable : nil)
        statusLabel.isHidden = statusLabel.text == nil

        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .kanaAccentColor
        configuration.baseForegroundColor = .white
        configuration.background.cornerRadius = 14
        configuration.cornerStyle = .fixed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14)
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.preferredFont(forTextStyle: .headline)
            return attributes
        }
        if let operation {
            configuration.title = operation == .purchase ? .coffeePurchasing : .coffeeRestoring
        } else if purchased {
            configuration.title = .continuePractice
        } else if isPending {
            configuration.title = .coffeePending
        } else if isLoading {
            configuration.title = .coffeeLoading
        } else {
            configuration.title = store.coffeePrice.map { String.localizedStringWithFormat(.coffeePrice, $0) } ?? .retry
        }
        configuration.showsActivityIndicator = operation != nil || (isLoading && !purchased)
        purchaseButton.configuration = configuration
        purchaseButton.isEnabled = operation == nil && (purchased || (!isLoading && !isPending))
        restoreButton.isEnabled = operation == nil
        restoreButton.isHidden = purchased
        termsLabel.isHidden = purchased
        closeButton.isEnabled = operation == nil
        isModalInPresentation = operation != nil
    }

    private func loadProduct() {
        isLoading = true
        updateContent()
        Task { [weak self] in
            guard let self else { return }
            await store.loadProduct()
            isLoading = false
            updateContent()
        }
    }

    @objc func purchaseAction() {
        guard operation == nil else { return }
        if store.adsRemoved {
            close()
            return
        }
        guard !isLoading && !isPending else { return }
        guard store.coffeePrice != nil else {
            loadProduct()
            return
        }
        perform(.purchase) {
            let outcome = try await self.store.purchaseCoffee()
            self.isPending = outcome == .pending
        }
    }

    @objc func restoreAction() {
        guard operation == nil else { return }
        perform(.restore) {
            let restored = try await self.store.restore()
            if !restored {
                self.showAlert(title: .restoreNoneTitle, message: .restoreNoneMessage)
            }
        }
    }

    private func perform(_ operation: Operation, action: @escaping () async throws -> Void) {
        self.operation = operation
        updateContent()
        Task {
            do {
                try await action()
            } catch {
                showAlert(title: .purchaseFailedTitle, message: error.localizedDescription)
            }
            self.operation = nil
            updateContent()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .ok, style: .default))
        present(alert, animated: true)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
