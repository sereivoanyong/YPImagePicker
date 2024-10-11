//
//  UIColor+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 26.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    static var offWhiteOrBlack: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                let rgbValue: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0 : 247
                return UIColor(r: rgbValue, g: rgbValue, b: rgbValue)
            }
        } else {
            return UIColor(r: 247, g: 247, b: 247)
        }
    }
    
    /// The color for text labels that contain primary content.
    ///
    /// Like `.label`, but backwards-compatible with iOS 12 and lower.
    static var ypLabel: UIColor {
        if #available(iOS 13, *) {
            return .label
        }
        return .black
    }
    
    static var ypSecondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }
        return UIColor(r: 153, g: 153, b: 153)
    }
    
    /// The color for the main background of your interface.
    ///
    /// Like `.systemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return .white
    }
    
    /// The color for content layered on top of the main background.
    ///
    /// Like `.secondarySystemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSecondarySystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemBackground
        }
        return UIColor(r: 247, g: 247, b: 247)
    }
}
