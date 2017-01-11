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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //
        let top = collectionView.addSpringRefresh(position: .top, actionHandlere: { (_) in
            self.dismiss(animated: true, completion: { 
                //
            })
        })
            
        top.text = "戻る"
        top.readyColor = UIColor.kanaKeyRedColor()
        
        //collectionView
        collectionView.register(UINib(nibName: "KanaCell", bundle: nil), forCellWithReuseIdentifier: "KanaCell")
        collectionView.register(UINib(nibName: "KanaHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "KanaHeaderView")

        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension KanaViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KanaCell", for: indexPath) as! KanaCell
        cell.backgroundColor = UIColor.yellow
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50;
    }
    
    // Cell Size Change
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let v = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "KanaHeaderView", for: indexPath)
            return v
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let size = CGSize(width: 400, height: 50)
        return size
    }
    
}
