//
//  LiveViewController.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/19/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import UIKit
import AVFoundation
import Fritz
import CoreImage
import Photos

class LiveViewController: UIViewController, HairColorPredictor {
    var color: HairColor!
    var colorPicker: ColorPicker?
    var effectPicker: EffectPicker?

    var cameraButton: UIView!
    var timerLabel: UILabel!
    var timer: Timer?
    let timerProvider = TimerProvider()


    var cameraView: UIImageView!
    internal lazy var visionModel = FritzVisionHairSegmentationModelFast()

    private lazy var cameraSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.sloban.awesomeHairColor.session")
    private let captureQueue = DispatchQueue(label: "com.sloban.awesomeHairColor.capture", qos: DispatchQoS.userInitiated)

    var assetWriter: AVAssetWriter?
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var isWriting = false
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    let context = CIContext()
    var movieURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        color = HairColor(hairColor: UIColor.clear, colorEffect: .softLight)
        colorPicker = ColorPickerViewPresenter()
        colorPicker?.pickerPresenterDelegate = self
        effectPicker = EffectPickerViewPresenter()
        effectPicker?.effectPickerPresenterDelegate = self
        didSelectEffect(.light)


        cameraView = UIImageView(frame: view.bounds)
        cameraView.contentMode = .scaleAspectFill
        view.addSubview(cameraView)
        setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        sessionQueue.async {
            self.cameraSession.startRunning()
        }
        configureCameraButton()
        self.maskColor = .clear
        effectPicker?.addEffectPicker(to: view)
        colorPicker?.addColorPicker(to: self.view)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard let effectPickerView = effectPicker?.effectPickerView else { return }
        view.bringSubviewToFront(effectPickerView)
    }

    func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
            else { return }

        let output = AVCaptureVideoDataOutput()

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA as UInt32]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: captureQueue)

        sessionQueue.async {
            self.cameraSession.beginConfiguration()
            self.cameraSession.addInput(input)
            self.cameraSession.addOutput(output) // output to screen
            self.cameraSession.commitConfiguration()
            self.cameraSession.sessionPreset = .photo

            // Front camera images are mirrored.
            output.connection(with: .video)?.isVideoMirrored = true
        }
    }

    internal func configureCameraButton() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        let width = screenWidth / 5.0
        let x = (screenWidth - width) / 2.0

        let y = (screenHeight - screenHeight / 14.0)

        cameraButton = UIView(frame: CGRect(x: x, y: y - width - 36.0, width: width, height: width))
        cameraButton.layer.cornerRadius = width/2
        cameraButton.layer.borderWidth = width/10.0
        cameraButton.layer.borderColor = UIColor.white.cgColor

        cameraButton.layer.shadowRadius = 10.0
        cameraButton.layer.shadowColor = UIColor.black.cgColor
        cameraButton.layer.shadowOpacity = 0.4

        cameraButton.isUserInteractionEnabled = true
        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(record(_:)))
        cameraButton.addGestureRecognizer(cameraButtonRecognizer)
        cameraButton.backgroundColor = UIColor.red

        timerLabel = UILabel(frame: CGRect(x: x + width + 10, y: y - width - 36.0, width: 60, height: width))
        self.view.addSubview(timerLabel)
        self.view.addSubview(cameraButton)
        self.view.bringSubviewToFront(cameraButton)
    }
}

//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension LiveViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let image = FritzVisionImage(sampleBuffer: sampleBuffer, connection: connection)
        let blended = self.predict(with: image)

        DispatchQueue.main.async {
            self.cameraView.image = blended
        }

        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)

        if self.isWriting {
            var newPixelBuffer: CVPixelBuffer? = nil
            CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)

            guard let outputImage = blended?.ciImage?.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.right.rawValue)) else { return }
            self.context.render(outputImage, to: newPixelBuffer!)

            if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: currentSampleTime!)

                if success == false {
                    print("Pixel Buffer failed")
                }
            }
        }


    }


    @objc func record(_ sender: Any) {
        if isWriting {
            print("stop record")
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            assetWriter?.finishWriting(completionHandler: {[unowned self] () -> Void in
                if let movieURL = self.movieURL {
                    self.saveVideo(at: movieURL)
                }
            })

            timerProvider.stop()
            timer?.invalidate()
            timerLabel?.isHidden = true
            timerLabel.text = ""
        } else {
            print("start record")
            createWriter()
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: currentSampleTime!)
            isWriting = true

            timerProvider.start()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                self.timerLabel?.text = self.timerProvider.getTimerString()
            })
            timerLabel?.isHidden = false
        }
    }

    func createWriter() {
        self.movieURL = FileService.getFileUrl()
        do {
            if let movieURL = self.movieURL {
                assetWriter = try AVAssetWriter(outputURL: movieURL, fileType: AVFileType.mov)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }

        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
        ] as [String : Any]

        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(3.0 * .pi / 2.0))

        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ] as [String : Any]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)

        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
        } else {
            print("no way\(assetWriterVideoInput)")
        }
    }
}

//MARK: ColorPickerDelegate
extension LiveViewController: ColorPickerDelegate {
    func didSelectColor(_ color: UIColor) {
        self.maskColor = color
    }
}

//MARK: EffectPickerDelegate
extension LiveViewController: EffectPickerDelegate {
    func didSelectEffect(_ effect: Effect) {
        switch effect {
            case .dark: self.blendKernel = .hue
            case .light: self.blendKernel = .softLight
        }
    }
}
