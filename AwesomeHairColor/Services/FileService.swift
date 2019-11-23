//
//  FileService.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/23/19.
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
                let ac = UIAlertController(title: "Error", message: "Failed to save image", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photo library", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        }

        checkAuthorizationAndPerform(saveToPhotoLibrary)
    }

    func exportVideo(_ video: AVVideoComposition, from url: URL) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd-HH-mm-ss"
        let date = dateFormatter.string(from: Date())

        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

        guard let exporter = AVAssetExportSession(asset: AVAsset(url: url.absoluteURL), presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
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
            let title = success ? "Saved!" : "Error"
            let message = success ? "Your video has been saved to your photo library" : "Failed to save video"

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

final class FileService {
    static func getFileUrl() -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd-HH-mm-ss"
        let date = dateFormatter.string(from: Date())

        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        checkForAndDeleteFile(at: url)
        return url
    }

    static func checkForAndDeleteFile(at url: URL) {
        let fm = FileManager.default
        let exist = fm.fileExists(atPath: url.path)

        if exist {
            do {
                try fm.removeItem(at: url as URL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
}
