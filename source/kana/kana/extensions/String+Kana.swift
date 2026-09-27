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
    static let practice = NSLocalizedString("Practice")
    static let statAnswers = NSLocalizedString("StatAnswers")
    static let statAverage = NSLocalizedString("StatAverage")
    static let statRecent = NSLocalizedString("StatRecent")
    static let statBest = NSLocalizedString("StatBest")
    static let statSeconds = NSLocalizedString("StatSeconds")
    static let menu = NSLocalizedString("Menu")
    static let closeMenu = NSLocalizedString("CloseMenu")
    static let close = NSLocalizedString("Close")
    static let more = NSLocalizedString("More")
    static let share = NSLocalizedString("Share")
    static let support = NSLocalizedString("Support")
    static let coffeeMessage = NSLocalizedString("CoffeeMessage")
    static let coffeeBenefit = NSLocalizedString("CoffeeBenefit")
    static let coffeeSupported = NSLocalizedString("CoffeeSupported")
    static let coffeePrice = NSLocalizedString("CoffeePrice")
    static let coffeeTerms = NSLocalizedString("CoffeeTerms")
    static let coffeeLoading = NSLocalizedString("CoffeeLoading")
    static let coffeeUnavailable = NSLocalizedString("CoffeeUnavailable")
    static let coffeePending = NSLocalizedString("CoffeePending")
    static let coffeePendingMessage = NSLocalizedString("CoffeePendingMessage")
    static let coffeePurchasing = NSLocalizedString("CoffeePurchasing")
    static let coffeeRestoring = NSLocalizedString("CoffeeRestoring")
    static let continuePractice = NSLocalizedString("ContinuePractice")
    static let retry = NSLocalizedString("Retry")
    static let purchaseUnverified = NSLocalizedString("PurchaseUnverified")
}
