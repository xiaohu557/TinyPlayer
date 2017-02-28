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

class VideoPlayerViewModel {
    
    internal let tinyPlayer: TinyVideoPlayer
    
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
        
        let mediaContext = MediaContext(videoTitle: "Big Buck Bunny - A MP4 test video.",      /// Use the embedded video metatdata
                                        artistName: "TinyPlayerDemo",
                                        startPosition: 9.0,
                                        endPosition: 15.0,       /// To play to the end of the video
                                        thumbnailImage: UIImage(named: "DemoVideoThumbnail_MP4"))
        
        tinyPlayer = TinyVideoPlayer(resourceUrl: url, mediaContext: mediaContext)
    }
}
