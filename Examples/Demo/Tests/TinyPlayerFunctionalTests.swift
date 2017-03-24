//
//  TinyPlayerFunctionalTests.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 13/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.

import Quick
import Nimble
import AVFoundation
@testable import TinyPlayer


class TinyPlayerFunctionalSpecs: QuickSpec {
    
    override func spec() {
        
        Nimble.AsyncDefaults.Timeout = 10.0 * tm
        
        describe("TinyVideoPlayer") {

            let urlPath = Bundle(for: type(of: self)).path(forResource: "unittest_video", ofType: "mp4")
            let targetUrl = urlPath.flatMap { URL(fileURLWithPath: $0) }
            
            guard let url = targetUrl else {
                XCTFail("Error encountered at loading test video.")
                return
            }

            describe("can be initialized") {
                
                it("with empty parameters") {
                
                    let videoPlayer = TinyVideoPlayer()
                
                    expect(videoPlayer.playbackState).to(equal(TinyPlayerState.unknown))
                    expect(videoPlayer.player).toNot(beNil())
                    expect(videoPlayer.playerItem).to(beNil())
                    expect(videoPlayer.mediaContext).to(beNil())
                    
                    expect(videoPlayer.videoDuration).to(beNil())
                    expect(videoPlayer.playbackPosition).to(beNil())
                    expect(videoPlayer.startPosition) == 0.0
                    expect(videoPlayer.endPosition) == 0.0
                    expect(videoPlayer.playbackProgress).to(beNil())
                    
                    expect(videoPlayer.hidden).to(beFalse())
                }

                it("with a url") {
                    
                    let videoPlayer = TinyVideoPlayer(resourceUrl: url)
                    
                    expect(videoPlayer.playbackState).to(equal(TinyPlayerState.unknown))
                    expect(videoPlayer.player).toNot(beNil())
                    expect(videoPlayer.mediaContext).to(beNil())

                    /* The video which the url points to should be eventually loaded. */
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.ready), timeout: 3.0 * tm)
                    expect(videoPlayer.playerItem).toEventuallyNot(beNil())

                    /* PlaybackPosition and the duration should be correctly initialized. */
                    expect(videoPlayer.videoDuration).toEventually(beGreaterThan(59.99))
                    expect(videoPlayer.playbackPosition).toEventually(beCloseTo(0.0, within: 0.2), timeout: 3.0 * tm)
                    expect(videoPlayer.playbackProgress).toEventually(equal(0.0))
                    expect(videoPlayer.startPosition).toEventually(equal(0.0))
                    
                    /* The endPosition should be set to the whole video length if it's not previously set. */
                    expect(videoPlayer.endPosition).toEventually(equal(videoPlayer.videoDuration))
                    
                    expect(videoPlayer.hidden).to(beFalse())
                }
            }
            
            describe("can unload a loaded media item") {

                    it("when unload") {
                        
                        let videoPlayer = TinyVideoPlayer(resourceUrl: url)
                        let spy = PlayerTestObserver(player: videoPlayer)

                        /* Wait until the player is ready. */
                        waitUntilPlayerIsReady(withSpy: spy)
                        
                        /* Initiate closing procedure and wait until the unloading process is done. */
                        waitUntil(timeout: 5.0 * tm) { done -> Void in
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
            
            describe("can load mediaContext correctly") {

                let mediaContext = MediaContext(videoTitle: "Test Video with start and end settings",
                                                artistName: "TinyPlayer Tester",
                                                startPosition: 9.0,
                                                endPosition: 15.0,
                                                thumbnailImage: UIImage())
                
                it("when specify start and end properties in mediaContext") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    
                    var secondsRecorded = Set<Float>()
                    
                    /* Wait until the player receives the ready signal and play. */
                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        spy.onPlayerReady = {
                            videoPlayer.play()
                        }
                        
                        /* Record secs updated by the player delegate method. */
                        spy.onPlaybackPositionUpdated = { secs, _ in
                            secondsRecorded.insert(floor(secs))
                        }
                        
                        spy.onPlaybackFinished = {
                            done()
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url, mediaContext: mediaContext)
                    }

                    /* Test if the player start at the 0.0 (absolute: 9.0) position,
                       and ends at the 6.0 (absolute: 15.0) position;. */
                    expect(secondsRecorded).to(contain(0.0))
                    expect(secondsRecorded).to(contain(6.0))
                    
                    /* Test the player ends before the 7.0 position. */
                    expect(secondsRecorded).toNot(contain(7.0))
                    expect(videoPlayer.playbackState).toEventually(equal(TinyPlayerState.finished), timeout: 8.0 * tm)
                    
                    /* Start and End should be correctly set. */
                    expect(videoPlayer.startPosition).toEventually(equal(9.0), timeout: 2.0 * tm)
                    expect(videoPlayer.endPosition).toEventually(equal(15.0), timeout: 2.0 * tm)
                }
            }
            
            describe("can create and recycle projection views") {
            
                it("at creation") {

                    let videoPlayer = TinyVideoPlayer()
                    
                    let projectionView = videoPlayer.generateVideoProjectionView()
                    expect(projectionView.hashId).toNot(beNil())
                }
                
                it("at recycling") {
                    
                    
                }
            }
            
            describe("can hide all projection views") {
                
                it("when hide") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    
                    let projectionViewBeforeHide = videoPlayer.generateVideoProjectionView()
                    videoPlayer.hidden = true
                    let projectionViewAfterHide = videoPlayer.generateVideoProjectionView()
                    
                    expect(projectionViewBeforeHide.isHidden) == true
                    expect(projectionViewAfterHide.isHidden) == true
                }
                
                it("when unhide") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    
                    let projectionViewBeforeUnhide = videoPlayer.generateVideoProjectionView()
                    videoPlayer.hidden = false
                    let projectionViewAfterUnhide = videoPlayer.generateVideoProjectionView()
                    
                    expect(projectionViewBeforeUnhide.isHidden) == false
                    expect(projectionViewAfterUnhide.isHidden) == false
                }
            }
            
            describe("can set content fill mode") {
                
                it("when switch between fill modes") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    
                    let projectionView = videoPlayer.generateVideoProjectionView()
                    
                    projectionView.fillMode = .resizeFill
                    expect(projectionView.playerLayer.videoGravity) == AVLayerVideoGravityResize

                    projectionView.fillMode = .resizeAspect
                    expect(projectionView.playerLayer.videoGravity) == AVLayerVideoGravityResizeAspect
                    
                    projectionView.fillMode = .resizeAspectFill
                    expect(projectionView.playerLayer.videoGravity)
                        == AVLayerVideoGravityResizeAspectFill
                }
            }
            
            describe("can call it's delegate at a proper time") {
                
                it("can call delegate when playerState changed") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    var delegateCalled = false

                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        var onceToken = 0x1
                        spy.onPlayerStateChanged = { _ in
                            if onceToken > 0x0 {
                                delegateCalled = true
                                onceToken = 0x0
                                done()
                            }
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(delegateCalled) == true
                }
                
                it("can call delegate when playback position updated") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    var delegateCalled = false
                    
                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        spy.onPlayerReady = {
                            videoPlayer.play()
                        }
                        
                        /* We will use the helper method to test the delegate hit.*/
                        let playbackPositionChangeAction = {
                            delegateCalled = true
                            done()
                        }
                        spy.registerAction(action: playbackPositionChangeAction, onTimepoint: 3.0)
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(delegateCalled) == true
                }
                
                it("can call delegate when seekable range updated") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    var delegateCalled = false
                    
                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        spy.onSeekableRangeUpdated = { _ in
                            delegateCalled = true
                            done()
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(delegateCalled) == true
                }
            
                it("can call delegate when player is ready") {
                    
                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    var delegateCalled = false
                    
                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        spy.onPlayerReady = {
                            delegateCalled = true
                            done()
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(delegateCalled) == true
                }
            
                it("can call delegate when playback finished") {

                    let videoPlayer = TinyVideoPlayer()
                    let spy = PlayerTestObserver(player: videoPlayer)
                    var delegateCalled = false
                    
                    waitUntil(timeout: 10.0 * tm) { done -> Void in
                        
                        spy.onPlaybackFinished = {
                            delegateCalled = true
                            done()
                        }
                        
                        spy.onPlayerReady = {
                            videoPlayer.play()
                            /* Seek to the near ending position. */
                            videoPlayer.seekTo(position: 58.0)
                        }
                        
                        /* Start player initialization now. */
                        videoPlayer.switchResourceUrl(url)
                    }
                    
                    expect(delegateCalled) == true
                }
            }
        }
    }
}
