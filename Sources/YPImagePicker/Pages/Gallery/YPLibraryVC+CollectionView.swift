//
//  YPLibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC {
    var isLimitExceeded: Bool {
        if let maximumNumberOfSelectionsOfType = YPConfig.library.maximumNumberOfSelectionsOfType, !maximumNumberOfSelectionsOfType.isEmpty {
            for (type, maximumNumberOfSelections) in maximumNumberOfSelectionsOfType {
                let numberOfSelections = selectedItems.count(where: { $0.mediaType == type })
                if numberOfSelections >= maximumNumberOfSelections {
                    return true
                }
            }
        }
        return selectedItems.count >= YPConfig.library.maximumNumberOfSelections
    }

    func setupCollectionView() {
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
        
        // Long press on cell to enable multiple selection
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        v.collectionView.addGestureRecognizer(longPressGR)
    }
    
    /// When tapping on the cell with long press, clear all previously selected cells.
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if isMultipleSelectionEnabled || isProcessing || YPConfig.library.maximumNumberOfSelections <= 1 {
            return
        }
        
        if longPressGR.state == .began {
            let point = longPressGR.location(in: v.collectionView)
            guard let indexPath = v.collectionView.indexPathForItem(at: point) else {
                return
            }
            startMultipleSelection(at: indexPath)
        }
    }
    
    func startMultipleSelection(at indexPath: IndexPath) {
        currentlySelectedIndex = indexPath.row
        toggleMultipleSelection()
        
        // Update preview.
        changeAsset(mediaManager.getAsset(at: indexPath.row))

        // Bring preview down and keep selected cell visible.
        panGestureHelper.resetToOriginalState()
        if !panGestureHelper.isImageShown {
            v.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
    }
    
    // MARK: - Library collection view cell managing
    
    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        if let positionIndex = selectedItems.firstIndex(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		}) {
            selectedItems.remove(at: positionIndex)

            let selectedIndexPaths = selectedItems.map { IndexPath(row: $0.index, section: 0) }

            // Replace the current selected image with the previously selected one
            if let previouslySelectedIndexPath = selectedIndexPaths.last {
                currentlySelectedIndex = previouslySelectedIndexPath.row
                changeAsset(mediaManager.getAsset(at: previouslySelectedIndexPath.row))
            }

            // Refresh the numbers & selection
            UIView.performWithoutAnimation {
                v.collectionView.reloadItems(at: selectedIndexPaths)
            }

            checkLimit()
        }
    }
    
    /// Adds cell to selection
    func addToSelection(at index: Int) {
        var reset: Bool = false
        addToSelection(at: index, reset: &reset)
    }

    func addToSelection(at index: Int, reset: inout Bool) {
        guard let asset = mediaManager.getAsset(at: index) else {
            print("No asset to add to selection.")
            return
        }
        if let delegate, !delegate.libraryViewShouldAdd(asset, at: index, to: selectedItems, reset: &reset) {
            return
        }

        let newSelection = YPLibrarySelection(index: index, assetIdentifier: asset.localIdentifier, mediaType: asset.mediaType, mediaSubtypes: asset.mediaSubtypes)
        if reset {
            selectedItems = [newSelection]
        } else {
            selectedItems.append(newSelection)
        }
        checkLimit()
    }
    
    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selectedItems.contains(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		})
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        v.maxNumberWarningView.isHidden = !isLimitExceeded || isMultipleSelectionEnabled == false
    }
}

extension YPLibraryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult?.count ?? 0
    }
}

extension YPLibraryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell", for: indexPath) as? YPLibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            return cell
        }

        cell.representedAssetIdentifier = asset.localIdentifier
        cell.multipleSelectionIndicator.selectionColor =
            YPConfig.colors.multipleItemsSelectedCircleColor ?? YPConfig.colors.tintColor
        mediaManager.imageManager?.requestImage(for: asset,
                                   targetSize: v.cellSize(),
                                   contentMode: .aspectFill,
                                   options: nil) { image, _ in
                                    // The cell may have been recycled when the time this gets called
                                    // set image only if it's still showing the same asset.
                                    if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                                        cell.imageView.image = image
                                    }
        }
        
        let isVideo = (asset.mediaType == .video)
        cell.durationLabel.isHidden = !isVideo
        cell.durationLabel.text = isVideo ? YPHelper.formattedStrigFrom(asset.duration) : ""
        cell.multipleSelectionIndicator.isHidden = !isMultipleSelectionEnabled
        cell.isSelectedForDisplay = currentlySelectedIndex == indexPath.row

        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == asset.localIdentifier }) {
            let currentSelection = selectedItems[index]
            if currentSelection.index < 0 {
                selectedItems[index] = YPLibrarySelection(index: indexPath.row,
                                                      cropRect: currentSelection.cropRect,
                                                      scrollViewContentOffset: currentSelection.scrollViewContentOffset,
                                                      scrollViewZoomScale: currentSelection.scrollViewZoomScale,
                                                      assetIdentifier: currentSelection.assetIdentifier,
                                                      mediaType: currentSelection.mediaType,
                                                      mediaSubtypes: currentSelection.mediaSubtypes)
            }
            cell.multipleSelectionIndicator.number = index + 1 // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.number = nil
        }

        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let previouslySelectedIndexPath = IndexPath(row: currentlySelectedIndex, section: 0)
        currentlySelectedIndex = indexPath.row

        changeAsset(mediaManager.getAsset(at: indexPath.row))
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
            
        var reset: Bool = false
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelectedIndexPath.row == currentlySelectedIndex
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                }
            } else if isLimitExceeded == false {
                addToSelection(at: indexPath.item, reset: &reset)
            }
        } else {
            selectedItems.removeAll()
            addToSelection(at: indexPath.item, reset: &reset)
        }
        UIView.performWithoutAnimation {
            if reset {
                collectionView.reloadData()
            } else {
                collectionView.reloadItems(at: [indexPath, previouslySelectedIndexPath])
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
}

extension YPLibraryVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margins = YPConfig.library.spacingBetweenItems * CGFloat(YPConfig.library.numberOfItemsInRow - 1)
        let width = (collectionView.frame.width - margins) / CGFloat(YPConfig.library.numberOfItemsInRow)
        return CGSize(width: width, height: width)
    }

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }
}
