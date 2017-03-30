//
//  TinyVideoProjectionView.swift
//  Leanr
//
//  Created by Kevin Chen on 29/11/2016.
//  Copyright © 2016 Magic Internet. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/**
    A view which is connected to an instance of TinyVideoPlayer that can draw video content directly onto it.
 
    The default backing layer(CALayer) of TinyVideoProjectionView is set to a AVPlayerLayer.
    You should always create the TinyVideoPlayer instance first, before you can create its projection view.
    This ensures that the video object gets initialized and handled properly before it gets propergated to the view.
 
    - Note: Every TinyVideoPlayer can be connected to arbitrary number of TinyVideoProjectionViews. The correct
    initial sequence: TinyVideoPlayer -> generateVideoProjectionView() -> TinyVideoProjectionView.
 */
public class TinyVideoProjectionView: UIView {
    
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
    
    /**
        A read-only unique identify for a single video projection view instance, that is generated while the
        instance is created.
     */
    private(set) public var hashId: String
    
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
        
        hashId = UUID().uuidString
        
        super.init(frame: frame)
    }
  
    required public init?(coder aDecoder: NSCoder) {

        fillMode = .resizeAspectFill

        hashId = UUID().uuidString

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
