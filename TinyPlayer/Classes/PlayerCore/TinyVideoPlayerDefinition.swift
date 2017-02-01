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

public protocol TinyPlayerDelegate: class {
    
    func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState)
    func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float)
    func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>)
    func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>)
    func playerIsReadyToPlay(_ player: TinyPlayer)
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer)
    func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error)
    
    /* For AdPlayer, optional */
    func player(_ player: TinyPlayer, didReceivedAdInjectPositions positions: [Float])
    func player(_ player: TinyPlayer, didStartAdPlayback adObject: NSObjectProtocol)
    func player(_ player: TinyPlayer, didFinishedAdPlayback adObject: NSObjectProtocol)
}

/**
    Caution: The following three methods are not implemented yet!
    TODO: Add ads playback support.
    Mark the following three methods to be optional.
 */
public extension TinyPlayerDelegate {
    
    func player(_ player: TinyPlayer, didReceivedAdInjectPositions positions: [Float]) { }
    func player(_ player: TinyPlayer, didStartAdPlayback adObject: NSObjectProtocol) { }
    func player(_ player: TinyPlayer, didFinishedAdPlayback adObject: NSObjectProtocol) { }
}

/**
    The purpose of this data structure is to provide extra context of the current media. It's also used to support displaying info on the CommandCenter.

    - note: If startPosition and / or endPosition is set, the playbale video is shorter! The consequence to this is that the videoDuration, playbackPosition, playbackProgress will be affected.
 */
public struct MediaContext {
    
    var videoTitle: String?
    var artistName: String?
    
    /*  
        Optional. It denotes the desired starting position of the current media.
        Can be used to jump over unwanted video intros.
     */
    var startPosition: Float?
    /*
        Optional. It denotes the desired ending position of the current media.
        Can be used to cut unwanted video ending.
     */
    var endPosition: Float?
    /*
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
    This protocol defines the public APIs of the TinyVideoPlayer.
 */
public protocol TinyPlayer: class {
    
    weak var delegate: TinyPlayerDelegate? { get set }
    
    var playerView: TinyVideoPlayerView { get }
    
    var playbackState: TinyPlayerState { get }

    var videoDuration: Float? { get }
    var playbackPosition: Float? { get }
    var playbackProgress: Float? { get }
    var bufferProgress: Float? { get }
    var hidden: Bool { get set }
    var isPrettyfingPauseStateTransation: Bool { get set }

    func switchResourceUrl(_ resourceUrl: URL, mediaContext: MediaContext?)
    func play()
    func pause()
    func closeCurrentItem() /* Stop playing, release the current playing item from memeory. */
    func resetPlayback()
    func seekTo(position: Float, completion: (()-> Void)?)
    func seekForward(secs: Float, completion: (()-> Void)?)
    func seekBackward(secs: Float, completion: (()-> Void)?)
}

/**
    Enumunates possible encoutnered player error.
 */
enum TinyVideoPlayerError: Error {
    case assetNotPlayable
    case assetDownloadFailed
}


