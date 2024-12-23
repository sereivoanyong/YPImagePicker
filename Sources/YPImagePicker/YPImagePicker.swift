//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public protocol YPImagePickerDelegate: AnyObject {

    func imagePickerHasNoItemsInLibrary(_ picker: YPImagePicker)
    func imagePickerShouldAdd(_ asset: PHAsset, at index: Int, to selections: [YPLibrarySelection], reset: inout Bool) -> Bool
}

open class YPImagePicker: UINavigationController {

    // MARK: - Public

    public let configuration: YPImagePickerConfiguration

    @available(iOS 15.0, *)
    open var pickerTitle: String? {
        get { return picker.title }
        set { picker.title = newValue }
    }

    weak open var imagePickerDelegate: YPImagePickerDelegate?

    open var finishPickingHandler: (([YPMediaItem]) -> Void)?

    open var cancelHandler: (() -> Void)?

    /// Get a YPImagePicker with the specified configuration.
    public init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        YPImagePickerConfiguration.shared = configuration
        picker = YPPickerVC()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen // Force .fullScreen as iOS 13 now shows modals as cards by default.
        picker.pickerVCDelegate = self
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        ypLog("Picker deinited 👍")
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return configuration.preferredStatusBarStyle
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Private

    // This nifty little trick enables us to call the single version of the callbacks.
    // This keeps the backwards compatibility keeps the api as simple as possible.
    // Multiple selection becomes available as an opt-in.
    private func didSelect(items: [YPMediaItem]) {
        finishPickingHandler?(items)
    }
    
    private let loadingView = YPLoadingView()
    private let picker: YPPickerVC!

    override open func viewDidLoad() {
        super.viewDidLoad()
        picker.didClose = cancelHandler
        viewControllers = [picker]
        setupLoadingView()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = configuration.colors.defaultNavigationBarColor
        navigationBar.titleTextAttributes = [.font: configuration.fonts.navigationBarTitleFont, .foregroundColor: configuration.colors.albumTitleColor]
        view.backgroundColor = .ypSystemBackground

        picker.didSelectItems = { [weak self] items in
            guard let self else { return }

            // Use Fade transition instead of default push animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.fade
            view.layer.add(transition, forKey: nil)
            
            // Multiple items flow
            if items.count > 1 {
                if configuration.library.skipSelectionsGallery {
                    didSelect(items: items)
                    return
                } else {
                    let selectionsGalleryVC = YPSelectionsGalleryVC(items: items) { [weak self] _, items in
                        guard let self else { return }

                        didSelect(items: items)
                    }
                    pushViewController(selectionsGalleryVC, animated: true)
                    return
                }
            }
            
            // One item flow
            let item = items.first!
            switch item {
            case .photo(let photo):
                let completion = { [weak self] photo in
                    guard let self else { return }

                    let mediaItem = YPMediaItem.photo(p: photo)
                    // Save new image or existing but modified, to the photo album.
                    if configuration.shouldSaveNewPicturesToAlbum {
                        let isModified = photo.modifiedImage != nil
                        if photo.fromCamera || (!photo.fromCamera && isModified) {
                            YPPhotoSaver.trySaveImage(photo.image, inAlbumNamed: configuration.albumName)
                        }
                    }
                    didSelect(items: [mediaItem])
                }
                
                func showCropVC(photo: YPMediaPhoto, completion: @escaping (_ aphoto: YPMediaPhoto) -> Void) {
                    switch configuration.showsCrop {
                    case .rectangle, .circle:
                        let cropVC = YPCropVC(image: photo.image)
                        cropVC.didFinishCropping = { croppedImage in
                            photo.modifiedImage = croppedImage
                            completion(photo)
                        }
                        pushViewController(cropVC, animated: true)
                    default:
                        completion(photo)
                    }
                }
                
                if configuration.showsPhotoFilters {
                    let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                                                    isFromSelectionVC: false)
                    // Show filters and then crop
                    filterVC.didSave = { outputMedia in
                        if case let YPMediaItem.photo(outputPhoto) = outputMedia {
                            showCropVC(photo: outputPhoto, completion: completion)
                        }
                    }
                    pushViewController(filterVC, animated: false)
                } else {
                    showCropVC(photo: photo, completion: completion)
                }
            case .video(let video):
                if configuration.showsVideoTrimmer {
                    let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                                                                   isFromSelectionVC: false)
                    videoFiltersVC.didSave = { [weak self] outputMedia in
                        self?.didSelect(items: [outputMedia])
                    }
                    pushViewController(videoFiltersVC, animated: true)
                } else {
                    didSelect(items: [YPMediaItem.video(v: video)])
                }
            }
        }
    }
    
    private func setupLoadingView() {
        view.subviews(
            loadingView
        )
        loadingView.fillContainer()
        loadingView.alpha = 0
    }
}

extension YPImagePicker: YPPickerVCDelegate {
    func libraryHasNoItems() {
        self.imagePickerDelegate?.imagePickerHasNoItemsInLibrary(self)
    }
    
    func libraryShouldAdd(_ asset: PHAsset, at index: Int, to selections: [YPLibrarySelection], reset: inout Bool) -> Bool {
        return imagePickerDelegate?.imagePickerShouldAdd(asset, at: index, to: selections, reset: &reset)
            ?? true
    }
}
