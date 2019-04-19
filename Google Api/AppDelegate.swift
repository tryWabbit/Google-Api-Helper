//
//  AppDelegate.swift
//  Google Api
//
//  Created by Wabbit on 4/12/19.
//  Copyright © 2019 Wabbit. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GoogleApi.shared.initialiseWithKey("")
        return true
    }
}

