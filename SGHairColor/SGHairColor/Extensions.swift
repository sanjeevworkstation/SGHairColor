//
//  Extensions.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 04/05/22.
//

import Foundation
import UIKit
import AVFoundation

extension CIImage {
    var image: UIImage { .init(ciImage: self) }
}

extension UIColor {
    func getRGBA() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var (r,g,b,a): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        return self.getRed(&r, green: &g, blue: &b, alpha: &a) ? (r,g,b,a) : nil
    }
}

extension AVCapturePhoto {
    func hairSemanticSegmentationMatteImage() -> CIImage? {
        if var matte = self.semanticSegmentationMatte(for: .hair) {
            if let orientation = self.metadata[String(kCGImagePropertyOrientation)] as? UInt32, let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
                matte = matte.applyingExifOrientation(exifOrientation)
            }
            return CIImage(cvPixelBuffer: matte.mattingImage)
        }
        return nil
    }
    
    func getPreviewPixelBufferImage() -> CIImage? {
        if let pixelBuffer = self.previewPixelBuffer {
            if let orientation = self.metadata[String(kCGImagePropertyOrientation)] as? UInt32, let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: Int32(exifOrientation.rawValue))
                return ciImage
            } else {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                return ciImage
            }
        }
        return nil
    }
}
