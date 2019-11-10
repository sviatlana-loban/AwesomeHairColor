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

class VideoHairViewController: UIViewController, HairColorPredictor {

    var color: HairColor!

    var photoLibraryPicker: PhotoLibraryPicker?
    var videoPlayer: AVPlayer?
    internal lazy var visionModel = FritzVisionHairSegmentationModelFast()

    override func viewDidLoad() {
        super.viewDidLoad()
        color = HairColor(hairColor: UIColor.red)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.photoLibraryPicker = PhotoLibraryPicker(presentationController: self, delegate: self)
        self.photoLibraryPicker?.present(from: view)
    }
}

extension VideoHairViewController: PhotoLibraryPickerDelegate {

    func didSelect(url: URL?) {
        guard let url = url else {
            return
        }

        if url.isImage {
            startPhotoPrediction(for: url)
        } else if url.isMovie {
            startVideoPrediction(for: url)
        } else {
            fatalError("Error file extension")
        }
    }

    internal func startPhotoPrediction(for url: URL) {
        var image: UIImage?
        if let imageData = try? Data(contentsOf: url) {
            image = UIImage(data: imageData)
        }

        guard let source = image else {
            return
        }

        let fritzImage = FritzVisionImage(image: source)
        if let maskedImage = self.predict(with: fritzImage) {
            showImage(maskedImage)
        } else {
            showImage(source)
        }
    }

    internal func showImage(_ image: UIImage) {
        let imageView = UIImageView(frame: view.frame)
        let newImage = image.convert(ciImage: image.ciImage!)
        imageView.image = UIImage(cgImage: newImage.cgImage!, scale: 1.0, orientation: UIImage.Orientation.right)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }

    internal func startVideoPrediction(for url: URL) {
        // Run prediction on every frame of the video or photo
        let composition = AVVideoComposition(asset: AVAsset(url: url)) { request in
            let source = request.sourceImage
            let fritzImage = FritzVisionImage(image: UIImage(ciImage: source))

            if let maskedImage = self.predict(with: fritzImage) {
                request.finish(with: maskedImage.ciImage!, context: nil)
            }
            else {
                request.finish(with: source, context: nil)
            }
        }

        let videoURL = URL(string: url.absoluteString)
        videoPlayer = AVPlayer(url: videoURL!)
        videoPlayer?.currentItem?.videoComposition = composition
        let playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)

        NotificationCenter.default.addObserver(self, selector: #selector(endedVideoPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)
        startPlaying()
    }
}

extension VideoHairViewController {

    func startPlaying() {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.play()
    }

    @objc func endedVideoPlaying(_ notification: Notification) {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.pause()
        videoPlayer.seek(to: CMTime.zero)
        videoPlayer.play()
    }
}



extension UIImage {

    func convert(ciImage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
