//
//  PlayerDefinition.swift
//  Leanr
//
//  Created by Kevin Chen on 29/11/2016.
//  Copyright © 2016 Magic Internet. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public enum TinyPlayerState: Int {
    case unknown = 0
    case ready =  1
    case playing = 2
    case waiting = 3
    case paused = 4
    case finished = 5
    case closed = 6
    case error = -1
}

/**
    This protocol defines the public general APIs of the TinyPlayer.
 */
public protocol TinyPlayer: class {
    
    weak var delegate: TinyPlayerDelegate? { get set }
    var playbackState: TinyPlayerState { get }
    
    var videoDuration: Float? { get }
    var playbackPosition: Float? { get }
    var playbackProgress: Float? { get }
    var bufferProgress: Float? { get }
    var willPrettifyPauseStateTransation: Bool { get set }
    
    func switchResourceUrl(_ resourceUrl: URL, mediaContext: MediaContext?)
    func play()
    func pause()
    func closeCurrentItem() /* Stop playing, release the current playing item from memeory. */
    func resetPlayback()
    func seekTo(position: Float, cancelPreviousSeeking: Bool, completion: ((Bool)-> Void)?)
    func seekForward(secs: Float, completion: ((Bool)-> Void)?)
    func seekBackward(secs: Float, completion: ((Bool)-> Void)?)
}

/**
    This protocol defines the additional video related public APIs for the TinyVideoPlayer.
 */
public protocol TinyVideoPlayerProtocol: TinyPlayer {
    
    var hidden: Bool { get set }

    func generateVideoProjectionView() -> TinyVideoProjectionView
    func recycleVideoProjectionView(_ connectedView: TinyVideoProjectionView)
    
    func captureStillImageFromCurrentVideoAssets(forTimes timePoints: [Float]?,
                                                 completion: @escaping (_ time: Float, _ image: UIImage?) -> Void) throws
    func captureStillImageForHLSMediaItem(atTime timepoint: Float?,
                                          completion: @escaping (_ time: Float, _ image: UIImage?) -> Void)
}

/**
    This protocol defines the public delegate methods that TinyPlayer will call in certain conditions.
    All the delegate methods are optional.
 */
public protocol TinyPlayerDelegate: class {
    
    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState)
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float)
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>)
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>)
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer)
    func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error)

    /**
        This method gets called when the media asset is successfully initialized
        and the player thinks it's ready for playback.
        You can send the play() command to the player right away once you have received this callback.
        - parameter player: The player that calls this delegate method.
        - Note: At this stage, the player might still need to fill the buffer before starting playback.
     */
    func playerIsReadyToPlay(_ player: TinyPlayer)

    /**
        It gets called when the player thinks it has cached enough data
        for a seemless playback.
        - parameter player: The player that calls this delegate method.
        - Note: You can determine whether to rely on this method or the playerIsReadyToPlay(:) method to trigger the staring playback behavior.
     */
    func playerIsLikelyToKeepUpPlaying(_ player: TinyPlayer)

    /* 
        The following three are planned for the upcoming AdPlayer component, optional.
        Caution: These methods are not implemented yet, please don't use them!
     */
    func player(_ player: TinyPlayer, didReceivedAdInjectPositions positions: [Float])
    func player(_ player: TinyPlayer, didStartAdPlayback adObject: NSObjectProtocol)
    func player(_ player: TinyPlayer, didFinishedAdPlayback adObject: NSObjectProtocol)
}

/// TODO: Add ads playback support.

/**
    Optional delegate methods in TinyPlayerDelegate.
 */
public extension TinyPlayerDelegate {
    
    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) { }
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) { }
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) { }
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) { }
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer) { }
    func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) { }
    func playerIsReadyToPlay(_ player: TinyPlayer) { }
    func playerIsLikelyToKeepUpPlaying(_ player: TinyPlayer) { }
    
    func player(_ player: TinyPlayer, didReceivedAdInjectPositions positions: [Float]) { }
    func player(_ player: TinyPlayer, didStartAdPlayback adObject: NSObjectProtocol) { }
    func player(_ player: TinyPlayer, didFinishedAdPlayback adObject: NSObjectProtocol) { }
}

/**
    The purpose of this data structure is to provide extra context of the current media. 
    These will also be used to support displaying info on the CommandCenter.

    - Note: When startPosition and / or endPosition is set, the valid playable timespan for the current video
            will be shorter! And the videoDuration,  playbackPosition and playbackProgress will be affected.
 */
public struct MediaContext {
    
    var videoTitle: String?
    var artistName: String?
    
    /**
        Optional. It denotes the desired starting position of the current media.
        Can be used to jump over unwanted video intros.
      */
    var startPosition: Float?
    
    /**
        Optional. It denotes the desired ending position of the current media.
        Can be used to cut unwanted video ending.
      */
    var endPosition: Float?
    
    /** 
        Optional. If don't specify, the player will take the duration of the playItem.
      */
    var thumbnailImage: UIImage?
    
    public init(videoTitle: String?, artistName: String?, startPosition: Float?,
                endPosition: Float?, thumbnailImage: UIImage?) {
        
                    self.videoTitle = videoTitle
                    self.artistName = artistName
                    self.startPosition = startPosition
                    self.endPosition = endPosition
                    self.thumbnailImage = thumbnailImage
                }
}

/**
    Enumunates possible encoutnered player error.
 */
enum TinyVideoPlayerError: Error {
    case assetNotPlayable
    case assetDownloadFailed
    case playerItemNotReady
}


