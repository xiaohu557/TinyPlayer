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
    A group of testing videos found in Apple's trailer repository.
    Only for testing! Please don't use them for commercial purpose.
 */
private let testVideoUrls = [
                     "http://movietrailers.apple.com/movies/independent/patriots-day/patriots-day-featurette_h720p.mov",
                     "http://movietrailers.apple.com/movies/paramount/monstertrucks/monster-trucks-trailer-2_h720p.mov",
                     "http://movietrailers.apple.com/movies/paramount/rings/rings-trailer-2_h720p.mov",
                     "http://movietrailers.apple.com/movies/disney/cars-3/cars-3-character-reveal-cruz_h720p.mov",
                     "http://movietrailers.apple.com/movies/independent/the-book-of-love/the-book-of-love-clip-1_h720p.mov",
                     "http://movietrailers.apple.com/movies/sony_pictures/t2trainspotting/t2-trainspotting-character-vignette-renton_h720p.mov",
                     "http://movietrailers.apple.com/movies/independent/20th-century-women/20th-century-women-featurette-1_h720p.mov"
                    ]

struct VideoPlayerViewModel {
    
    internal let tinyPlayer: TinyVideoPlayer

    init() {
        
        let randomIndex = Int(arc4random() % UInt32(testVideoUrls.count))
        
        let videoUrl = URL(string: testVideoUrls[randomIndex])
        
        /*
            For each test video item, we at a seek operation to a random position 
            to increase the performance impact.
         */
        let mediaContext = MediaContext(videoTitle: "This is a test video.",
                                         artistName: "TinyPlayerBenchmark",
                                         startPosition: Float(arc4random()%10),
                                         endPosition: 0.0,       /// Play to end of the video
                                         thumbnailImage: nil)
        
        tinyPlayer = TinyVideoPlayer(resourceUrl: videoUrl!, mediaContext: mediaContext)
    }
}
