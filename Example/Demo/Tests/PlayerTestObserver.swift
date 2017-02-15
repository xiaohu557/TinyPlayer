//
//  PlayerTestObserver.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 15/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

@testable import TinyPlayer

class PlayerTestObserver: TinyPlayerDelegate {
    
    var videoPlayer: TinyVideoPlayer
    
    var onPlayerStateChanged: ((TinyPlayerState) -> Void)?
    var onPlaybackPositionUpdated: ((_ position: Float, _ progress: Float) -> Void)?
    var onSeekableRangeUpdated: ((ClosedRange<Float>) -> Void)?
    var onPlayerReady: (() -> Void)?
    var onPlaybackFinished: (() -> Void)?
    
    init(player: TinyVideoPlayer) {
        
        videoPlayer = player
        videoPlayer.delegate = self
    }
    
    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
        
        onVideoStateChanged?(newState)
    }
    
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
        
        onPlaybackPositionUpdated?((position, playbackProgress))
    }
    
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) {
        
        /* We won't monitor the buffer range here since AVPlayerItem won't buffer for local files. */
    }
    
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) {
        
        onSeekableRangeUpdated?(range)
    }
    
    public func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) {
    }
    
    func playerIsReadyToPlay(_ player: TinyPlayer) {
        
        onPlayerReady?()
    }
    
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
        
        onPlaybackFinished?()
    }
}
