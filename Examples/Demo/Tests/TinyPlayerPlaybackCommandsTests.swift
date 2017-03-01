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
                
                waitUntil(timeout: 10.0 * tm) { done -> Void in
                    
                    /* Wait until the player receives the ready signal then start playing. */
                    spy.onPlayerReady = {
                        videoPlayer.play()
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
                waitUntil(timeout: 15.0 * tm) { done -> Void in
                    
                    spy.onPlayerReady = {
                        videoPlayer.play()
                    }
                    
                    /* Pause at the 2.0 secs position. */
                    let actionAt2Secs = {
                        videoPlayer.pause()
                        done()
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.paused))
                
                videoPlayer.play()
                expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.playing), timeout: 3.0 * tm)
            }
            
            it("reset playback") {
                
                videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                waitUntil(timeout: 15.0 * tm) { done -> Void in
                    
                    /* Wait until the player receives the ready signal then start playing. */
                    var onceToken = 0x1
                    spy.onPlayerReady = {
                        if onceToken > 0x0 {
                            videoPlayer.play()
                            onceToken = 0x0
                        }
                    }
                    
                    let actionAt3Secs = {
                        videoPlayer.resetPlayback()
                        done()
                    }
                    spy.registerAction(action: actionAt3Secs, onTimepoint: 3.0)
                    
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                expect(videoPlayer.playbackState).to(equal(TinyPlayerState.ready))
                expect(videoPlayer.playbackPosition).to(beCloseTo(0.0, within: 0.2))
            }
            
            it("seek to") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                var secondsRecorded = Set<Float>()

                waitUntil(timeout: 15.0 * tm) { done -> Void in
                    
                    spy.onPlayerReady = {
                        videoPlayer.play()
                    }
                    
                    /* Record secs updated by the player delegate method. */
                    spy.onPlaybackPositionUpdated = { secs, _ in
                        secondsRecorded.insert(floor(secs))
                    }
                    
                    /* Seek to 50.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = {
                        videoPlayer.seekTo(position: 50.0)
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* End sampling at 56.0 secs. */
                    let actionAt56Secs = {
                        videoPlayer.pause()
                        done()
                    }
                    spy.registerAction(action: actionAt56Secs, onTimepoint: 56.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 50.0 (tolerance up to 3.0) secs. */
                expect(secondsRecorded).toNot(contain(46.0))
                expect(secondsRecorded).to(contain(52.0))
                expect(secondsRecorded).to(contain(53.0))
                expect(secondsRecorded).to(contain(54.0))
            }
            
            it("seek forwards") {
                
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                var secondsRecorded = Set<Float>()

                waitUntil(timeout: 15.0 * tm) { done -> Void in
                    
                    spy.onPlayerReady = {
                        videoPlayer.play()
                    }
                    
                    /* Seek fmorward 20.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = {
                        videoPlayer.seekForward(secs: 20.0)
                        return
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Record secs updated by the player delegate method. */
                    spy.onPlaybackPositionUpdated = { secs, _ in
                        secondsRecorded.insert(floor(secs))
                    }
                    
                    /* End sampling at 28.0 secs. */
                    let actionAt28Secs = {
                        videoPlayer.pause()
                        done()
                    }
                    spy.registerAction(action: actionAt28Secs, onTimepoint: 28.0)

                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 22.0 (tolerance up to 3.0) secs. */
                expect(secondsRecorded).toNot(contain(3.0))
                expect(secondsRecorded).toNot(contain(19.0))
                expect(secondsRecorded).to(contain(24.0))
                expect(secondsRecorded).to(contain(25.0))
                expect(secondsRecorded).to(contain(26.0))
            }
            
            it("seek backwards") {
            
                let videoPlayer = TinyVideoPlayer()
                let spy = PlayerTestObserver(player: videoPlayer)
                
                var secondsRecorded = Set<Float>()

                waitUntil(timeout: 15.0) { done -> Void in
                    
                    spy.onPlayerReady = {
                        videoPlayer.play()
                    }
                    
                    /* Seek forward 48.0 secs at the 2.0 secs position. */
                    let actionAt2Secs = {
                        videoPlayer.seekForward(secs: 48.0)
                    }
                    spy.registerAction(action: actionAt2Secs, onTimepoint: 2.0)
                    
                    /* Then seek backward to 5.0 at the 55.0 secs position. */
                    let actionAt55Secs = {
                        videoPlayer.seekBackward(secs: 50.0)
                    }
                    spy.registerAction(action: actionAt55Secs, onTimepoint: 55.0)
                    
                    /* Record secs updated by the player delegate method. */
                    spy.onPlaybackPositionUpdated = { secs, _ in
                        secondsRecorded.insert(floor(secs))
                    }
                    
                    /* End sampling at 10.0 secs. */
                    let actionAt10Secs = {
                        videoPlayer.pause()
                        done()
                    }
                    spy.registerAction(action: actionAt10Secs, onTimepoint: 10.0)
                    
                    /* Start player initialization now. */
                    videoPlayer.switchResourceUrl(url)
                }
                
                /* The player is playing from 5.0 (tolerance up to 3.0) secs. */
                expect(secondsRecorded).toNot(contain(57.0))
                expect(secondsRecorded).toNot(contain(2.0))
                expect(secondsRecorded).to(contain(8.0))
                expect(secondsRecorded).to(contain(9.0))
            }
        }
    }
}
