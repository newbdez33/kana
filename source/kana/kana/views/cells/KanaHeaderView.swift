//
//  KanaHeaderView.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

class KanaHeaderView: UICollectionReusableView {

    @IBOutlet weak var hirakanaButton: UIButton!
    @IBOutlet weak var katakanaButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        hirakanaButton.layer.cornerRadius = hirakanaButton.bounds.size.width / 2
        katakanaButton.layer.cornerRadius = katakanaButton.bounds.size.width / 2
    }
    
}
