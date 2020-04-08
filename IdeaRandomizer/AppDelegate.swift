//
//  AppDelegate.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-07.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    let navigationController = UINavigationController(rootViewController: ViewController())
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
    return true
  }

}

