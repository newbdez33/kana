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
    static let IntroText = NSLocalizedString("IntroText")
    static let Feedback = NSLocalizedString("Feedback")
    static let coffee = NSLocalizedString("Coffee")
    static let coffeeThanks = NSLocalizedString("CoffeeThanks")
    static let restore = NSLocalizedString("Restore")
    static let adPrivacy = NSLocalizedString("AdPrivacy")
    static let thanksTitle = NSLocalizedString("ThanksTitle")
    static let thanksMessage = NSLocalizedString("ThanksMessage")
    static let restoreNoneTitle = NSLocalizedString("RestoreNoneTitle")
    static let restoreNoneMessage = NSLocalizedString("RestoreNoneMessage")
    static let purchaseFailedTitle = NSLocalizedString("PurchaseFailedTitle")
    static let ok = NSLocalizedString("OK")
    static let chart = NSLocalizedString("Chart")
}
