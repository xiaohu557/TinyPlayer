//
//  TinyVideoPlayer+ImageCapture.swift
//  Pods
//
//  Created by Kevin Chen on 28/03/2017.
//
//

import Foundation
import AVFoundation

extension TinyVideoPlayer {
    
    /**
     Capture a set of still images from the current media asset in its original resolution by giving a set of
     timepoints. The image capture only takes place in the valid time span. If the one of specified timepoints is
     out of bounds, TinyVideoPlayer will try to performe the action at the closest position. If the video duration
     is not known yet, TinyVideoPlayer will instead try to capture the very first frame of the video.
     
     - Parameter timepoints: A set of timepoint within the valid playable timespan at which TinyVideoPlayer will
        capture a still image from the video sequence. If you let it empty, then the currentPlayback time will 
        be used.
     - Parameter completion: A closure that will be called after the image capture is done. The final result
        will be passed in as a closure parameter. This closure will be called once per valid timepoint.
     - Parameter time: The timepoint for which the image is captured.
     - Parameter image: The captured image. Or nil if the capture was failed.
     
     - Note: This method takes advantage of the AVAsset class and it won't work with HLS videos.
     Use captureStillImageForHLSMediaItem(:) for HLS videos instead. The completion closure will be called on
     the main thread!
     */
    public func captureStillImageFromCurrentVideoAssets(forTimes timepoints: [Float]? = nil,
                                        completion: @escaping (_ time: Float, _ image: UIImage?) -> Void) throws {
        
        /* Won't call the completion when TinyVideoPlayer hasn't loaded any video assets yet. */
        guard let playerItem = playerItem  else {
            
            throw TinyVideoPlayerError.playerItemNotReady
        }
        
        var destinations: [NSValue] = []
        
        if let timepoints = timepoints {
            
            for time in timepoints {
                
                let destination = fmin(fmax(time, 0.0), videoDuration ?? 0.0) + startPosition
                
                guard let destinationMediaTime = floatTimepointToCMTime(destination) else {
                    continue
                }
                
                destinations.append(NSValue(time: destinationMediaTime))
            }
            
        } else {
            
            let destination = playbackPosition ?? 0.0 + startPosition
            
            if let destinationMediaTime = floatTimepointToCMTime(destination) {
                destinations.append(NSValue(time: destinationMediaTime))
            }
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: playerItem.asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: destinations) {
            (requestedTime: CMTime, image: CGImage?, _, result: AVAssetImageGeneratorResult, error: Error?) in
            
            let floatRepresentedTime = Float(CMTimeGetSeconds(requestedTime))
            
            if result == AVAssetImageGeneratorResult.failed {
                
                if let error = error {
                    self.errorLog("Image generation from video asset failed with error: \(error). " +
                        "A possible reason for this is that the video is loaded via a HLS link. " +
                        "Try use captureStillImageForHLSMediaItem(:) instead.")
                }
                
                DispatchQueue.main.async {
                    completion(floatRepresentedTime, nil)
                }
                
            } else if result == AVAssetImageGeneratorResult.succeeded {
                
                let resultImage = image.flatMap{ UIImage(cgImage: $0) }
                
                DispatchQueue.main.async {
                    completion(floatRepresentedTime, resultImage)
                }
            }
        }
    }
    
    /**
        Capture a still image at a given timepoint from the current playing HLS media item. The image capture only
        takes place in the valid time span. If the specified timepoint is out of bounds, TinyVideoPlayer will
        try to performe the action at the closest position. If the video duration is not known yet, TinyVideoPlayer
        will instead try to capture the very first frame of the video.
     
        - Parameter timepoint: A timepoint within the valid playable timespan at which TinyVideoPlayer will capture
            a still image from the video sequence. If you let it empty, then the currentPlayback time will
            be used.
        - Parameter completion: A closure that will be called after the image capture is done. The final result
            will be passed in as a closure parameter.
        - Parameter time: The timepoint for which the image is captured.
        - Parameter image: The captured image. Or nil if the capture was failed.
     
        - Note: This method is mainly used for image capture of a HLS media item. If the current playing item is not
        a HLS video, then the alternative method captureStillImageFromCurrentVideoAssets(:) works better in terms
        of performance. The completion closure will be called on the main thread!
     */
    public func captureStillImageForHLSMediaItem(atTime timepoint: Float? = nil,
                                                 completion: @escaping (_ time: Float, _ image: UIImage?) -> Void) {
        
        var destination: Float
        
        if let timepoint = timepoint {
            destination = fmin(fmax(timepoint, 0.0), videoDuration ?? 0.0) + startPosition
            
        } else {
            destination = playbackPosition ?? 0.0 + startPosition
        }
        
        guard let aCMTime = floatTimepointToCMTime(destination) else {
            
            completion(destination, nil)
            return
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            let pixelBuffer = self.playerItemVideoOutput?.copyPixelBuffer(forItemTime: aCMTime, itemTimeForDisplay: nil)
            let resultImage = pixelBuffer.flatMap{ CIImage.init(cvImageBuffer: $0) }
                .flatMap { UIImage(ciImage: $0) }
            
            let floatRepresentedTime = Float(CMTimeGetSeconds(aCMTime))
            
            DispatchQueue.main.async {
                
                completion(floatRepresentedTime, resultImage)
            }
        }
    }
    
    /**
        A little helper that converts a timepoint from its float representation to a CMTime representation.
     */
    fileprivate func floatTimepointToCMTime(_ timepoint: Float) -> CMTime? {
        
        let aCMTimepoint: CMTime = CMTime(seconds: Double(timepoint),
                                          preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        if !CMTIME_IS_VALID(aCMTimepoint) {
            
            self.errorLog("Can not convert given timepoint to CMTime: \(timepoint)")
            return nil
        }
        
        return aCMTimepoint
    }
}
