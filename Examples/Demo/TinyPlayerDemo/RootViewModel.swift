//
//  RootViewModel.swift
//  TinyPlayerDemo
//
//  Created by Xi Chen on 2017/2/26.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import TinyPlayer

class RootViewModel: RootViewModelOutput {
    
    var playButtonDisplayMode = Observable<PlayButtonDisplayMode>(.playButton)
    
    /**
        A command receiver (video player) will take commands from this view model.
     */
    var commandReceiver: VideoPlayerViewModelInput & PlayerViewModelDelegatable

    /**
        UI update logic. 
     */
    fileprivate func needToUpdatePlayButtonMode(_ buttonMode: PlayButtonDisplayMode) {
        guard playButtonDisplayMode.value != buttonMode else {
            return
        }
        playButtonDisplayMode.next(buttonMode)
    }

    init(playerViewModel: VideoPlayerViewModelInput & PlayerViewModelDelegatable) {
        self.commandReceiver = playerViewModel
        commandReceiver.delegate = self
    }
}

// MARK: - Handle commands received from the correspond view controller.

extension RootViewModel: RootViewModelInput {
    
    func playButtonTapped() {
        commandReceiver.playButtonTapped()
    }
    
    func seekBackwardsFor5Secs() {
        commandReceiver.seekBackwardsFor5Secs()
    }
    
    func seekForwardsFor5Secs() {
        commandReceiver.seekForwardsFor5Secs()
    }
    
    func freePlayerItemResource() {
        commandReceiver.freePlayerItemResource()
    }
}

// MARK: - PlayerViewModelDelegate

extension RootViewModel: PlayerViewModelDelegate {
    
    func demoPlayerIsReadyToStartPlayingFromBeginning(isReady: Bool) {
       needToUpdatePlayButtonMode(.playButton)
    }
    
    func demoPlayerHasUpdatedState(state: TinyPlayerState) {
        switch state {
        case .playing:
            needToUpdatePlayButtonMode(.pauseButton)
        case .paused:
            needToUpdatePlayButtonMode(.playButton)
        default:
            break
        }
    }
}

// MARK: - Definitions

/**
    Display modes of the play/pause button.
 */
enum PlayButtonDisplayMode {
    case playButton
    case pauseButton
    case hidden
}

/**
    This protocol defines the operations that the view model can take as inputs.
 */
protocol RootViewModelInput: class {
    func playButtonTapped()
    func seekBackwardsFor5Secs()
    func seekForwardsFor5Secs()
    func freePlayerItemResource()
}

/**
    This protocol defines the inferfaces that the view model exposes to update the UI.
 */
protocol RootViewModelOutput: class {
    var playButtonDisplayMode: Observable<PlayButtonDisplayMode> { get }
}
