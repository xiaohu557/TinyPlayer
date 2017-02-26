//
//  ViewController.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import UIKit
import TinyPlayer

class RootViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    
    fileprivate var viewModel: RootViewModel!
    
    fileprivate var videoPlayerVC: VideoPlayerViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        viewModel = RootViewModel(viewDelegate: self)
        
        videoPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController
        
        if let videoPlayerVC = videoPlayerVC {
            
            /* Link video models between the parent view controller and the child view controller. */
            let playerViewModel = VideoPlayerViewModel()
            videoPlayerVC.viewModel = playerViewModel

            viewModel.commandReceiver = playerViewModel
            playerViewModel.viewModelObserver = viewModel
            
            self.addChildViewController(videoPlayerVC)
            self.view.insertSubview(videoPlayerVC.view, belowSubview: startButton)
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
}

// MARK: - Root view update delegate

extension RootViewController: RootViewUpdateDelegate {
    
    internal func updatePlayButtonToMode(buttonMode: PlayButtonDisplayMode) {
        
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

// MARK: - Actions

extension RootViewController {
    
    @IBAction func playButtonTapped(button: UIButton) {
        
        viewModel.playButtonTapped()
    }
    
    @IBAction func seekBackwardsButtonTapped(button: UIButton) {
        
        viewModel.seekBackwardsFor5Secs()
    }
    
    @IBAction func seekForwardsButtonTapped(button: UIButton) {
        
        viewModel.seekForwardsFor5Secs()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        
        viewModel.freePlayerItemResource()
        
        if let vc = videoPlayerVC {
            
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
            videoPlayerVC = nil
        }
    }
    
    @IBAction func freePlayerItemResource(_ sender: Any) {
        
        viewModel.freePlayerItemResource()
    }
}

