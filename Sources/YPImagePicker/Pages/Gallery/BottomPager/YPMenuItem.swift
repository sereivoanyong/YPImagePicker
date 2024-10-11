//
//  YPMenuItem.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPMenuItem: UIView {
    
    private var isSelected: Bool = false
    var textLabel = UILabel()
    var button = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    func setup() {
        backgroundColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemBackgroundColor
        
        subviews(
            textLabel,
            button
        )
        
        textLabel.centerInContainer()
        |-(10)-textLabel-(10)-|
        button.fillContainer()
        
        textLabel.style { l in
            l.textAlignment = .center
            l.font = YPConfig.fonts.menuItemFont
            l.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemUnselectedTextColor
            l.adjustsFontSizeToFitWidth = true
            l.numberOfLines = 2
        }
    }

    func select() {
        isSelected = true
        textLabel.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemSelectedTextColor ?? tintColor
    }
    
    func deselect() {
        isSelected = false
        textLabel.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemUnselectedTextColor
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        if isSelected {
            if YPImagePickerConfiguration.shared.colors.bottomMenuItemSelectedTextColor == nil {
              textLabel.textColor = tintColor
            }
        }
    }
}
