//
//  MenuViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/23.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import MessageUI

class MenuViewController: UIViewController, MFMailComposeViewControllerDelegate {

    let coffeeButton = UIButton(type: .system)
    let chartButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)

    let shareURL = URL(string: "https://itunes.apple.com/app/id1195345471")!
    let messageStr:String  = .IntroText
    let img: UIImage = UIImage(named: "share-app-icon")!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .kanaKeyGrayColor()

        configureButton(chartButton, title: .chart, symbol: "square.grid.3x3", action: #selector(chartAction))
        configureButton(coffeeButton, title: .support, symbol: "cup.and.saucer", action: #selector(coffeeAction))
        coffeeButton.accessibilityIdentifier = "coffeeMenu"
        chartButton.accessibilityIdentifier = "chartMenu"
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .kanaSecondaryColor
        moreButton.accessibilityLabel = .more
        moreButton.accessibilityIdentifier = "moreMenu"
        moreButton.showsMenuAsPrimaryAction = true

        let row = UIStackView(arrangedSubviews: [chartButton, UIView(), coffeeButton, moreButton])
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(row)
        let preferredWidth = row.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            row.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            row.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            row.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            preferredWidth,
            chartButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            coffeeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            moreButton.widthAnchor.constraint(equalToConstant: 44),
            moreButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        updatePurchaseButtons()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePurchaseButtons), name: .adsRemovedDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePurchaseButtons), name: .adsReadyDidChange, object: nil)
    }

    private func configureButton(_ button: UIButton, title: String, symbol: String, action: Selector) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 8
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        configuration.baseForegroundColor = .kanaBlackColor()
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 14, weight: .medium)
            return attributes
        }
        button.configuration = configuration
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    func setExpanded(_ expanded: Bool) {
        view.isHidden = !expanded
        view.accessibilityElementsHidden = !expanded
    }

    @objc func updatePurchaseButtons() {
        var configuration = coffeeButton.configuration
        configuration?.baseForegroundColor = .kanaAccentColor
        configuration?.image = UIImage(systemName: Store.shared.adsRemoved ? "heart" : "cup.and.saucer")
        coffeeButton.configuration = configuration

        var actions = [UIAction(title: .share, image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self else { return }
            self.shareAction(self.moreButton)
        }]
        if MFMailComposeViewController.canSendMail() {
            actions.append(UIAction(title: .Feedback, image: UIImage(systemName: "envelope")) { [weak self] _ in
                self?.sendEmail()
            })
        }
        if !Store.shared.adsRemoved && AdsManager.shared.isPrivacyOptionsRequired {
            actions.append(UIAction(title: .adPrivacy, image: UIImage(systemName: "hand.raised")) { [weak self] _ in
                guard let self else { return }
                AdsManager.shared.presentPrivacyOptions(from: self)
            })
        }
        moreButton.menu = UIMenu(children: actions)
    }

    @objc func coffeeAction(_ sender: UIButton) {
        let coffee = CoffeeViewController()
        let regularWidth = traitCollection.horizontalSizeClass == .regular
        coffee.modalPresentationStyle = regularWidth ? .formSheet : .pageSheet
        coffee.preferredContentSize = CGSize(width: 520, height: 720)
        if let sheet = coffee.sheetPresentationController {
            if !regularWidth { sheet.detents = [.large()] }
            sheet.prefersGrabberVisible = !regularWidth
            sheet.preferredCornerRadius = 28
        }
        present(coffee, animated: true)
    }

    /// The gojūon chart; presented as a sheet so it can be swiped away.
    @IBAction func chartAction(_ sender: UIButton) {
        guard let chart = UIStoryboard(name: "Kana", bundle: nil).instantiateInitialViewController() else { return }
        chart.view.accessibilityIdentifier = "kanaChart"
        present(chart, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .ok, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Share and feedback

    @IBAction func shareAction(_ sender: UIButton) {

        let shareItems:[Any] = [img, messageStr, shareURL]

        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender
        activityViewController.popoverPresentationController?.sourceRect = sender.bounds
        present(activityViewController, animated: true, completion: nil)

    }

    @IBAction func feedbackAction(_ sender: UIButton) {
        sendEmail()
    }

    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["newbdez33+kana.feedback@gmail.com"])
            mail.setSubject(.Feedback)
            mail.setMessageBody("", isHTML: false)

            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}
