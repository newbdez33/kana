//
//  UIColor+Kana.swift
//  kana
//
//  Created by JackyZ on 2017/01/11.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import SwiftHEXColors

extension UIColor {
    class func kanaKeyRedColor() -> UIColor {
        //81.6, 0.8, 10.
        return UIColor(red: 0.816, green: 0.08, blue: 0.106, alpha: 1)
    }
    
    class func kanaKeyGrayColor() -> UIColor {
        return UIColor(hexString: "f8f8f8")!
    }
    
    class func kanaBlackColor() -> UIColor {
        return UIColor(hexString: "171412")!
    }
}
