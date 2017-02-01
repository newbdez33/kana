//
//  MenuViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/23.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

//http://www.flaticon.com/packs/outicons

import UIKit
import MonkeyKing

class MenuViewController: UIViewController {
    
    let shareURL = URL(string: "https://itunes.apple.com/app/id1195345471")!
    let messageStr:String  = .IntroText
    let img: UIImage = UIImage(named: "share-app-icon")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        
        
        let shareItems:[Any] = [img, messageStr, shareURL]

        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)    //[qqActivity()]
        
        present(activityViewController, animated: true, completion: nil)

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
