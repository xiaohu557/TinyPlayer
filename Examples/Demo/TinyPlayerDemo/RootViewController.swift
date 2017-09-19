//
//  ViewController.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import UIKit
import TinyPlayer

/**
    This delegate protocol forms a communication channel to the Router for 
    presenting/dismissing.
 */
protocol RootViewControllerDelegate: class {
    func needToDismissVideoPlayer()
}

/**
    This delegate protocol defines the commands that its parent Router could
    issue.
 */
protocol RootViewControllerPresentable: class {
    func embedPlayer(within viewController: UIViewController)
    func removePlayer(within viewController: UIViewController)
}

final class RootViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    
    var viewModel: (RootViewModelInput & RootViewModelOutput)!
    weak var delegate: RootViewControllerDelegate?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        bind(to: viewModel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func bind(to viewModel: RootViewModelOutput) {
        viewModel.playButtonDisplayMode.observe { [weak self] mode in
            self?.updatePlayButtonToMode(buttonMode: mode)
        }
    }
}

// MARK: - Present and dismiss

extension RootViewController: RootViewControllerPresentable {

    func embedPlayer(within viewController: UIViewController) {
        addChildViewController(viewController)
        view.insertSubview(viewController.view, belowSubview: startButton)
        viewController.didMove(toParentViewController: self)
    }

    func removePlayer(within viewController: UIViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
}

// MARK: - UI updates

extension RootViewController {

    fileprivate func updatePlayButtonToMode(buttonMode: PlayButtonDisplayMode) {
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

// MARK: - UI Actions

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
        delegate?.needToDismissVideoPlayer()
    }
    
    @IBAction func freePlayerItemResource(_ sender: Any) {
        viewModel.freePlayerItemResource()
    }
}

