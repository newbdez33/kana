//
//  MenuViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/23.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

//http://www.flaticon.com/packs/outicons

import UIKit
import MessageUI

class MenuViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var coffeeButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var chartButton: UIButton!

    let shareURL = URL(string: "https://itunes.apple.com/app/id1195345471")!
    let messageStr:String  = .IntroText
    let img: UIImage = UIImage(named: "share-app-icon")!

    override func viewDidLoad() {
        super.viewDidLoad()

        if !MFMailComposeViewController.canSendMail() {
            let v = self.view.viewWithTag(1)
            v?.isHidden = true
        }

        restoreButton.setTitle(.restore, for: .normal)
        privacyButton.setTitle(.adPrivacy, for: .normal)
        chartButton.setTitle(String.chart + " ›", for: .normal)
        updatePurchaseButtons()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePurchaseButtons), name: .adsRemovedDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePurchaseButtons), name: .adsReadyDidChange, object: nil)
    }

    private var isExpanded = false

    /// The top row (chart, ad privacy) sits under the status bar while the menu is
    /// collapsed, so it is only shown once the menu has been pulled down.
    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        updatePurchaseButtons()
    }

    @objc func updatePurchaseButtons() {
        let removed = Store.shared.adsRemoved
        coffeeButton.setTitle(removed ? .coffeeThanks : .coffee, for: .normal)
        coffeeButton.isEnabled = !removed
        restoreButton.isHidden = removed
        chartButton.isHidden = !isExpanded
        privacyButton.isHidden = !isExpanded || removed || !AdsManager.shared.isPrivacyOptionsRequired
    }

    // MARK: - Purchase

    @IBAction func coffeeAction(_ sender: UIButton) {
        sender.isEnabled = false
        Task {
            do {
                if try await Store.shared.purchaseCoffee() {
                    showAlert(title: .thanksTitle, message: .thanksMessage)
                }
            } catch {
                showAlert(title: .purchaseFailedTitle, message: error.localizedDescription)
            }
            updatePurchaseButtons()
        }
    }

    @IBAction func restoreAction(_ sender: UIButton) {
        sender.isEnabled = false
        Task {
            do {
                if try await Store.shared.restore() {
                    showAlert(title: .thanksTitle, message: .thanksMessage)
                } else {
                    showAlert(title: .restoreNoneTitle, message: .restoreNoneMessage)
                }
            } catch {
                showAlert(title: .purchaseFailedTitle, message: error.localizedDescription)
            }
            sender.isEnabled = true
            updatePurchaseButtons()
        }
    }

    @IBAction func privacyAction(_ sender: UIButton) {
        AdsManager.shared.presentPrivacyOptions(from: self)
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
