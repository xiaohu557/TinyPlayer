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

class VideoPlayerViewController: UIViewController, TinyPlayerDelegate, TinyLogging {
    
    let viewModel: VideoPlayerViewModel = VideoPlayerViewModel()
    
    var loggingLevel: TinyLoggingLevel = .info
    
    
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
        
        infoLog("Player view controller is dealloced.")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        /*
        let playerView = TinyVideoPlayerView(frame: .zero)
        self.view.addSubview(playerView)
        self.view.backgroundColor = UIColor.clear
        playerView.player = viewModel.videoPlayer.player
        */
        
        let playerView = viewModel.tinyPlayer.playerView
        self.view.addSubview(playerView)
        self.view.backgroundColor = UIColor.clear
        
        playerView.fillMode = .resizeAspectFill
        let hueValue = CGFloat(arc4random() % 256) / 255.0
        playerView.backgroundColor = UIColor.init(hue: hueValue, saturation: 0.16, brightness: 0.8, alpha: 1.0)
        
        /* 
            Setup player view constrains. 
         */
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        playerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0.0).isActive = true
        playerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
        playerView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
        playerView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
    }
    
    
    // MARK: - TinyPlayer Delegates
    
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
