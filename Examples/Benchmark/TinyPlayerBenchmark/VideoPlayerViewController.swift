//
//  VideoPlayerViewController.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import Foundation
import UIKit
import TinyPlayer

class VideoPlayerViewController: UIViewController, TinyLogging {
    
    /* Required property for the TinyLogging service. */
    internal var loggingLevel: TinyLoggingLevel = .info

    fileprivate let viewModel: VideoPlayerViewModel = VideoPlayerViewModel()
    
    /* Hold an instance of the player's video projection view for later animated transation. */
    fileprivate var videoProjectionView: TinyVideoProjectionView?
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)

        viewModel.tinyPlayer.delegate = self
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        viewModel.tinyPlayer.delegate = self
    }
    
    deinit {
        
        viewModel.tinyPlayer.delegate = nil
        
        /*
            Just a demo of using the recycle method.
         
            In this project it's not necessary to deliberately recycle the projection view, because this view 
            controller owns the instance of its own view model, and therefore indirectly owns the TinyVideoPlayer
            instance. While releasing the view controller, we also release the TinyVideoPlayer instance (and the
            projection view owned by it).
         */
        if let videoProjectionView = videoProjectionView {
            viewModel.tinyPlayer.recycleVideoProjectionView(videoProjectionView)
        }

        infoLog("Player view controller is dealloced.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        /* Generate a projection view from TinyVideoPlayer and add it to the current view hierarchy. */
        videoProjectionView = viewModel.tinyPlayer.generateVideoProjectionView()

        guard let videoProjectionView = videoProjectionView else {
            return
        }

        videoProjectionView.alpha = 0.2
        videoProjectionView.fillMode = .resizeAspectFill
        
        let hueValue = CGFloat(arc4random() % 256) / 255.0
        videoProjectionView.backgroundColor = UIColor.init(hue: hueValue, saturation: 0.16, brightness: 0.2, alpha: 1.0)
        
        self.view.addSubview(videoProjectionView)
        self.view.backgroundColor = UIColor.clear
        
        /* 
            Setup player view constrains. 
         */
        videoProjectionView.translatesAutoresizingMaskIntoConstraints = false
        
        videoProjectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0.0).isActive = true
        videoProjectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
        videoProjectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
        videoProjectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
    }
}

// MARK: - TinyPlayer Delegates

extension VideoPlayerViewController: TinyPlayerDelegate {

    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
        
        infoLog("Tiny player has changed state: \(oldState) >> \(newState)")
    }
    
    
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
        
        verboseLog("Tiny player has updated playing position: \(position), progress: \(playbackProgress)")
    }
    
    
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) {
        
        verboseLog("Tiny player has updated buffered time range: \(range.lowerBound) - \(range.upperBound)")
    }
    
    
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) {
        
        verboseLog("Tiny player has updated seekable time range: \(range.lowerBound) - \(range.upperBound)")
    }
    
    
    public func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) {
        
        errorLog("Tiny player has encountered an error: \(error)")
    }
    
    
    func playerIsReadyToPlay(_ player: TinyPlayer) {

        UIView.animate(withDuration: 0.4) {
            
            if let projectionView = self.videoProjectionView {
                projectionView.alpha = 1.0
            }
        }

        viewModel.tinyPlayer.play()
    }
    
    
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
        
        viewModel.tinyPlayer.resetPlayback()
        
        viewModel.tinyPlayer.play()
    }
    
    
    func freePlayerItemResource() {
        
        viewModel.tinyPlayer.closeCurrentItem()
    }
}
