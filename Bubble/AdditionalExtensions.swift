//
//  AdditionalExtensions.swift
//  Bubble
//
//  Created by Alex Rodriguez on 12/27/16.
//  Copyright © 2016 magnitude. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
