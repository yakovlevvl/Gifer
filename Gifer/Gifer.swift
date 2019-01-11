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
        
        case imagesArrayIsEmpty
        
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
            case .imagesArrayIsEmpty :
                return "Images array is empty"
            }
        }
    }
}

public final class Gifer {
    
    private let loopCount: Int
    
    private let startTime: Float!
    
    private let endTime: Float!
    
    private let gifSize: CGSize
    
    private let images: [UIImage]!
    
    private let videoAsset: AVAsset!
    
    private let videoLength: Float!
    
    private let delayTime: Float
    
    private init(videoUrl: URL, frameRate: Int, loopCount: Int, startTime: Float?, endTime: Float?, size: CGSize?) {
        self.loopCount = loopCount
        self.videoAsset = AVAsset(url: videoUrl)
        let videoLength = Float(videoAsset.duration.seconds)
        self.startTime = startTime ?? 0
        self.endTime = endTime ?? videoLength
        self.videoLength = videoLength
        self.delayTime = 1.0/Float(frameRate)
        self.gifSize = size ?? .zero
        self.images = nil
    }
    
    private init(images: [UIImage], frameTime: Float, loopCount: Int, size: CGSize?) {
        self.images = images
        self.loopCount = loopCount
        self.delayTime = frameTime
        self.gifSize = size ?? .zero
        self.videoAsset = nil
        self.videoLength = nil
        self.startTime = nil
        self.endTime = nil
    }
    
    public static func createGifFromVideo(_ videoUrl: URL, frameRate: Int = 10, loopCount: Int = 0, startTime: Float? = nil, endTime: Float? = nil, size: CGSize? = nil, completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        let gifer = Gifer(videoUrl: videoUrl, frameRate: frameRate, loopCount: loopCount, startTime: startTime, endTime: endTime, size: size)
        gifer.createGifFromVideo { gifUrl, error in
            DispatchQueue.main.async {
                completion(gifUrl, error)
            }
        }
    }
    
    public static func createGifFromImages(_ images: [UIImage], frameTime: Float, loopCount: Int = 0, size: CGSize? = nil, completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        let gifer = Gifer(images: images, frameTime: frameTime, loopCount: loopCount, size: size)
        gifer.createGifFromImages { gifUrl, error in
            DispatchQueue.main.async {
                completion(gifUrl, error)
            }
        }
    }
    
    private func createGifFromVideo(completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
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
    
    private func createGifFromImages(completion: @escaping (_ gifUrl: URL?, Error?) -> ()) {
        guard !images.isEmpty else {
            return completion(nil, .imagesArrayIsEmpty)
        }
        
        let fileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gifer.gif")
        
        guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, CGImageDestination.gifType, images.count, nil) else {
            return completion(nil, .destinationFileNotFound)
        }
        
        let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: NSNumber(value: Int32(loopCount))], kCGImagePropertyGIFHasGlobalColorMap: NSValue(nonretainedObject: true)] as CFDictionary
        
        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delayTime]] as CFDictionary
        
        CGImageDestinationSetProperties(destination, fileProperties)
        
        for image in images {
            CGImageDestinationAddImage(destination, image.cgImage!, frameProperties)
        }
        
        CGImageDestinationFinalize(destination) ? completion(fileUrl, nil) : completion(nil, .endAddingFramesFailed)
    }
}
