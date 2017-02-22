//
//  TinyVideoPlayerView.swift
//  Leanr
//
//  Created by Kevin Chen on 29/11/2016.
//  Copyright © 2016 Magic Internet. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/**
    - Note: Every TinyVideoPlayer contains a TinyVideoPlayerView.
 
    The default backing CALayer of the TinyVideoPlayerView is set to a AVPlayerLayer.
    You should always create the TinyVideoPlayer first, before you can operate on its playerView property.
    This ensures that the video object gets initialized and handled properly before it gets propergated to view.
 
    TinyVideoPlayer -> TinyVideoPlayerView

 */
public class TinyVideoPlayerView: UIView {
    
    internal weak var player: AVPlayer? {
        
        get {
            return playerLayer.player 
        }
        
        set {
            playerLayer.player = newValue
        }
    }

    internal var playerLayer: AVPlayerLayer {
        
        return layer as! AVPlayerLayer
    }
    
    override public class var layerClass: AnyClass {
        
        return AVPlayerLayer.self
    }
  
    /**
        Set fillMode to determine how you want the video content to be rendered within the playerView.
     */
    public var fillMode: TinyPlayerContentFillMode {
        
        didSet {
            
            switch fillMode {
                
            case .resizeFill:
                playerLayer.videoGravity = AVLayerVideoGravityResize
            case .resizeAspect:
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            case .resizeAspectFill:
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            }
        }
    }
    
    override init(frame: CGRect) {
        
        fillMode = .resizeAspectFill
        
        super.init(frame: frame)
    }
  
    required public init?(coder aDecoder: NSCoder) {

        fillMode = .resizeAspectFill

        super.init(coder: aDecoder)
    }
}

/**
    There are three predefined fill modes for displaying video content:
    - resizeFill: Stretch the video content to fill the playerView's bounds.
    - resizeAspect: Maintain the video's aspect ratio and fit it within the playerView's bounds.
    - resizeAspect: Maintain the video's aspect ratio while expanding the content to fill the playerView's bounds.
 */
public enum TinyPlayerContentFillMode {
    case resizeFill
    case resizeAspect
    case resizeAspectFill
    
}
