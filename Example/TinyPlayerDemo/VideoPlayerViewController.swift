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
    
    let viewModel: VideoPlayerViewModel
    
    weak var delegate: DemoPlayerControlDelegate?
    
    var loggingLevel: TinyLoggingLevel = .info
    
    required init?(coder aDecoder: NSCoder) {

        viewModel = VideoPlayerViewModel()
        
        super.init(coder: aDecoder)

        viewModel.tinyPlayer.delegate = self
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        viewModel = VideoPlayerViewModel()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        viewModel.tinyPlayer.delegate = self
    }
    
    deinit {
        
        infoLog("Player view controller is dealloced.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.view.addSubview(viewModel.tinyPlayer.playerView)
        
        /* 
            Setup player view constrains. 
         */
        viewModel.tinyPlayer.playerView.translatesAutoresizingMaskIntoConstraints = false
        
        viewModel.tinyPlayer.playerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
    }
    
    // MARK: - TinyPlayer Delegates
    
    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
        
        infoLog("Tiny player has changed state: \(oldState) >> \(newState)")
        
        delegate?.demoPlayerHasUpdatedState(state: newState)
    }
    
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
    
        verboseLog("Tiny player has updated playing position: \(position), progress: \(playbackProgress)")
    }
    
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) {
        
        verboseLog("Tiny player has updated buffered time range: \(range.lowerBound) - \(range.upperBound)")
    }
    
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) {
        
        infoLog("Tiny player has updated seekable time range: \(range.lowerBound) - \(range.upperBound)")
    }
    
    public func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) {
        
        infoLog("Tiny player has encountered an error: \(error)")
    }
    
    func playerIsReadyToPlay(_ player: TinyPlayer) {
        
        delegate?.demoPlayerIsReadyToStartPlayingFromBeginning(isReady: true)
    }
    
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
        
        delegate?.demoPlayerIsReadyToStartPlayingFromBeginning(isReady: true)
    }

    // MARK: - Player controls
    
    func playButtonTapped() {
        
        if viewModel.tinyPlayer.playbackState == .paused ||
           viewModel.tinyPlayer.playbackState == .ready ||
           viewModel.tinyPlayer.playbackState == .finished {
            
            viewModel.tinyPlayer.play()
            
        } else if viewModel.tinyPlayer.playbackState == .playing {
            
            viewModel.tinyPlayer.pause()
        }
    }
    
    func seekBackwardsFor5Secs() {
        
        viewModel.tinyPlayer.seekBackward(secs: 5.0)
    }
    
    func seekForwardsFor5Secs() {
        
        viewModel.tinyPlayer.seekForward(secs: 5.0)
    }
    
    func freePlayerItemResource() {
        
        viewModel.tinyPlayer.closeCurrentItem()
    }
}
