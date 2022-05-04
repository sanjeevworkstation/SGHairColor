//
//  HairCameraViewController.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 03/05/22.
//

import UIKit
import AVFoundation

protocol HairCameraViewControllerDelegate: AnyObject {
    func photoCaptured(photo: AVCapturePhoto)
}

class HairCameraViewController: UIViewController {

    weak var delegate: HairCameraViewControllerDelegate?
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private lazy var photoSettings = AVCapturePhotoSettings()
    private lazy var photoOutput = AVCapturePhotoOutput()
    
    private var capturePhotoButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        HairHelper.isVerifyAndAuthorisedCamera { [weak self] (result) in
            if result {
                DispatchQueue.main.async {
                    self?.setUpInitial()
                }
            }
        }
    }
    
    private func setUpInitial() {
        guard let videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard self.captureSession.canAddInput(videoDeviceInput) else { return }
        self.captureSession.addInput(videoDeviceInput)
        
        self.captureSession.sessionPreset = .photo
        self.captureSession.beginConfiguration()
        
        guard self.captureSession.canAddOutput(photoOutput) else { return }
        self.captureSession.addOutput(photoOutput)
        
        self.photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
        self.photoOutput.isDepthDataDeliveryEnabled = true
        self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
        self.photoOutput.isHighResolutionCaptureEnabled = true
        
        if  photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            self.photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        if videoDeviceInput.device.isFlashAvailable {
            self.photoSettings.flashMode = .auto
        }
        self.photoSettings.isHighResolutionPhotoEnabled = true
        if let previewPhotoPixelFormatType = self.photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            self.photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        self.photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
        self.photoSettings.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        if self.photoSettings.isDepthDataDeliveryEnabled {
            if !photoOutput.availableSemanticSegmentationMatteTypes.isEmpty {
                self.photoSettings.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            }
        }
        
        self.captureSession.commitConfiguration()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = self.view.layer.frame
        
        self.captureSession.startRunning()
        
        // Add Capture Button
        self.capturePhotoButton = UIButton(type: .custom)
        if let btn = self.capturePhotoButton {
            btn.setTitle("Capture", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            self.view.addSubview(btn)
            
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 80).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
            btn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            btn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50).isActive = true
            
            btn.backgroundColor = .red
            btn.addTarget(self, action: #selector(capturePhotoAction(_:)), for: .touchUpInside)
        }
    }

    @IBAction func capturePhotoAction(_ sender: UIButton) {
        self.sessionQueue.async {
            self.photoOutput.capturePhoto(with: self.photoSettings, delegate: self)
        }
    }
}


extension HairCameraViewController : AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.photoCaptured(photo: photo)
            self.navigationController?.popViewController(animated: true)
        }
    }
}
