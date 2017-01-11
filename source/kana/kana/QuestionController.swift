//
//  ViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/07.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import JZSpringRefresh

class QuestionViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottom = scrollView.addSpringRefresh(position: .bottom, actionHandlere: { (v:JZSpringRefresh) in
            let vc = UIStoryboard(name: "Kana", bundle: nil).instantiateInitialViewController()
            self.present(vc!, animated: true, completion: { 
                //
            })
        })
        bottom.text = "五十音図"
        bottom.readyColor = UIColor.kanaKeyRedColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

