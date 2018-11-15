//
//  Gifer.swift
//  Gifer
//
//  Created by Vladyslav Yakovlev on 11/13/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import AVFoundation

extension Gifer {
    
    public enum Error: LocalizedError {
        
        case videoUrlInvalid
        
        case inputParametersInvalid
        
        case destinationFileNotFound
        
        case generateFrameFailed
        
        case endAddingFramesFailed
        
        public var errorDescription: String? {
            switch self {
            case .videoUrlInvalid :
                return "The source file does not appear to be a video"
            case .inputParametersInvalid :
                return "Invalid input parameters"
            case .destinationFileNotFound :
                return "The temporary file destination for gif could not be created or found"
            case .generateFrameFailed :
                return "Failed to generate frame"
            case .endAddingFramesFailed :
                return "Failed to end adding frames"
            }
        }
    }
}

public final class Gifer {
    
    private let videoUrl: URL
    
    private let frameRate: Int
    
    private let loopCount: Int
    
    private let startTime: Float
    
    private let endTime: Float
    
    private let gifSize: CGSize
    
    private let videoAsset: AVAsset
    
    private let videoLength: Float
    
    private let delayTime: Float
    
    private init(videoUrl: URL, frameRate: Int, loopCount: Int, startTime: Float?, endTime: Float?, size: CGSize?) {
        self.videoUrl = videoUrl
        self.frameRate = frameRate
        self.loopCount = loopCount
        self.videoAsset = AVAsset(url: videoUrl)
        let videoLength = Float(videoAsset.duration.seconds)
        self.startTime = startTime ?? 0
        self.endTime = endTime ?? videoLength
        self.videoLength = videoLength
        self.delayTime = 1.0/Float(frameRate)
        self.gifSize = size ?? .zero
    }
    
    public static func createGifFromVideo(_ videoUrl: URL, frameRate: Int = 10, loopCount: Int = 0, startTime: Float? = nil, endTime: Float? = nil, size: CGSize? = nil, completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        let gifer = Gifer(videoUrl: videoUrl, frameRate: frameRate, loopCount: loopCount, startTime: startTime, endTime: endTime, size: size)
        gifer.createGif { gifUrl, error in
            DispatchQueue.main.async {
                completion(gifUrl, error)
            }
        }
    }
    
    private func createGif(completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        if startTime < 0 || endTime > videoLength || startTime >= endTime {
            return completion(nil, .inputParametersInvalid)
        }
        
        let timePoints = createTimePoints()
        
        createGifForTimePoints(timePoints) { gifUrl, error in
            completion(gifUrl, error)
        }
    }
    
    private func createTimePoints() -> [CMTime] {
        let timePoints = stride(from: startTime, through: endTime, by: delayTime).map {
            CMTime(seconds: Double($0), preferredTimescale: CMTimeScale.video)
        }
        return timePoints
    }
    
    private func createGifForTimePoints(_ timePoints: [CMTime], completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        guard videoAsset.isVideo else {
            return completion(nil, .videoUrlInvalid)
        }
        
        let fileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gifer.gif")
        
        guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, CGImageDestination.gifType, timePoints.count, nil) else {
            return completion(nil, .destinationFileNotFound)
        }
        
        let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: NSNumber(value: Int32(loopCount))],
            kCGImagePropertyGIFHasGlobalColorMap: NSValue(nonretainedObject: true)] as CFDictionary
        
        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delayTime]] as CFDictionary
        
        CGImageDestinationSetProperties(destination, fileProperties)
        
        let generator = AVAssetImageGenerator(asset: videoAsset)
        
        let tolerance = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale.video)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance
        
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = gifSize
        
        let times = timePoints.map {
            NSValue(time: $0)
        }
        
        generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
            guard let image = image, error == nil else {
                if result != .cancelled {
                    generator.cancelAllCGImageGeneration()
                    completion(nil, .generateFrameFailed)
                }
                return
            }
            
            CGImageDestinationAddImage(destination, image, frameProperties)
            
            if requestedTime == times.last?.timeValue {
                CGImageDestinationFinalize(destination) ? completion(fileUrl, nil) : completion(nil, .endAddingFramesFailed)
            }
        }
    }
}
