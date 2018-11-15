//
//  Helper.swift
//  Gifer
//
//  Created by Vladyslav Yakovlev on 11/14/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import AVFoundation
import MobileCoreServices

extension CMTimeScale {
    
    static let video: CMTimeScale = 600
}

extension CGImageDestination {
    
    static let gifType = kUTTypeGIF
}

extension AVAsset {
    
    var videoFrameRate: Float? {
        guard let track = tracks(withMediaType: .video).first else {
            return nil
        }
        return track.nominalFrameRate
    }
    
    var isVideo: Bool {
        return !tracks(withMediaType: .video).isEmpty
    }
}
