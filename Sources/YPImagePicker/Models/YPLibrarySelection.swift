//
//  YPLibrarySelection.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 18/04/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation
import Photos

public struct YPLibrarySelection {
    public let index: Int
    public var cropRect: CGRect?
    var scrollViewContentOffset: CGPoint?
    var scrollViewZoomScale: CGFloat?
    public let assetIdentifier: String
    public let mediaType: PHAssetMediaType
    public let mediaSubtypes: PHAssetMediaSubtype

    init(index: Int,
         cropRect: CGRect? = nil,
         scrollViewContentOffset: CGPoint? = nil,
         scrollViewZoomScale: CGFloat? = nil,
         assetIdentifier: String,
         mediaType: PHAssetMediaType,
         mediaSubtypes: PHAssetMediaSubtype) {
        self.index = index
        self.cropRect = cropRect
        self.scrollViewContentOffset = scrollViewContentOffset
        self.scrollViewZoomScale = scrollViewZoomScale
        self.assetIdentifier = assetIdentifier
        self.mediaType = mediaType
        self.mediaSubtypes = mediaSubtypes
    }
}
