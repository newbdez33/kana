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
    @IBOutlet weak var collectionView: UICollectionView!
    
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
        
        collectionView.register(UINib(nibName: "AnswerCell", bundle: nil), forCellWithReuseIdentifier: "AnswerCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension QuestionViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnswerCell", for: indexPath) as! AnswerCell
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4;
    }
    
    // Cell Size Change
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    
}

