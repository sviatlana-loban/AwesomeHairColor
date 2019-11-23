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

        color = HairColor(hairColor: UIColor.clear)
        colorPicker = ColorPickerViewPresenter()
        colorPicker?.pickerPresenterDelegate = self
        self.maskColor = .clear

        self.photoLibraryPicker = PhotoLibraryPicker(presentationController: self, delegate: self)
        self.photoLibraryPicker?.present(from: view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            colorPicker?.addColorPicker(to: self.view)
            imageView = UIImageView(frame: view.frame)
            view.addSubview(imageView!)
            startPhotoPrediction(for: url)
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

//MARK: Video playing rutines
extension VideoHairViewController {

    func startPlaying() {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.play()
        colorPicker?.addColorPicker(to: self.view)
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
            UIImageWriteToSavedPhotosAlbum(predictedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else if predictedVideo != nil {
            exportVideo()
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            let ac = UIAlertController(title: "Error", message: "Failed to save image", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photo library", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    func exportVideo() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd-HH-mm-ss"
        let date = dateFormatter.string(from: Date())

        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

        guard let exporter = AVAssetExportSession(asset: AVAsset(url: sourceUrl.absoluteURL), presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.videoComposition = predictedVideo
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true

        exporter.exportAsynchronously() { () -> Void in
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
    }

    func exportDidFinish(_ session: AVAssetExportSession) {

      guard
        session.status == AVAssetExportSession.Status.completed,
        let outputURL = session.outputURL
        else {
          return
      }

        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }) { saved, error in
                let success = saved && (error == nil)
                self.navigationItem.rightBarButtonItem?.isEnabled = !success
                let title = success ? "Saved!" : "Error"
                let message = success ? "Your video has been saved to your photo library" : "Failed to save video"

                DispatchQueue.main.async {
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }

        // Ensure permission to access Photo Library
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            }
        } else {
            saveVideoToPhotos()
        }
    }
}
