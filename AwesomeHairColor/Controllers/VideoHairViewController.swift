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

class VideoHairViewController: UIViewController {

    var photoLibraryPicker: PhotoLibraryPicker?
    var videoPlayer: AVPlayer!
    internal lazy var visionModel = FritzVisionHairSegmentationModelFast()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.photoLibraryPicker = PhotoLibraryPicker(presentationController: self, delegate: self)
        self.photoLibraryPicker?.present(from: view)
    }
    

    func predict(with source: FritzVisionImage) -> UIImage? {
        guard let result = try? visionModel.predict(source),
            let mask = result.buildSingleClassMask(forClass: FritzVisionHairClass.hair)
            else { return nil }

        let blended = source.blend(
            withMask: mask,
            blendKernel: .softLight,
            opacity: 0.7
        )

        return blended
    }

}

extension VideoHairViewController: PhotoLibraryPickerDelegate {

    func didSelect(url: URL?) {
        guard let url = url else {
            return
        }

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
        videoPlayer.currentItem!.videoComposition = composition
        let playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
    }
    

}
