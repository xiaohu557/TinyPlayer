//
//  VideoPlayerViewModel.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import Foundation
import UIKit
import TinyPlayer

protocol PlayerViewModelDelegatable {
    var delegate: PlayerViewModelDelegate? { get set }
}

class VideoPlayerViewModel: PlayerViewModelDelegatable, TinyLogging {
    
    /* Required property from the TinyLogging protocol. */
    var loggingLevel: TinyLoggingLevel = .info
    
    let tinyPlayer: TinyVideoPlayer
    
    /* A observer that will receive updates from a VideoPlayerViewModel instance. */
    weak var delegate: PlayerViewModelDelegate?
    
    init(repository: VideoURLRepository) {
        /*
            We won't load the demo video and initiate only a empty player when the app
            instance is hosted by a XCTestCase.
         */
        if ProcessInfo.processInfo.environment["RUNNING_TEST"] == "true" {
            tinyPlayer = TinyVideoPlayer()
            return
        }

        let urlString = repository.fetchVideoUrlString()
        guard let url = URL(string: urlString) else {
            tinyPlayer = TinyVideoPlayer()
            return
        }
        
        let mediaContext = MediaContext(videoTitle: "Big Buck Bunny - A MP4 test video.",
                                        artistName: "TinyPlayerDemo",
                                        startPosition: 9.0,
                                        endPosition: 0.0,       /// To play to the end of the video
                                        thumbnailImage: UIImage(named: "DemoVideoThumbnail_MP4"))
        
        tinyPlayer = TinyVideoPlayer(resourceUrl: url, mediaContext: mediaContext)
        
        tinyPlayer.delegate = self
    }
}

// MARK: - TinyPlayerDelegates

extension VideoPlayerViewModel: TinyPlayerDelegate {
    
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
        tinyPlayer.resetPlayback()
        delegate?.demoPlayerIsReadyToStartPlayingFromBeginning(isReady: true)
    }
}

// MARK: - Process commands from RootViewModel

extension VideoPlayerViewModel: VideoPlayerViewModelInput {
    
    func playButtonTapped() {
        switch tinyPlayer.playbackState {
        case .paused, .ready, .finished:
            tinyPlayer.play()
        case .playing:
            tinyPlayer.pause()
        default:
            break
        }
    }
    
    func seekBackwardsFor5Secs() {
        tinyPlayer.seekBackward(secs: 5.0)
    }
    
    func seekForwardsFor5Secs() {
        tinyPlayer.seekForward(secs: 5.0)
    }
    
    func freePlayerItemResource() {
        tinyPlayer.closeCurrentItem()
    }
}

/**
    This protocol defines the delegate methods of a videoPlayerViewModel observer.
    In our case it describes the communication uplink from a VideoPlayerViewModel to a RootViewModel.
 */
internal protocol PlayerViewModelDelegate: class {
    func demoPlayerIsReadyToStartPlayingFromBeginning(isReady: Bool)
    func demoPlayerHasUpdatedState(state: TinyPlayerState)
}

/**
 This protocol defines all the commands that a CommandReceiver can take as input.
 In our case, a CommandReceiver will be a VideoPlayerViewModel instance.
 */
protocol VideoPlayerViewModelInput: class {
    func playButtonTapped()
    func seekBackwardsFor5Secs()
    func seekForwardsFor5Secs()
    func freePlayerItemResource()
}
