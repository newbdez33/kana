//
//  KanaViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

class KanaViewController: UIViewController {
    
    var currentKanaType:KanaType = .hiragana {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //
//        let top = collectionView.addSpringRefresh(position: .top, actionHandlere: { (_) in
//            self.dismiss(animated: true, completion: {
//                //
//            })
//        })
//            
//        top.text = "戻る"
//        top.readyColor = UIColor.kanaKeyRedColor()
        
        //collectionView
        collectionView.register(UINib(nibName: "KanaCell", bundle: nil), forCellWithReuseIdentifier: "KanaCell")
        collectionView.register(UINib(nibName: "KanaHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "KanaHeaderView")

        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension KanaViewController : KanaHeaderDelegate {
    
    func katakanaAction(_ sender: UIButton) {
        currentKanaType = .katakana
    }
    
    func hirakanaAction(_ sender: UIButton) {
        currentKanaType = .hiragana
    }
}

extension KanaViewController : UICollectionViewDelegate, UICollectionViewDataSource, KanaCollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KanaCell", for: indexPath) as! KanaCell
        let kanaArray = AppConfig.monographs[indexPath.section][indexPath.row]
        cell.kanaLabel.text = kanaArray[currentKanaType.rawValue]
        cell.romaLabel.text = kanaArray[KanaType.roma.rawValue]
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return AppConfig.monographs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let chars = AppConfig.monographs[section]
        return chars.count;
    }
    
    // Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCells:CGFloat = 5.0
        let margin:CGFloat = 10.0
        let width = self.view.bounds.size.width / numberOfCells - margin - margin/2
        let retval = CGSize(width: width, height: 60)
        return retval
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let margin:CGFloat = 10.0
        return UIEdgeInsets(top: margin+8, left: margin, bottom: margin, right: margin)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let v = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "KanaHeaderView", for: indexPath) as! KanaHeaderView
            v.delegate = self
            return v
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            let size = CGSize(width: UIScreen.main.bounds.width, height: 140)
            return size
        }
        return CGSize.zero
    }
    
    //
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, backgroundColorForSectionAt section: Int) -> UIColor {
        if section % 2 == 0 {
            return UIColor.white
        } else {
            return UIColor.kanaKeyGrayColor()
        }
    }
    
}
