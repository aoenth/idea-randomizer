//
//  UINavigationController+Extension.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-09.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit

extension UINavigationController {
  static var configuredController: UINavigationController {
    let vc = ViewController()
    let nav = UINavigationController()
    nav.navigationBar.prefersLargeTitles = true
    nav.viewControllers = [vc]
    return nav
  }
}
