//
//  TinyPlayerFunctionalTests.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 13/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.

import Quick
import Nimble
@testable import TinyPlayer


class TinyPlayerFunctionalSpecs: QuickSpec {
    
    override func spec() {
        
        describe("TinyVideoPlayer") {

            var videoPlayer: TinyVideoPlayer!
            let urlPath = Bundle(for: type(of: self)).path(forResource: "unittest_video", ofType: "mp4")
            let targetUrl = urlPath.flatMap { URL(fileURLWithPath: $0) }

            guard let url = targetUrl else {
                XCTFail("Error encountered at loading test video.")
                return
            }

            describe("can be initialized correctly") {
                
                it("when initialized with empty parameters") {
                
                    videoPlayer = TinyVideoPlayer()
                
                    expect(videoPlayer.playbackState).to(equal(TinyPlayerState.unknown))
                    expect(videoPlayer.player).toNot(beNil())
                    expect(videoPlayer.playerItem).to(beNil())
                    expect(videoPlayer.mediaContext).to(beNil())
                    
                    expect(videoPlayer.videoDuration).to(beNil())
                    expect(videoPlayer.playbackPosition).to(beNil())
                    expect(videoPlayer.startPosition) == 0.0
                    expect(videoPlayer.endPosition) == 0.0
                    expect(videoPlayer.playbackProgress).to(beNil())
                    
                    expect(videoPlayer.playerView).toNot(beNil())
                    expect(videoPlayer.hidden).to(beFalse())
                }

                it("when initialized with a url") {
                    
                    videoPlayer = TinyVideoPlayer(resourceUrl: url)
                    
                    expect(videoPlayer.playbackState).to(equal(TinyPlayerState.unknown))
                    expect(videoPlayer.player).toNot(beNil())
                    expect(videoPlayer.mediaContext).to(beNil())
                    expect(videoPlayer.playerView).toNot(beNil())

                    /* The video which the url points to should be eventually loaded. */
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 3.0)
                    expect(videoPlayer.playerItem).toEventuallyNot(beNil())

                    /* PlaybackPosition and the duration should be correctly initialized. */
                    expect(videoPlayer.videoDuration).toEventually(beGreaterThan(59.99))
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(0.0, within: 0.5), timeout: 3.0)
                    expect(videoPlayer.playbackProgress).toEventually(equal(0.0))
                    expect(videoPlayer.startPosition).toEventually(equal(0.0))
                    
                    /* The endPosition should be set to the whole video length if it's not previously set. */
                    expect(videoPlayer.endPosition).toEventually(equal(videoPlayer.videoDuration))
                    
                    expect(videoPlayer.hidden).to(beFalse())
                }
            }
            
            describe("can unload the loaded media item") {

                    it("when unload") {
                        
                        videoPlayer = TinyVideoPlayer(resourceUrl: url)
                        let spy = PlayerTestObserver(player: videoPlayer)

                        /* Wait until the player is ready. */
                        waitUntil(timeout: 3.0) { done -> Void in
                            spy.onPlayerReady = {
                                done()
                            }
                        }
                        
                        /* Initiate closing procedure and wait until the unloading process is done. */
                        waitUntil(timeout: 5.0) { done -> Void in
                            spy.onPlayerStateChanged = { state in
                                if state == TinyPlayerState.closed {
                                    done()
                                }
                            }

                            videoPlayer.closeCurrentItem()
                        }
                        
                        expect(videoPlayer.videoDuration).to(beNil())
                        expect(videoPlayer.startPosition).to(equal(0.0))
                        expect(videoPlayer.endPosition).to(equal(0.0))
                        expect(videoPlayer.playbackPosition).toEventually(beNil())
                        expect(videoPlayer.playbackProgress).toEventually(beNil())
                        
                        expect(videoPlayer.player).toNot(beNil())
                        expect(videoPlayer.player.currentItem).toEventually(beNil())
                        expect(videoPlayer.playerItem).to(beNil())
                        expect(videoPlayer.mediaContext).to(beNil())
                    }
            }
            
            describe("can calculate start / end position correctly") {

                let mediaContext = MediaContext(videoTitle: "Test Video with start and end settings",
                                                artistName: "TinyPlayer Tester",
                                                startPosition: 9.0,
                                                endPosition: 15.0,
                                                thumbnailImage: nil)
                
                it("when specify start and end properties in mediaContext") {
                    
                    videoPlayer = TinyVideoPlayer(resourceUrl: url, mediaContext: mediaContext)
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    expect(videoPlayer.startPosition).toEventually(equal(9.0), timeout: 2.0)
                    expect(videoPlayer.endPosition).toEventually(equal(15.0), timeout: 2.0)
                    
                    /* Wait until the player receives the ready signal. */
                    waitUntil(timeout: 5.0) { done -> Void in
                        spy.onPlayerReady = {
                            done()
                        }
                    }
                    
                    videoPlayer.play()

                    /* Test if the player start at the 0.0 (absolute: 9.0) position, 
                       and ends at the 6.0 (absolute: 15.0) position;. */
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.playing), timeout: 5.0)
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(0.0, within: 0.01), timeout: 5.0)
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(1.0, within: 0.1), timeout: 5.0)
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(2.0, within: 0.1), timeout: 5.0)
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(6.0, within: 0.01), timeout: 5.0)
                    
                    /* Test the player ends before the 7.0 position. */
                    expect(videoPlayer.playbackPosition).toEventuallyNot(beCloseTo(7.0, within: 0.01), timeout: 8.0)
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.finished), timeout: 8.0)
                }
            }
            
            describe("can responed to player operations:") {
                
                it("play") {
                    
                }
                
                it("pause") {
                    
                }
                
                it("reset playback") {
                    
                    videoPlayer = TinyVideoPlayer(resourceUrl: url)
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    /* Wait until the player receives the ready signal. */
                    waitUntil(timeout: 15.0) { done -> Void in
                        
                        spy.onPlayerReady = {  [weak videoPlayer] in
                            videoPlayer?.play()
                        }
                        
                        spy.onPlaybackPositionUpdated = { [weak videoPlayer] (position, progress) in
                            
                            /* Reset playback at 3.0 secs position. */
                            if fabs(position - 3.0) < 0.01 {
                                videoPlayer?.resetPlayback()
                                done()
                            }
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(videoPlayer.playbackState).to(equal(TinyPlayerState.ready))
                }
                
                it("seek to") {
                    
                }
                
                it("seek forwards") {
                    
                }
                
                it("seek backwards") {
                    
                }
            }
            
            describe("can call it's delegate at a proper time") {
                
                it("can call delegate when playerState changed") {
                    
                }
                
                it("can call delegate when playback position updated") {
                    
                }
                
                it("can call delegate when seekable range updated") {
                    
                }
                
                it("can call delegate when player is ready") {
                    
                }
                
                it("can call delegate when playback finished") {
                    
                }
            }
        }
    }
}
