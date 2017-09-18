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

/**
    Here are several video urls that can be used to test the player.
    Feel free to add your own test resource.
 */
fileprivate let testVideoUrl = "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"

fileprivate let testHLSVideoUrl = "http://cdn-fms.rbs.com.br/hls-vod/sample1_1500kbps.f4v.m3u8"

fileprivate let testHLSVideoUrl2 = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

fileprivate let testHLSVideoUrl3 = "https://tungsten.aaplimg.com/VOD/bipbop_adv_example_v2/master.m3u8"

fileprivate let testHLSVideoUrl4 = "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"

fileprivate let testLocalVideo = Bundle.main.path(forResource: "unittest_video", ofType: "mp4")

class VideoPlayerViewModel: TinyLogging {
    
    /* Required property from the TinyLogging protocol. */
    var loggingLevel: TinyLoggingLevel = .info
    
    internal let tinyPlayer: TinyVideoPlayer
    
    /* A observer to receive updates from a VideoPlayerViewModel instance. */
    internal weak var viewModelObserver: PlayerViewModelObserver?
    
    init() {
        
        /* 
            We won't load the demo video and initiate only a empty player when the app instance
            is hosted by a XCTestCase. 
         */
        if ProcessInfo.processInfo.environment["RUNNING_TEST"] == "true" {
            tinyPlayer = TinyVideoPlayer()
            return
        }
        
        guard let url = URL(string: testVideoUrl) else {
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
        
        viewModelObserver?.demoPlayerHasUpdatedState(state: newState)
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
        
        viewModelObserver?.demoPlayerIsReadyToStartPlayingFromBeginning(isReady: true)
    }
    
    func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
        
        tinyPlayer.resetPlayback()
        viewModelObserver?.demoPlayerIsReadyToStartPlayingFromBeginning(isReady: true)
    }
}

// MARK: - Process commands from RootViewModel

extension VideoPlayerViewModel: VideoPlayerViewModelInput {
    
    func playButtonTapped() {
        
        if tinyPlayer.playbackState == .paused ||
           tinyPlayer.playbackState == .ready ||
           tinyPlayer.playbackState == .finished {
            
            tinyPlayer.play()
            
        } else if tinyPlayer.playbackState == .playing {
            
            tinyPlayer.pause()
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
    This protocol defines the callbacks from a viewModel observer. 
    In our case it describes the communication uplink from a VideoPlayerViewModel to a RootViewModel.
 */
internal protocol PlayerViewModelObserver: class {
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
