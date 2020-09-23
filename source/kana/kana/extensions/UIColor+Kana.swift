//
//  UIColor+Kana.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func kanaKeyRedColor() -> UIColor {
        //81.6, 0.8, 10.
        return UIColor(red: 0.816, green: 0.08, blue: 0.106, alpha: 1)
    }
    
    class func kanaKeyGrayColor() -> UIColor {
        return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00)
    }
    
    class func kanaBlackColor() -> UIColor {
        return UIColor(red: 0.09, green: 0.08, blue: 0.07, alpha: 1.00)
    }
    
    class func kanaIncorrectAnswerBackgroundColor() -> UIColor {
        return UIColor(red: 0.94, green: 0.56, blue: 0.56, alpha: 1.00)
    }
}

