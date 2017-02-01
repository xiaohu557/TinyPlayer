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
 * - Note: Every TinyVideoPlayer contains a TinyVideoPlayerView.
 * The default backing layer of the TinyVideoPlayerView is a AVPlayerLayer. Change player object of this class to switch AVPlayer.
 * You should always create the TinyVideoPlayer first, before you access its playerView property.
 * This ensures that the video data get initialized first before it gets propergated to view.
 *
 * TinyVideoPlayer -> TinyVideoPlayerView

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


public enum TinyPlayerContentFillMode {
    case resizeFill
    case resizeAspect
    case resizeAspectFill
    
}
