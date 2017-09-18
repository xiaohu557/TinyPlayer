//
//  VideoURLRepository.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 18.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
    Here are several video urls that can be used to test the player.
    Feel free to add your own test resource.
 */
fileprivate enum TestRemoteVideoUrls: String {
    case normalVideo = "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"
    case hlsVideo = "http://cdn-fms.rbs.com.br/hls-vod/sample1_1500kbps.f4v.m3u8"
    case hlsVideo2 = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
    case hlsVideo3 = "https://tungsten.aaplimg.com/VOD/bipbop_adv_example_v2/master.m3u8"
    case hlsVideo4 = "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"
}

fileprivate let testLocalVideo = Bundle.main.path(forResource: "unittest_video", ofType: "mp4")

class VideoURLRepository {
    func fetchVideoUrlString() -> String {
        return TestRemoteVideoUrls.normalVideo.rawValue
    }
}
