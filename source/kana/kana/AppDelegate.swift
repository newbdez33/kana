//
//  AppDelegate.swift
//  kana
//
//  Created by JackyZ on 2017/01/07.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import MonkeyKing
import RealmSwift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-1295607594822275~2834593518")
        
        Realm.Configuration.defaultConfiguration = AppConfig.realmConfig()
        Fabric.with([Crashlytics.self])

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if MonkeyKing.handleOpenURL(url) {
            return true
        }
        return false
    }
}

