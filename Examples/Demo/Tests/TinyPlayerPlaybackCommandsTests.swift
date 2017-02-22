//
//  TinyPlayerPlaybackCommandsTests.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 22/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import TinyPlayer

class TinyPlayerPlaybackCommandsSpecs: QuickSpec {
    
    override func spec() {
        
        describe("TinyVideoPlayer can respond to player commands:") {
            
            var videoPlayer: TinyVideoPlayer!
            let urlPath = Bundle(for: type(of: self)).path(forResource: "unittest_video", ofType: "mp4")
            let targetUrl = urlPath.flatMap { URL(fileURLWithPath: $0) }
            
            guard let url = targetUrl else {
                XCTFail("Error encountered at loading test video.")
                return
            }
            
            it("play") {
                
                videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                waitUntil(timeout: 10.0) { done -> Void in
                    
                    /* Wait until the player receives the ready signal then start playing. */
                    spy.onPlayerReady = {  [weak videoPlayer] in
                        videoPlayer?.play()
                        done()
                    }
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.playing))
            }
            
            it("pause then resume") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                /* Wait until the player receives the ready signal. */
                waitUntil(timeout: 15.0) { done -> Void in
                    
                    spy.onPlayerReady = {  [weak videoPlayer] in
                        videoPlayer?.play()
                    }
                    
                    /* Pause at the 2.0 secs position. */
                    let actionAt2Secs = { [weak videoPlayer] in
                        videoPlayer?.pause()
                        done()
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.paused))
                
                videoPlayer.play()
                expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.playing), timeout: 3.0)
            }
            
            it("reset playback") {
                
                videoPlayer = TinyVideoPlayer()
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
                    
                    let actionAt3Secs = { [weak videoPlayer] in
                        videoPlayer?.resetPlayback()
                        done()
                    }
                    spy.registerAction(action: actionAt3Secs, onTimepoint: 3.0)
                    
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                expect(videoPlayer.playbackState).to(equal(TinyPlayerState.ready))
            }
            
            it("seek to") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                waitUntil(timeout: 15.0) { done -> Void in
                    
                    spy.onPlayerReady = {  [weak videoPlayer] in
                        videoPlayer?.play()
                    }
                    
                    /* Seek to 30.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = { [weak videoPlayer] in
                        videoPlayer?.seekTo(position: 30.0)
                        done()
                        return
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 30.0 secs. */
                expect(videoPlayer.playbackPosition).toEventuallyNot(beCloseTo(29.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(31.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(32.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(33.0, within: 0.2))
            }
            
            it("seek forwards") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                waitUntil(timeout: 15.0) { done -> Void in
                    
                    spy.onPlayerReady = {  [weak videoPlayer] in
                        videoPlayer?.play()
                    }
                    
                    /* Seek forward 20.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = { [weak videoPlayer] in
                        videoPlayer?.seekForward(secs: 20.0)
                        done()
                        return
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 22.0 secs. */
                expect(videoPlayer.playbackPosition).toEventuallyNot(beCloseTo(3.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(22.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(23.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(24.0, within: 0.2))
            }
            
            it("seek backwards") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                waitUntil(timeout: 15.0) { done -> Void in
                    
                    spy.onPlayerReady = {  [weak videoPlayer] in
                        videoPlayer?.play()
                    }
                    
                    /* Seek forward 48.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = { [weak videoPlayer] in
                        videoPlayer?.seekForward(secs: 48.0)
                        return
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Then seek backward to 6.0 at the 52.0 secs position. */
                    let actionAt52Secs = { [weak videoPlayer] in
                        videoPlayer?.seekBackward(secs: 46.0)
                        done()
                        return
                    }
                    spy.registerAction(action: actionAt52Secs, onTimepoint: 52.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 6.0 secs. */
                expect(videoPlayer.playbackPosition).toEventuallyNot(beCloseTo(52.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(6.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(7.0, within: 0.2))
                expect(videoPlayer.playbackPosition).toEventually(beCloseTo(8.0, within: 0.2))
            }
        }
    }
}
