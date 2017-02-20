//
//  PlayerTestObserver.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 15/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import TinyPlayer

public class PlayerTestObserver: TinyPlayerDelegate {
    
    private var videoPlayer: TinyVideoPlayer
    
    public var onPlayerStateChanged: ((TinyPlayerState) -> Void)?
    public var onPlaybackPositionUpdated: ((_ position: Float, _ progress: Float) -> Void)?
    public var onSeekableRangeUpdated: ((ClosedRange<Float>) -> Void)?
    public var onPlayerReady: (() -> Void)?
    public var onPlaybackFinished: (() -> Void)?
    

    public var onPlaybackHasOverThe3SecsMark: (() -> Void)?
    
    init(player: TinyVideoPlayer) {
        
        videoPlayer = player
        videoPlayer.delegate = self
    }
    
    // MARK: - Delegate Methods
    
    public func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
        
        onPlayerStateChanged?(newState)
    }
    
    private var positionOnceToken = 0x1
    public func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
        
        onPlaybackPositionUpdated?((position, playbackProgress))
        
        if position > 3.0 && positionOnceToken > 0x0 {
            onPlaybackHasOverThe3SecsMark?()
            positionOnceToken = 0x0
        }
        
        for (index, tpAction) in timepointActions.enumerated() {
            
            if !timepointActions[index].executed &&
                tpAction.timepoint - position < 0.1 {
                
                tpAction.onTimepoint()
                
                print("Executed timepoint action at \(tpAction.timepoint)!")
                
                timepointActions[index].executed = true
            }
        }
    }
    
    public func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) {
        
        /* We won't monitor the buffer range here since AVPlayerItem won't buffer for local files. */
    }
    
    public func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) {
        
        onSeekableRangeUpdated?(range)
    }
    
    public func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) {
    }
    
    public func playerIsReadyToPlay(_ player: TinyPlayer) {
        
        onPlayerReady?()
    }
    
    public func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
        
        onPlaybackFinished?()
    }
    
    // MARK: - Helper
    
    /**
        This tuple can be intepreted as "at which timepoint, what operation need to be called".
     */
    public typealias TimepointAction = (timepoint: Float, onTimepoint: () -> Void)
    
    /**
        A private property which extends the original tuple to support recording the execution state.
     */
    private typealias TimepointActionExtended = (timepoint: Float, onTimepoint: () -> Void, executed: Bool)
    
    /**
        Used to maintain a group of timepoint-actions.
     */
    private var timepointActions: [TimepointActionExtended] = []
    
    /**
        Add a new pair of timepoint-action to the repository which will be excuted at the specific time.
     
        - Note: Avoid to put the onPlaybackPositionUpdated closure inside Nimble's waitUntil(:) method.
        Because onPlaybackPositionUpdated will be called multiple times per second.
        Doing so will cause Nimble to throw the exception of calling done() too many times!
     
        - Parameter timepointAction: A TimepointAction tuple that represents the timepoint and the wanted action.
     */
    public func registerActionOnTimepoint(_ timepointAction: TimepointAction) {
        
        timepointActions.append(TimepointActionExtended(timepoint: timepointAction.timepoint,
                                                        onTimepoint: timepointAction.onTimepoint,
                                                        executed: false
                                                        ))
    }
    
    ///TODO: Write a factory for timepoint actions!
}
