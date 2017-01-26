//
//  Double+Kana.swift
//  kana
//
//  Created by JackyZ on 2017/01/26.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
