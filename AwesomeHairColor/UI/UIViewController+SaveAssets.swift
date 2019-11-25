//
//  UIViewController+SaveAssets.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/24/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import Photos
import UIKit

//MARK: Saving assets
extension UIViewController {

    func savePhoto(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {

        let saveToPhotoLibrary = { [unowned self] in
            if error != nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Error".localized(), message: "Failed to save image".localized(), preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }

            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Saved!".localized(), message: "Your image has been saved to your photo library".localized(), preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)                }
            }
        }

        checkAuthorizationAndPerform(saveToPhotoLibrary)
    }

    func exportVideo(_ video: AVVideoComposition, from url: URL) {
        guard let outputUrl = FileService.getFileUrl() else { return }

        guard let exporter = AVAssetExportSession(asset: AVAsset(url: url.absoluteURL), presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = outputUrl
        exporter.videoComposition = video
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

        let saveVideoToPhotos = { [unowned self] in
            self.saveVideo(at: outputURL)
        }

        checkAuthorizationAndPerform(saveVideoToPhotos)
    }

    func saveVideo(at url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            let success = saved && (error == nil)
            self.navigationItem.rightBarButtonItem?.isEnabled = !success
            let title = success ? "Saved!".localized() : "Error".localized()
            let message = success ? "Your video has been saved to your photo library".localized() : "Failed to save video".localized()

            DispatchQueue.main.async {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func checkAuthorizationAndPerform(_ saveAction: (()-> Void)?) {
        // Ensure permission to access Photo Library
        guard let saveAction = saveAction else { return }
        DispatchQueue.main.async {
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        saveAction()
                    }
                }
            } else {
                saveAction()
            }
        }

    }
}
