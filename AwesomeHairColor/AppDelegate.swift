//
//  AppDelegate.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/9/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import UIKit
import Fritz

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FritzCore.configure()
        return true
    }

}

