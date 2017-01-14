//
//  KanaHeaderView.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

protocol KanaHeaderDelegate {
    func hirakanaAction(_ sender:UIButton)
    func katakanaAction(_ sender:UIButton)
}

class KanaHeaderView: UICollectionReusableView {
    
    var delegate:KanaHeaderDelegate?

    @IBOutlet weak var hirakanaButton: UIButton!
    @IBOutlet weak var katakanaButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        hirakanaButton.layer.cornerRadius = hirakanaButton.bounds.size.width / 2
        katakanaButton.layer.cornerRadius = katakanaButton.bounds.size.width / 2
    }
    
    @IBAction func hirakanaAction(_ sender: UIButton) {
        delegate?.hirakanaAction(sender)
        hirakanaButton.backgroundColor = UIColor.kanaKeyRedColor()
        katakanaButton.backgroundColor = UIColor.kanaBlackColor()
        
    }
    
    @IBAction func katakanaAction(_ sender: UIButton) {
        delegate?.katakanaAction(sender)
        hirakanaButton.backgroundColor = UIColor.kanaBlackColor()
        katakanaButton.backgroundColor = UIColor.kanaKeyRedColor()
    }
    
}
