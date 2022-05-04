//
//  ViewController.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 03/05/22.
//

import UIKit
import AVFoundation

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

class ViewController: UIViewController {

    @IBOutlet weak var imageViewResult: UIImageView!
    @IBOutlet weak var imageViewOriginal: UIImageView!
    @IBOutlet weak var imageViewSegmented: UIImageView!
    
    private var capturedPhoto: AVCapturePhoto?
    private var selectedColor: Colors = .red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIBarButtonItem(title: "Take Selfie", style: .plain, target: self, action: #selector(takeSelfieAction))
        self.navigationItem.rightBarButtonItem  = button1
    }

    @objc func takeSelfieAction() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HairCameraViewController") as? HairCameraViewController {
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func colorButtonAction(_ sender: UIButton) {
        if let colorType = Colors(rawValue: sender.tag) {
            self.selectedColor = colorType
            self.applyFilterColor()
        }
    }
}

extension ViewController: HairCameraViewControllerDelegate {
    func photoCaptured(photo: AVCapturePhoto) {
        self.capturedPhoto = photo
        self.applyFilterColor()
    }
}

extension ViewController {
    private func applyFilterColor() {
        guard let photo = capturedPhoto else {
            return
        }
        
        let object = HairColorFilter.applyFilter(photo: photo, color: self.selectedColor.getColor())
        self.imageViewResult.image = object.resultCIImage?.image
        self.imageViewOriginal.image = object.mainCIImage?.image
        self.imageViewSegmented.image = object.hairCIImage?.image
    }
}
