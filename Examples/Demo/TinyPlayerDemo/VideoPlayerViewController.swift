//
//  VideoPlayerViewController.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 06/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import Foundation
import UIKit
import TinyPlayer

class VideoPlayerViewController: UIViewController, TinyLogging {
    
    /* Required property from the TinyLogging protocol. */
    var loggingLevel: TinyLoggingLevel = .info

    internal var viewModel: VideoPlayerViewModel!
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
        
        infoLog("Player view controller is dealloced.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.view.addSubview(viewModel.tinyPlayer.playerView)
        
        /* 
            Setup player view constrains. 
         */
        viewModel.tinyPlayer.playerView.translatesAutoresizingMaskIntoConstraints = false
        
        viewModel.tinyPlayer.playerView.topAnchor
            .constraint(equalTo: self.view.topAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.bottomAnchor
            .constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.leftAnchor
            .constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
        viewModel.tinyPlayer.playerView.rightAnchor
            .constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
    }
}
