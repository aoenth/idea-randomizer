//
//  SceneDelegate.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-07.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?


  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }
    let rootViewController = createRootViewController()
    window = UIWindow(windowScene: scene)
    window?.rootViewController = rootViewController
    window?.makeKeyAndVisible()
  }
  
  func createRootViewController() -> UIViewController {
    let vc = ViewController()
    let nav = UINavigationController()
    nav.viewControllers = [vc]
    return nav
  }

}
