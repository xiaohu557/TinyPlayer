//
//  TinyPlayerStateTransationTests.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 16/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import TinyPlayer

class TinyPlayerStateTransationSpecs: QuickSpec {
    
    override func spec() {
        
        describe("TinyVideoPlayer") {
            
            let urlPath = Bundle(for: type(of: self)).path(forResource: "unittest_video", ofType: "mp4")
            let targetUrl = urlPath.flatMap { URL(fileURLWithPath: $0) }
            
            guard let url = targetUrl else {
                XCTFail("Error encountered at loading test video.")
                return
            }

            describe("can update states correctly in it's lifecycle") {
                
                let mediaContext = MediaContext(videoTitle: "Test Video with start and end settings",
                                                artistName: "TinyPlayer Tester",
                                                startPosition: 3.0,
                                                endPosition: 8.0,
                                                thumbnailImage: nil)
                
                context("when call switch resource url with an already loaded item") {
                    
                    it("when the same url is specified, only a .ready event should be recored") {
                        
                        var stateRecordsFragment: [TinyPlayerState] = []
                        
                        let videoPlayer = TinyVideoPlayer()
                        let spy = PlayerTestObserver(player: videoPlayer)
                        
                        /* First we load a video, then wait until it's ready. */
                        videoPlayer.switchResourceUrl(url)
                        expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 5.0)
                        
                        /* Load the second video and check state changes. */
                        waitUntil(timeout: 10.0) { done -> Void in
                            
                            spy.onPlayerReady = nil
                            
                            spy.onPlayerStateChanged = { state in
                                
                                /* Collect state changes one by one in an array. */
                                stateRecordsFragment.append(state)
                                
                                if state == .ready {
                                    done()
                                }
                            }
                            
                            /* Start loading the player with the same video now. */
                            videoPlayer.switchResourceUrl(url, mediaContext: mediaContext)
                        }
                        
                        expect(stateRecordsFragment).to(equal([
                            TinyPlayerState.ready
                            ]))
                    }
                    
                    it("when a different url is specified, a .closed event should be emitted first") {
                        
                        var stateRecordsFragment: [TinyPlayerState] = []
                        
                        let videoPlayer = TinyVideoPlayer()
                        let spy = PlayerTestObserver(player: videoPlayer)
                        
                        /* First we load a video, then wait until it's ready. */
                        videoPlayer.switchResourceUrl(url)
                        expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 5.0)
                        
                        /* Load the second video and check state changes. */
                        waitUntil(timeout: 10.0) { done -> Void in
                            
                            spy.onPlayerReady = nil
                            
                            spy.onPlayerStateChanged = { state in
                                
                                /* Collect state changes one by one in an array. */
                                stateRecordsFragment.append(state)
                                
                                if state == .ready {
                                    done()
                                }
                            }

                            /* Start loading the player with an alternative video now. */
                            let newUrlPath = Bundle(for: type(of: self)).path(forResource: "unittest_video_alternative", ofType: "mp4")
                            guard let newUrl = (newUrlPath.flatMap { URL(fileURLWithPath: $0) }) else {
                                XCTFail("Error encountered at loading test video.")
                                return
                            }
                            
                            /* 
                                Note that TinyVideoPlayer will check the url parameter to determin
                                whether start a new loading or just reset the current media item. 
                             */
                            videoPlayer.switchResourceUrl(newUrl, mediaContext: mediaContext)
                        }
                        
                        expect(stateRecordsFragment).to(equal([
                            TinyPlayerState.closed,
                            TinyPlayerState.unknown,
                            TinyPlayerState.ready,
                            ]))
                    }
                }
                
                context("when prettify filter on") {
                    
                    let idealPlaybackLifecycleStateRecordsWithPrettifyingOn = [
                        TinyPlayerState.unknown,
                        TinyPlayerState.ready,
                        TinyPlayerState.waiting,
                        TinyPlayerState.playing,
                        TinyPlayerState.finished
                    ]
                    
                    it("states are transited in a determinic way in a normal playback lifecycle") {
                        
                        var stateRecords: [TinyPlayerState] = []
                        
                        let videoPlayer = TinyVideoPlayer()
                        let spy = PlayerTestObserver(player: videoPlayer)
                        
                        waitUntil(timeout: 12.0) { done -> Void in
                            
                            spy.onPlayerReady = { [weak videoPlayer] in
                                videoPlayer?.play()
                            }
                            
                            spy.onPlayerStateChanged = { state in
                                
                                /* Collect state changes one by one in an array. */
                                stateRecords.append(state)
                                
                                if state == .finished {
                                    done()
                                }
                            }
                            
                            /* Start player initialization now. */
                            videoPlayer.switchResourceUrl(url, mediaContext: mediaContext)
                        }
                        
                        expect(stateRecords).to(equal(idealPlaybackLifecycleStateRecordsWithPrettifyingOn))
                    }
                }
                
                context("when prettify filter off") {
                    
                    let idealPlaybackLifecycleStateRecordsWithPrettifyingOff = [
                        TinyPlayerState.unknown,
                        TinyPlayerState.ready,
                        TinyPlayerState.waiting,
                        TinyPlayerState.playing,
                        TinyPlayerState.paused,
                        TinyPlayerState.finished
                    ]
                    
                    it("states are transited in a determinic way in a normal playback lifecycle") {
                        
                        var stateRecords: [TinyPlayerState] = []
                        
                        let videoPlayer = TinyVideoPlayer()
                        videoPlayer.willPrettifyPauseStateTransation = false
                        let spy = PlayerTestObserver(player: videoPlayer)
                        
                        waitUntil(timeout: 10.0) { done -> Void in
                            
                            spy.onPlayerReady = { [weak videoPlayer] in
                                videoPlayer?.play()
                            }
                            
                            spy.onPlayerStateChanged = { state in
                                
                                /* Collect state changes one by one in an array. */
                                stateRecords.append(state)
                                
                                if state == .finished {
                                    done()
                                }
                            }
                            
                            /* Start player initialization now. */
                            videoPlayer.switchResourceUrl(url, mediaContext: mediaContext)
                        }
                        
                        expect(stateRecords).to(equal(idealPlaybackLifecycleStateRecordsWithPrettifyingOff))
                    }
                }
            }
            
            describe("can switch states according to player operations") {
                
                it("play") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []

                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    /* Wait until the player receives the ready signal. */
                    waitUntil(timeout: 5.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                            
                            if state == .playing {
                                done()
                            }
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(stateRecordsFragment).to(equal([
                        TinyPlayerState.ready,
                        TinyPlayerState.waiting,
                        TinyPlayerState.playing
                    ]))
                }
                
                it("pause") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    /* Wait until the player receives the ready signal. */
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                        }
                        
                        /* Pause at the 2.0 secs position and resume after the 3.0 sec. */
                        let actionAt2Secs = { [weak videoPlayer] in
                            videoPlayer?.pause()
                            Thread.sleep(forTimeInterval: 3.0)
                            videoPlayer?.play()
                        }
                        spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                        
                        /* Finish test after 4.0 secs position. */
                        let actionAt4Secs = {
                            done()
                        }
                        spy.registerAction(action: actionAt4Secs, onTimepoint: 4.0)
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(stateRecordsFragment).to(equal([
                        TinyPlayerState.ready,
                        TinyPlayerState.waiting,
                        TinyPlayerState.playing,
                        TinyPlayerState.paused,
                        TinyPlayerState.waiting,
                        TinyPlayerState.playing
                        ]))
                }
                
                it("reset playback") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        /* Wait until the player receives the ready signal then start playing. */
                        var onceToken = 0x1
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            if onceToken > 0x0 {
                                videoPlayer?.play()
                                onceToken = 0x0
                            }
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                        }
                        
                        let actionAt3Secs = { [weak videoPlayer] in
                            videoPlayer?.resetPlayback()
                            done()
                        }
                        spy.registerAction(action: actionAt3Secs, onTimepoint: 3.0)

                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 3.0)
                }
                
                /**
                    To make the player lightweighted we don't have a seek state, therefore we expect the player
                    to report the .playing state directly before and after the seeking.
                 */
                
                let idealSeekingStateRecords = [
                    TinyPlayerState.ready,
                    TinyPlayerState.waiting,
                    TinyPlayerState.playing
                ]
                
                it("seek to") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                        }
                        
                        /* Seek to 30.0 secs at the 2.0 secs position. */
                        let actionAt2Secs = { [weak videoPlayer] in
                            videoPlayer?.seekTo(position: 30.0)
                            return
                        }
                        spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                        
                        /* Finish test after the 32.0 secs position. */
                        let actionAt32Secs = {
                            done()
                        }
                        spy.registerAction(action: actionAt32Secs, onTimepoint: 32.0)
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(stateRecordsFragment).to(equal(idealSeekingStateRecords))
                }
                
                it("seek forwards") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                        }
                        
                        /* Seek Forward 48.0 secs at the 2.0 secs position. */
                        let actionAt2Secs = { [weak videoPlayer] in
                            videoPlayer?.seekForward(secs: 48.0)
                            return
                        }
                        spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                        
                        /* Finish test after the 52.0 secs position. */
                        let actionAt52Secs = {
                            done()
                        }
                        spy.registerAction(action: actionAt52Secs, onTimepoint: 52.0)
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(stateRecordsFragment).to(equal(idealSeekingStateRecords))
                }
                
                it("seek backwards") {
                    
                    var stateRecordsFragment: [TinyPlayerState] = []
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlayerStateChanged = { state in
                            
                            /* Record the state changes after .ready. */
                            if state.rawValue >= TinyPlayerState.ready.rawValue {
                                stateRecordsFragment.append(state)
                            }
                        }
                        
                        /* Seek forward 48.0 secs at the 2.0 secs position. */
                        let actionAt2Secs = { [weak videoPlayer] in
                            videoPlayer?.seekForward(secs: 48.0)
                            return
                        }
                        spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                        
                        /* Then seek backward to 2.0 at the 52.0 secs position. */
                        let actionAt52Secs = { [weak videoPlayer] in
                            videoPlayer?.seekBackward(secs: 50.0)
                            return
                        }
                        spy.registerAction(action: actionAt52Secs, onTimepoint: 52.0)
                        
                        /* Finish test after the 4.0 secs position. */
                        let actionAt4Secs = {
                            done()
                        }
                        spy.registerAction(action: actionAt4Secs, onTimepoint: 4.0)
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(stateRecordsFragment).to(equal(idealSeekingStateRecords))
                }
            }
        }
    }
}

