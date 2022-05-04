//
//  HairHelper.swift
//  SGHairColor
//
//  Created by Sanjeev Gautam on 03/05/22.
//

import Foundation
import AVFoundation
import UIKit

class CameraHelper {
    class func isVerifyAndAuthorisedCamera(completionHandler: @escaping (Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                completionHandler(true)
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    completionHandler(granted)
                }
            
            case .denied: // The user has previously denied access.
                completionHandler(false)

            case .restricted: // The user can't grant access due to restrictions.
                completionHandler(false)
        }
    }
}
