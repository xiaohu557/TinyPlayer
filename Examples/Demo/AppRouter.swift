//
//  AppRouter.swift
//  TinyPlayerDemo
//
//  Created by Xi Chen on 14.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

final class AppRouter {

    fileprivate let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func load() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootViewController") as? RootViewController else {
            return
        }

        guard let videoPlayerVC = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController else {
            return
        }

        let playerViewModel = VideoPlayerViewModel()
        videoPlayerVC.viewModel = playerViewModel

        let rootViewModel = RootViewModel(playerViewModel: playerViewModel)
        rootViewController.viewModel = rootViewModel

        rootViewController.embedPlayer(with: videoPlayerVC)

        window.rootViewController = rootViewController
    }
}
