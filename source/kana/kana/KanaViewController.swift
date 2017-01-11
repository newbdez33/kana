//
//  KanaViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import JZSpringRefresh

class KanaViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let top = scrollView.addSpringRefresh(position: .top, actionHandlere: { (_) in
            self.dismiss(animated: true, completion: { 
                //
            })
        })
            
        top.text = "戻る"
        top.readyColor = UIColor.kanaKeyRedColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
