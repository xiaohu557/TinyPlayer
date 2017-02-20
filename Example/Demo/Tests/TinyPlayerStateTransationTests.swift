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
                        
                        /* Pause at 2.0 secs position and resume after 3.0 sec. */
                        let actionAt2Secs = { [weak videoPlayer] in
                            videoPlayer?.pause()
                            Thread.sleep(forTimeInterval: 3.0)
                            videoPlayer?.play()
                        }
                        let pointActionAt2Secs: PlayerTestObserver.TimepointAction = (timepoint: 2.0,
                                                                                      onTimepoint: actionAt2Secs)
                        spy.registerActionOnTimepoint(pointActionAt2Secs)
                        
                        
                        /* Finish test after 4.0 secs position. */
                        let actionAt4Secs = {
                            done()
                        }
                        let pointActionAt4Secs: PlayerTestObserver.TimepointAction = (timepoint: 4.0,
                                                                                      onTimepoint: actionAt4Secs)
                        spy.registerActionOnTimepoint(pointActionAt4Secs)
                        
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
                        let pointActionAt2Secs: PlayerTestObserver.TimepointAction = (timepoint: 3.0,
                                                                                      onTimepoint: actionAt3Secs)
                        spy.registerActionOnTimepoint(pointActionAt2Secs)

                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 3.0)
                }
                
                it("seek to") {
                    
                }
                
                it("seek forwards") {
                    
                }
                
                it("seek backwards") {
                    
                }
            }
        }
    }
}

