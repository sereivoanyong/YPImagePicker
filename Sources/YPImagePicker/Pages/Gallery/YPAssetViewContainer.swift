//
//  YPAssetViewContainer.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 15/11/2016.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import UIKit
import Stevia
import AVFoundation

/// The container for asset (video or image). It containts the YPGridView and YPAssetZoomableView.
final class YPAssetViewContainer: UIView {
    public var zoomableView: YPAssetZoomableView
    public var itemOverlay: UIView?
    public let contentView = UIView()
    public let curtain = UIView()
    public let spinnerView = UIView()
    public let albumButton: UIButton = {
        if #available(iOS 15.0, *) {
            var configuration: UIButton.Configuration = .plain()
            let font: UIFont = .systemFont(ofSize: 15, weight: .semibold)
            configuration.titleTextAttributesTransformer = .init { container in
                container
                    .font(font)
            }
            configuration.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small))
            configuration.imagePadding = 2
            configuration.imagePlacement = .trailing
            configuration.imageColorTransformer = .init { _ in
                .tertiaryLabel
            }
            let button = UIButton(configuration: configuration)
            button.tintColor = .label
            return button
        }
        let v = UIButton()
        return v
    }()
    public let squareCropButton: UIButton = {
        if #available(iOS 15.0, *) {
            var configuration: UIButton.Configuration = .gray()
            configuration.buttonSize = .mini
            configuration.cornerStyle = .capsule
            configuration.image = YPConfig.icons.iOS15CropIcon ?? UIImage(systemName: "arrow.down.backward.and.arrow.up.forward", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))
            let button = UIButton(configuration: configuration)
            return button
        }
        let v = UIButton()
        v.setImage(YPConfig.icons.cropIcon, for: .normal)
        return v
    }()
    public let multipleSelectionButton: UIButton = {
        if #available(iOS 15.0, *) {
            var configuration: UIButton.Configuration = .gray()
            configuration.buttonSize = .mini
            configuration.cornerStyle = .capsule
            configuration.image = YPConfig.icons.iOS15MultipleSelectionIcon ?? UIImage(systemName: "rectangle.on.rectangle", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))
            let button = UIButton(configuration: configuration)
            return button
        }
        let v = UIButton()
        v.setImage(YPConfig.icons.multipleSelectionOffIcon, for: .normal)
        return v
    }()
    public var onlySquare = YPConfig.library.onlySquare
    public var isShown = true
    public var spinnerIsShown = false
    
    private let spinner = UIActivityIndicatorView(style: .white)
    private var shouldCropToSquare = YPConfig.library.isSquareByDefault
    private var isMultipleSelectionEnabled = false

    public var itemOverlayType = YPConfig.library.itemOverlayType

    init(frame: CGRect, zoomableView: YPAssetZoomableView) {
        self.zoomableView = zoomableView
        super.init(frame: frame)

        self.zoomableView.zoomableViewDelegate = self

        switch itemOverlayType {
        case .grid:
            itemOverlay = YPGridView()
        default:
            break
        }

        if let itemOverlay = itemOverlay {
            addSubview(itemOverlay)
            itemOverlay.frame = frame
            clipsToBounds = true

            itemOverlay.alpha = 0
        }

        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        addGestureRecognizer(touchDownGR)

        // TODO: Add tap gesture to play/pause. Add double tap gesture to square/unsquare

        subviews(
            contentView.subviews(
                spinnerView.subviews(
                    spinner
                ),
                curtain
            )
        )

        contentView.fillHorizontally()
        contentView.heightEqualsWidth()
        spinner.centerInContainer()
        spinnerView.fillContainer()
        curtain.fillContainer()

        spinner.startAnimating()
        spinnerView.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.3)
        curtain.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.7)
        curtain.alpha = 0

        subviews(albumButton)
        if #available(iOS 15.0, *) {
            albumButton.height(44)
            albumButton.leading(15 - albumButton.configuration!.contentInsets.leading)
            albumButton.Bottom == self.Bottom
        } else {
            albumButton.height(42)
            albumButton.leading(15)
            albumButton.Bottom == self.Bottom - 15
        }

        if !onlySquare {
            // Crop Button
            subviews(squareCropButton)
            if #available(iOS 15.0, *) {
                squareCropButton.size(36)
                |-15-squareCropButton
                squareCropButton.Bottom == self.Bottom - (44 + 4)
            } else {
                squareCropButton.size(42)
                |-15-squareCropButton
                squareCropButton.Bottom == self.Bottom - 15
            }
        }

        // Multiple selection button
        subviews(multipleSelectionButton)
        if #available(iOS 15.0, *) {
            multipleSelectionButton.size(36)
            multipleSelectionButton.trailing(15)
            multipleSelectionButton.Bottom == self.Bottom - 4
        } else {
            multipleSelectionButton.size(42)
            multipleSelectionButton.trailing(15)
            multipleSelectionButton.Bottom == self.Bottom - 15
        }
    }

    required init?(coder: NSCoder) {
        zoomableView = YPAssetZoomableView()
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Square button

    @objc public func squareCropButtonTapped() {
        let z = zoomableView.zoomScale
        shouldCropToSquare = (z >= 1 && z < zoomableView.squaredZoomScale)
        zoomableView.fitImage(shouldCropToSquare, animated: true)
    }

    /// Update only UI of square crop button.
    public func updateSquareCropButtonState() {
        guard !isMultipleSelectionEnabled else {
            // If multiple selection enabled, the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }
        guard !onlySquare else {
            // If only square enabled, than the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }
        guard let selectedAssetImage = zoomableView.assetImageView.image else {
            // If no selected asset, than the squareCropButton is not visible
            squareCropButton.isHidden = true
            return
        }

        let isImageASquare = selectedAssetImage.size.width == selectedAssetImage.size.height
        squareCropButton.isHidden = isImageASquare
    }
    
    // MARK: - Multiple selection

    /// Use this to update the multiple selection mode UI state for the YPAssetViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        let image = on ? YPConfig.icons.multipleSelectionOnIcon : YPConfig.icons.multipleSelectionOffIcon
        if #available(iOS 15.0, *) {
            multipleSelectionButton.isSelected = on
        } else {
            multipleSelectionButton.setImage(image, for: .normal)
        }
        updateSquareCropButtonState()
    }
}

// MARK: - ZoomableViewDelegate
extension YPAssetViewContainer: YPAssetZoomableViewDelegate {
    public func ypAssetZoomableViewDidLayoutSubviews(_ zoomableView: YPAssetZoomableView) {
        let newFrame = zoomableView.assetImageView.convert(zoomableView.assetImageView.bounds, to: self)
        
        if let itemOverlay = itemOverlay {
            // update grid position
            itemOverlay.frame = frame.intersection(newFrame)
            itemOverlay.layoutIfNeeded()
        }
        
        // Update play imageView position - bringing the playImageView from the videoView to assetViewContainer,
        // but the controll for appearing it still in videoView.
        if zoomableView.videoView.playImageView.isDescendant(of: self) == false {
            self.addSubview(zoomableView.videoView.playImageView)
            zoomableView.videoView.playImageView.centerInContainer()
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidZoom() {
        guard let itemOverlay = itemOverlay else {
            return
        }
        if isShown {
            UIView.animate(withDuration: 0.1) {
                itemOverlay.alpha = 1
            }
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidEndZooming() {
        guard let itemOverlay = itemOverlay else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            itemOverlay.alpha = 0
        }
    }
}

// MARK: - Gesture recognizer Delegate
extension YPAssetViewContainer: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !spinnerIsShown && !(touch.view is UIButton)
    }
    
    @objc
    private func handleTouchDown(sender: UILongPressGestureRecognizer) {
        guard let itemOverlay = itemOverlay else {
            return
        }
        switch sender.state {
        case .began:
            if isShown {
                UIView.animate(withDuration: 0.1) {
                    itemOverlay.alpha = 1
                }
            }
        case .ended:
            UIView.animate(withDuration: 0.3) {
                itemOverlay.alpha = 0
            }
        default: ()
        }
    }
}
