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

    private let window: UIWindow
    private var storyboard: UIStoryboard?
    fileprivate let rootViewController: RootViewController
    fileprivate var videoPlayerViewController: VideoPlayerViewController?

    init(window: UIWindow) {
        self.window = window

        storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let rootVC = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? RootViewController else {
            fatalError("Failed initiate RootViewController")
        }
        rootViewController = rootVC
        rootViewController.delegate = self
    }

    func load() {
        guard let videoPlayerVC = storyboard?.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController else {
            fatalError("Failed initiate VideoPlayerViewController")
        }
        videoPlayerViewController = videoPlayerVC

        let playerViewModel = VideoPlayerViewModel(repository: VideoURLRepository())
        videoPlayerVC.viewModel = playerViewModel

        let rootViewModel = RootViewModel(playerViewModel: playerViewModel)
        rootViewController.viewModel = rootViewModel

        rootViewController.embedPlayer(within: videoPlayerVC)

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
    }
}

extension AppRouter: RootViewControllerDelegate {

    func needToDismissVideoPlayer() {
        guard let videoPlayerVC = videoPlayerViewController else {
            return
        }
        rootViewController.removePlayer(within: videoPlayerVC)
        videoPlayerViewController = nil
    }
}
