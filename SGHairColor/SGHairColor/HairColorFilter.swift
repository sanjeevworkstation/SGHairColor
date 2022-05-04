//
//  HairColorFilter.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 03/05/22.
//

import Foundation
import UIKit
import AVFoundation


class HairColorFilter {
    
    class func applyFilter(photo: AVCapturePhoto, color: UIColor) -> (mainCIImage: CIImage?, hairCIImage: CIImage?, resultCIImage: CIImage?) {
        
        guard let (r,g,b,a) = self.getRGBA(color: color) else { return (nil, nil, nil) }
        
        guard let originalCIImage = self.previewPixelBufferImage(photo: photo) else { return (nil, nil, nil) }
        guard let segmentedCIImage = self.semanticSegmentationMatte(photo: photo) else { return (nil, nil, nil) }
        
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


extension HairColorFilter {
    class func previewPixelBufferImage(photo: AVCapturePhoto) -> CIImage? {
        if let pixelBuffer = photo.previewPixelBuffer {
            if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32, let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: Int32(exifOrientation.rawValue))
                return ciImage
            } else {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                return ciImage
            }
        }
        return nil
    }
    
    class func semanticSegmentationMatte(photo: AVCapturePhoto) -> CIImage? {
        if var matte = photo.semanticSegmentationMatte(for: .hair) {
            if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32, let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
                matte = matte.applyingExifOrientation(exifOrientation)
            }
            return CIImage(cvPixelBuffer: matte.mattingImage)
        }
        return nil
    }
    
    class func getRGBA(color: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var (r,g,b,a): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        return color.getRed(&r, green: &g, blue: &b, alpha: &a) ? (r,g,b,a) : nil
    }
}

extension CIImage {
    var image: UIImage { .init(ciImage: self) }
}
