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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        let img: UIImage = UIImage(named: "share-app-icon")!
        let messageStr:String  = "极简日语50音记忆+挑战APP，你真的把50音图都背下来了么？我不信，来这里试试吧。"
        let shareURL = URL(string: "https://itunes.apple.com/app/id1195345471")!
        let shareItems:[Any] = [img, messageStr, shareURL]
        
        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
        present(activityViewController, animated: true, completion: nil)

    }

}
