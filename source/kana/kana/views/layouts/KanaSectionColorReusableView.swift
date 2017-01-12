//
//  SectionColorReusableView.swift
//  kana
//
//  Created by JackyZ on 2017/01/12.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

class KanaSectionColorReusableView: UICollectionReusableView {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let attr = layoutAttributes as? KanaLayoutAttributes else {
            return
        }
        
        self.backgroundColor = attr.backgroundColor
    }
}
