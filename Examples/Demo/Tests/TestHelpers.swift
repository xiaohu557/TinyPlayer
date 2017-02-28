//
//  TestHelpers.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 21/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import TinyPlayer
import Nimble
import XCTest

/**
    This magnifier is used to extend the timeout settings for all tests.
    It's very useful when running tests on a slower maschine or in CI environment.
 */
private let _testTimeoutMagnifier = 1.0

/**
    An alias to the hidden testTimeoutMagnifier variable for code readability.
 */
internal let tm = _testTimeoutMagnifier

/**
    This helper method blocks the main thread and then resumes the execution 
    when the player is reported ready.
 */
public func waitUntilPlayerIsReady(withSpy spy: PlayerTestObserver) {

    waitUntil(timeout: 5.0 * tm) { done -> Void in
        spy.onPlayerReady = {
            done()
        }
    }
}

/**
    A solution posted on https://github.com/Quick/Nimble/issues/216 to workaround
    the Nimble waitUntil(:) timed out issue on TravisCI.
 */
extension XCTestCase {
    
    func waitExpectation(timeout: TimeInterval = 3.0, caller: String = #function, action: (@escaping () -> Void) -> Void) {
        
        let exp = expectation(description: caller)

        action { done in
            exp.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { (error) -> Void in
            if let error = error {
                print("Failed fulfilling expectation: \(error)")
            }
        }
    }
}

