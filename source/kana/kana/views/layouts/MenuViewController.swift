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
import MonkeyKing
import Crashlytics

class MenuViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let shareURL = URL(string: "https://itunes.apple.com/app/id1195345471")!
    let messageStr:String  = .IntroText
    let img: UIImage = UIImage(named: "share-app-icon")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !MFMailComposeViewController.canSendMail() {
            let v = self.view.viewWithTag(1)
            v?.isHidden = true
        }
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        
        let shareItems:[Any] = [img, messageStr, shareURL]

        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)    //[qqActivity()]
        activityViewController.popoverPresentationController?.sourceView = sender
        activityViewController.popoverPresentationController?.sourceRect = sender.bounds

        activityViewController.completionWithItemsHandler = {(type:UIActivityType?, completed:Bool, items:[Any]?, error:Error?) in
            
            if !completed {
                //cancelled
                return
            }
            
            //shared successfully
            let activity:String = type!.rawValue
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            //
            Answers.logShare(withMethod: activity,
                                       contentName: "Sharing app",
                                       contentType: activity,
                                       contentId: "app-version-\(version!)",
                                       customAttributes: [:])
        }
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
    
    func qqActivity() -> AnyActivity {
        MonkeyKing.registerAccount(.qq(appID: "1105892489"))
        let sessionMessage = MonkeyKing.Message.qq(.friends(info: (title: "QQ", description: messageStr, thumbnail: UIImage(named: "share-app-icon")!, media: MonkeyKing.Media.url(shareURL))))
        let qqActivity = AnyActivity(
            type: UIActivityType(rawValue: "com.salmonapps.kana.qq.session"),
            title: "QQ",
            image: UIImage(named: "QQ")!,
            message: sessionMessage,
            completionHandler: { success in
                print("Session success: \(success)")
        })
        return qqActivity
    }

}
