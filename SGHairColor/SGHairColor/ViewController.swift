//
//  ViewController.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 03/05/22.
//

import UIKit
import AVFoundation

// MARK: - Colors
private enum Colors: Int {
    case red = 101
    case green = 102
    case yellow = 103
    case black = 104
    case orange = 105
    
    func getColor() -> UIColor {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .black:
            return .black
        case .orange:
            return .cyan
        }
    }
}

// MARK: -
class ViewController: UIViewController {

    @IBOutlet weak var imageViewResult: UIImageView!
    @IBOutlet weak var imageViewOriginal: UIImageView!
    @IBOutlet weak var imageViewSegmented: UIImageView!
    
    private var capturedPhoto: AVCapturePhoto?
    private var selectedColor: Colors = .red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add right navigation bar button to open camera view controller
        let button1 = UIBarButtonItem(title: "Take Selfie", style: .plain, target: self, action: #selector(takeSelfieAction))
        self.navigationItem.rightBarButtonItem  = button1
    }

    // target action to navigate to camera view controller
    @objc func takeSelfieAction() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HairCameraViewController") as? HairCameraViewController {
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // action to select color and apply on clicked selfie image
    @IBAction func colorButtonAction(_ sender: UIButton) {
        if let colorType = Colors(rawValue: sender.tag) {
            self.selectedColor = colorType
            self.applyFilterColor()
        }
    }
}

// MARK: - Delegate to receive click selfie
extension ViewController: HairCameraViewControllerDelegate {
    func photoCaptured(photo: AVCapturePhoto) {
        // save clicked selfie
        self.capturedPhoto = photo
        // apply filter on clicked selfie
        self.applyFilterColor()
    }
}

// MARK:- Apply Filter on Clicked Selfie
extension ViewController {
    private func applyFilterColor() {
        guard let photo = capturedPhoto else {
            return
        }
        
        let object = ViewController.processCapturedPhoto(photo: photo, color: self.selectedColor.getColor())
        // display filtered image
        self.imageViewResult.image = object.resultCIImage?.image
        // display original image
        self.imageViewOriginal.image = object.originalCIImage?.image
        // display hair segmented image
        self.imageViewSegmented.image = object.segmentedCIImage?.image
    }
}

// MARK: - Process Captured Photo
extension ViewController {
    class func processCapturedPhoto(photo: AVCapturePhoto, color: UIColor) -> (originalCIImage: CIImage?, segmentedCIImage: CIImage?, resultCIImage: CIImage?) {
        
        guard let (r,g,b,a) = color.getRGBA() else { return (nil, nil, nil) }
        
        guard let originalCIImage = photo.getPreviewPixelBufferImage() else { return (nil, nil, nil) }
        guard let segmentedCIImage = photo.hairSemanticSegmentationMatteImage() else { return (nil, nil, nil) }
        
        var params = [String:Any]()
        params[kCIInputImageKey] = originalCIImage
        params["inputRVector"] = CIVector(x: r, y: 0, z: 0, w: 0)
        params["inputGVector"] = CIVector(x: 0, y: g, z: 0, w: 0)
        params["inputBVector"] = CIVector(x: 0, y: 0, z: b, w: 0)
        params["inputAVector"] = CIVector(x: 0, y: 0, z: 0, w: a)
        let gamma = CIFilter(name: "CIColorMatrix", parameters: params)
        let makeup = gamma?.outputImage
        
        let base = originalCIImage
        var matte = segmentedCIImage
        let scale = CGAffineTransform(scaleX: base.extent.size.width / matte.extent.size.width, y: base.extent.size.height / matte.extent.size.height)
        matte = matte.transformed( by: scale)

        var blendParams = [String:Any]()
        blendParams[kCIInputImageKey] = makeup
        blendParams["inputBackgroundImage"] = base
        blendParams["inputMaskImage"] = matte
        let blend = CIFilter(name: "CIBlendWithMask", parameters: blendParams)
        return (originalCIImage, segmentedCIImage, blend?.outputImage)
    }
}
