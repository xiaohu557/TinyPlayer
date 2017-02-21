//
//  TestHelpers.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 21/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import TinyPlayer
import Nimble

/**
    This helper method blocks the main thread and then resumes the execution 
    when the player is reported ready.
 */
public func waitUntilPlayerIsReady(withSpy spy: PlayerTestObserver) {

    waitUntil(timeout: 5.0) { done -> Void in
        spy.onPlayerReady = {
            done()
        }
    }
}


