//
//  VideoHairViewController.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/10/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Fritz
import Photos

class VideoHairViewController: UIViewController, HairColorPredictor {
    var color: HairColor!
    
    var photoLibraryPicker: PhotoLibraryPicker?
    var colorPicker: ColorPicker?
    var effectPicker: EffectPicker?

    var videoPlayer: AVPlayer?
    var imageView: UIImageView?

    var sourceUrl: URL!
    var predictedImage: UIImage?
    var predictedVideo: AVVideoComposition?

    internal lazy var visionModel = FritzVisionHairSegmentationModelFast()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "LET'S COLOR!"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: #selector(savePredictedAsset))
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        color = HairColor(hairColor: UIColor.clear, colorEffect: .softLight)
        colorPicker = ColorPickerViewPresenter()
        colorPicker?.pickerPresenterDelegate = self
        self.maskColor = .clear

        effectPicker = EffectPickerViewPresenter()
        effectPicker?.effectPickerPresenterDelegate = self
        didSelectEffect(.light)

        self.photoLibraryPicker = PhotoLibraryPicker(presentationController: self, delegate: self)
        self.photoLibraryPicker?.present(from: view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let imageView = imageView {
            view.sendSubviewToBack(imageView)
        }
        guard let effectPickerView = effectPicker?.effectPickerView else { return }
        view.bringSubviewToFront(effectPickerView)
    }

//MARK: HairColoring methods
    internal func startPhotoPrediction(for url: URL) {
        var image: UIImage?
        if let imageData = try? Data(contentsOf: url) {
            image = UIImage(data: imageData)
        }

        guard let source = image else {
            return
        }

        let fritzImage = FritzVisionImage(image: source)
        if self.maskColor == UIColor.clear {
            showPredictedPhoto(source)
        } else if let maskedImage = self.predict(with: fritzImage) {
            showPredictedPhoto(maskedImage)
        } else {
            showPredictedPhoto(source)
        }
    }

    internal func showPredictedPhoto(_ image: UIImage) {
        if let ciImage = image.ciImage {
            let newImage = image.convert(ciImage: ciImage)
            let rotatedImage = UIImage(cgImage: newImage.cgImage!, scale: 1.0, orientation: UIImage.Orientation.right)
            imageView?.image = rotatedImage
            self.predictedImage = rotatedImage
        } else {
            imageView?.image = image
        }
        imageView?.contentMode = .scaleAspectFit
    }

    internal func startVideoPrediction(for url: URL) {
        // Run prediction on every frame of the video or photo
        let composition = AVVideoComposition(asset: AVAsset(url: url)) { request in
            let source = request.sourceImage
            let fritzImage = FritzVisionImage(image: UIImage(ciImage: source))
            if self.maskColor != .clear,
                let maskedImage = self.predict(with: fritzImage) {
                    request.finish(with: maskedImage.ciImage!, context: nil)
                } else {
                    request.finish(with: source, context: nil)
                }
        }

        let videoURL = URL(string: url.absoluteString)
        videoPlayer = AVPlayer(url: videoURL!)
        videoPlayer?.currentItem?.videoComposition = composition
        let playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        self.predictedVideo = composition

        NotificationCenter.default.addObserver(self, selector: #selector(endedVideoPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)
        startPlaying()
    }
}

//MARK: PhotoLibraryPickerDelegate
extension VideoHairViewController: PhotoLibraryPickerDelegate {

    func didSelect(url: URL?) {
        guard let url = url else {
            return
        }

        self.sourceUrl = url

        if url.isImage {
            imageView = UIImageView(frame: view.frame)
            view.addSubview(imageView!)
            imageView?.contentMode = .scaleAspectFit
            startPhotoPrediction(for: url)
            effectPicker?.addEffectPicker(to: view)
            colorPicker?.addColorPicker(to: self.view)
        } else if url.isMovie {
            startVideoPrediction(for: url)
        } else {
            fatalError("Error file extension")
        }
    }
}

//MARK: ColorPickerDelegate
extension VideoHairViewController: ColorPickerDelegate {
    func didSelectColor(_ color: UIColor) {
        self.maskColor = color
        if sourceUrl.isImage {
            startPhotoPrediction(for: sourceUrl)
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
}

//MARK: EffectPickerDelegate
extension VideoHairViewController: EffectPickerDelegate {
    func didSelectEffect(_ effect: Effect) {
        switch effect {
            case .dark: self.blendKernel = .hue
            case .light: self.blendKernel = .softLight
        }
        if sourceUrl != nil, sourceUrl.isImage {
            startPhotoPrediction(for: sourceUrl)
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
}

//MARK: Video playing rutines
extension VideoHairViewController {

    func startPlaying() {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.play()
        colorPicker?.addColorPicker(to: self.view)
        effectPicker?.addEffectPicker(to: view)
    }

    @objc func endedVideoPlaying(_ notification: Notification) {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.pause()
        videoPlayer.seek(to: CMTime.zero)
        videoPlayer.play()
    }
}

//MARK: Saving assets
extension VideoHairViewController {
    @objc func savePredictedAsset() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        if let predictedImage = predictedImage {
            self.savePhoto(predictedImage)
            //UIImageWriteToSavedPhotosAlbum(predictedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else if predictedVideo != nil {
            self.exportVideo(predictedVideo!, from: sourceUrl.absoluteURL)
            //exportVideo()
        }
    }
}
