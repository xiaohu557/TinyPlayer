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
    
    init(player: TinyVideoPlayer) {
        
        videoPlayer = player
        videoPlayer.delegate = self
    }
    
    // MARK: - Delegate Methods
    
    public func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
        
        onPlayerStateChanged?(newState)
    }
    
    public func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
        
        onPlaybackPositionUpdated?((position, playbackProgress))
        
        for (index, tpAction) in timepointActionRepository.enumerated() {
            
            if !timepointActionRepository[index].executed &&
                tpAction.timepoint - position < 0.1 {
                
                tpAction.onTimepoint()
                
                print("Executed timepoint action at \(tpAction.timepoint)!")
                
                timepointActionRepository[index].executed = true
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
        The last property of the tuple is used to support recording the execution state.
     */
    private typealias TimepointAction = (timepoint: Float, onTimepoint: () -> Void, executed: Bool)
    
    /**
        Used to maintain a group of timepoint-actions.
     */
    private var timepointActionRepository: [TimepointAction] = []
    
    /**
        Add an action closure to the repository that will get excuted at the specific time.
        The action closure only gets executed once(!) when the playback position is approaching the specified
        timepoint with a 0.1 sec tolerance.
     
        - Note: Avoid to put the onPlaybackPositionUpdated closure inside Nimble's waitUntil(:) closure!
        The reason is that onPlaybackPositionUpdated will get called at a 60fps rate, this causes issue when 
        unblocking the mainthread after the done() declaration within Nimble. Doing so will potentially cause 
        Nimble to throw an exception about calling done() too many times.
     
        - Parameter action: A closure that contains to be excuted commands on the specific timepoint.
        - Parameter timepoint: A timepoint at which the action closure get executed.
     */
    public func registerAction(action: @escaping () -> Void, onTimepoint timepoint: Float) {
        
        let timpepointAction: TimepointAction = TimepointAction(timepoint: timepoint,
                                            onTimepoint: action,
                                            executed: false)
        timepointActionRepository.append(timpepointAction)
    }
}
