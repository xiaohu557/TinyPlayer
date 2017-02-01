//
//  ViewController.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import UIKit
import TinyPlayer

class RootViewController: UIViewController, DemoPlayerControlDelegate {

    @IBOutlet weak var startButton: UIButton!
    
    var videoPlayerVC: VideoPlayerViewController?
    
    // MARK: - Lifecycle 
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        videoPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController
        videoPlayerVC?.delegate = self
        
        if let videoPlayerVC = videoPlayerVC {
            self.addChildViewController(videoPlayerVC)
            self.view.insertSubview(videoPlayerVC.view, belowSubview: startButton)
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    @IBAction func playButtonTapped(button: UIButton) {
        
        videoPlayerVC?.playButtonTapped()
    }
    
    @IBAction func seekBackwardsButtonTapped(button: UIButton) {
        
        videoPlayerVC?.seekBackwardsFor5Secs()
    }
    
    @IBAction func seekForwardsButtonTapped(button: UIButton) {
        
        videoPlayerVC?.seekForwardsFor5Secs()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        
        videoPlayerVC?.freePlayerItemResource()
        
        if let vc = videoPlayerVC {
            
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
            videoPlayerVC = nil
        }
    }
    
    @IBAction func freePlayerItemResource(_ sender: Any) {
        
        videoPlayerVC?.freePlayerItemResource()
    }
    
    // MARK: - DemoPlayerControlDelegate

    func demoPlayerIsReadyToStartPlayingFromBeginning(isReady: Bool) {
        
        updatePlayButtonToMode(buttonMode: .playButton)
    }
    
    func demoPlayerHasUpdatedState(state: TinyPlayerState) {
        
        if state == .playing {
            updatePlayButtonToMode(buttonMode: .pauseButton)
            
        } else if state == .paused {
            updatePlayButtonToMode(buttonMode: .playButton)
        }
    }

    // MARK: - UI Updates
    
    var playButtonDisplayMode: PlayButtonDisplayMode = .playButton
    
    fileprivate func updatePlayButtonToMode(buttonMode: PlayButtonDisplayMode) {
        
        guard playButtonDisplayMode != buttonMode else {
            return
        }
        
        playButtonDisplayMode = buttonMode
        
        let designatedAlpha: CGFloat
        var buttonTitle: String?
        
        switch buttonMode {
        case .playButton:
            designatedAlpha = 1.0
            buttonTitle = "Play"
        case .pauseButton:
            designatedAlpha = 1.0
            buttonTitle = "Pause"
        case .hidden:
            designatedAlpha = 0.0
        }
        
        UIView.transition(with: self.startButton,
                          duration: 0.7,
                          options: .transitionCrossDissolve,
                          animations: {
                            
                              self.startButton.alpha = designatedAlpha
                            
                              if let title = buttonTitle {
                                  self.startButton.setTitle(title, for: .normal)
                              }
                            
                          }, completion: nil)
    }
    
}

/**
    Display modes of the play/pause button.
 */
enum PlayButtonDisplayMode {
    case playButton
    case pauseButton
    case hidden
}

/**
    Callbacks from a VideoPlayerViewController class instance.
 */
protocol DemoPlayerControlDelegate: class {
    
    func demoPlayerIsReadyToStartPlayingFromBeginning(isReady: Bool)
    func demoPlayerHasUpdatedState(state: TinyPlayerState)
}
