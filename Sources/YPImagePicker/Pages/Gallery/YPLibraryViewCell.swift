//
//  YPLibraryViewCell.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPMultipleSelectionIndicator: UIView {
    
    let circle = UIView()
    let label = UILabel()
    var selectionColor: UIColor?

    convenience init() {
        self.init(frame: .zero)
        
        let size: CGFloat = 20
        
        subviews(
            circle,
            label
        )
        
        circle.fillContainer()
        circle.size(size)
        label.fillContainer()
        
        circle.layer.cornerRadius = size / 2.0
        label.textAlignment = .center
        label.textColor = .white
        label.font = YPConfig.fonts.multipleSelectionIndicatorFont
    }
    
    var number: Int? {
        didSet {
            label.isHidden = number == nil
            if let number {
                circle.backgroundColor = selectionColor ?? tintColor
                circle.layer.borderColor = UIColor.clear.cgColor
                circle.layer.borderWidth = 0
                label.text = "\(number)"
            } else {
                circle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
                circle.layer.borderColor = UIColor.white.cgColor
                circle.layer.borderWidth = 1
                label.text = ""
            }
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        if number != nil {
            if selectionColor == nil {
                circle.backgroundColor = tintColor
            }
        }
    }
}

class YPLibraryViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    let imageView = UIImageView()
    let durationLabel = UILabel()
    let selectionOverlay = UIView()
    let multipleSelectionIndicator = YPMultipleSelectionIndicator()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviews(
            imageView,
            durationLabel,
            selectionOverlay,
            multipleSelectionIndicator
        )

        imageView.fillContainer()
        selectionOverlay.fillContainer()
        layout(
            durationLabel-5-|,
            5
        )
        
        layout(
            3,
            multipleSelectionIndicator-3-|
        )
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        durationLabel.textColor = .white
        durationLabel.font = YPConfig.fonts.durationFont
        durationLabel.isHidden = true
        selectionOverlay.backgroundColor = .white
        selectionOverlay.alpha = 0
        backgroundColor = .ypSecondarySystemBackground
        setAccessibilityInfo()
    }

    var isSelectedForDisplay: Bool = false {
        didSet { refreshSelection() }
    }
    
    private func refreshSelection() {
        let showOverlay = isSelectedForDisplay
        selectionOverlay.alpha = showOverlay ? 0.6 : 0
    }

    private func setAccessibilityInfo() {
        isAccessibilityElement = true
        self.accessibilityIdentifier = "YPLibraryViewCell"
        self.accessibilityLabel = "Library Image"
    }
}
