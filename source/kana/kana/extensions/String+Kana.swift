//
//  String+Kana.swift
//  kana
//
//  Created by JackyZ on 2017/01/26.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import Foundation

fileprivate func NSLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

extension String {
    static let lastNAvg = NSLocalizedString("LastNAvg")
}
