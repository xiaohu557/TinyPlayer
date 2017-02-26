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

class RootViewModel {
    
    internal weak var viewDelegate: RootViewUpdateDelegate?
    
    internal var playButtonDisplayMode: PlayButtonDisplayMode = .playButton
    
    /* 
        A command receiver will take commands from this view model.
     */
    internal weak var commandReceiver: RootViewModelCommandReceiver?
    
    init(viewDelegate: RootViewUpdateDelegate) {
        
        self.viewDelegate = viewDelegate
    }
    
    /* UI update logic. */
    
    func needToUpdatePlayButtonMode(_ buttonMode: PlayButtonDisplayMode) {
        
        guard playButtonDisplayMode != buttonMode else {
            return
        }
        
        playButtonDisplayMode = buttonMode
        
        viewDelegate?.updatePlayButtonToMode(buttonMode: playButtonDisplayMode)
    }
}

// MARK: - Handle commands received from the correspond view controller.

extension RootViewModel {
    
    func playButtonTapped() {
        
        commandReceiver?.playButtonTapped()
    }
    
    func seekBackwardsFor5Secs() {
        
        commandReceiver?.seekBackwardsFor5Secs()
    }
    
    func seekForwardsFor5Secs() {
        
        commandReceiver?.seekForwardsFor5Secs()
    }
    
    func freePlayerItemResource() {
        
        commandReceiver?.freePlayerItemResource()
    }
}

// MARK: - PlayerViewModelObserver

extension RootViewModel: PlayerViewModelObserver {
    
    func demoPlayerIsReadyToStartPlayingFromBeginning(isReady: Bool) {
        
       needToUpdatePlayButtonMode(.playButton)
    }
    
    func demoPlayerHasUpdatedState(state: TinyPlayerState) {
        
        if state == .playing {
            needToUpdatePlayButtonMode(.pauseButton)
            
        } else if state == .paused {
            needToUpdatePlayButtonMode(.playButton)
        }
    }
}

// MARK: - Additional definitions

/**
    Display modes of the play/pause button.
 */
internal enum PlayButtonDisplayMode {
    case playButton
    case pauseButton
    case hidden
}

// MARK: - RootViewUpdateDelegate definition

internal protocol RootViewUpdateDelegate: class {
    
    func updatePlayButtonToMode(buttonMode: PlayButtonDisplayMode)
}

// MARK: - RootViewModelCommandReceiver definition

/**
    This protocol defines all the commands that a CommandReceiver can respond.
    In our case, a CommandReceiver will be a VideoPlayerViewModel instance.
 */
internal protocol RootViewModelCommandReceiver: class {
    
    func playButtonTapped()
    func seekBackwardsFor5Secs()
    func seekForwardsFor5Secs()
    func freePlayerItemResource()
}
