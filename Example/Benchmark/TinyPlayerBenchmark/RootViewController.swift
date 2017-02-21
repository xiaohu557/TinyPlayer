//
//  ViewController.swift
//  TinyPlayerBenchmark
//
//  Created by Kevin Chen on 06/01/2017.
//  Copyright © 2017 Xi Chen. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    @IBOutlet var addMoreButton: UIButton!
    
    /**
        The density tier of on-screen players.
        It can also be understandable as the index of the playerDensityTierList array.
     */
    fileprivate var playerDensityTier: Int = 0
    
    /**
        The pre-defined count number of on-screen videoPlayers that matches the density tier.
     */
    private let playerDensityTierList: Array<Int> = [0, 1, 2, 4, 6, 8, 9, 12, 16]
    
    /**
        A in-memory reference store for all on-screen players.
     */
    private var videoPlayerViewInstances: Array<UIViewController> = []

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        increasePlayerCountOnScreenToMatchTier(1)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    /**
        Add more video players on screen to match the specified density tier.
     */
    func increasePlayerCountOnScreenToMatchTier(_ newTier: Int) {
        
        guard playerDensityTier < newTier && newTier < playerDensityTierList.count else {
            return
        }
        
        let playerCount = playerDensityTierList[playerDensityTier]
        let nextPlayerCount = playerDensityTierList[newTier]
        
        playerDensityTier = newTier
            
        for _ in 0 ..< nextPlayerCount - playerCount {
        
            let videoPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayerViewController") as! VideoPlayerViewController
        
            self.addChildViewController(videoPlayerVC)
            self.view.insertSubview(videoPlayerVC.view, belowSubview: addMoreButton)
            videoPlayerVC.view.frame = CGRect(x: 0.0,
                                              y: 0.0,
                                              width: 10.0,
                                              height: 10.0)
            videoPlayerVC.view.alpha = 0.0
            
            videoPlayerViewInstances.append(videoPlayerVC)
        }
        
        layoutOnScreenPlayers()
    }
    
    /**
        Remove and deallocate video players on screen to match the specified density tier.
     */
    func decreasePlayerCountOnScreenToMatchTier(_ newTier: Int) {
        
        guard playerDensityTier > newTier && newTier >= 0 else {
            return
        }
        
        let playerCount = playerDensityTierList[playerDensityTier]
        let nextPlayerCount = playerDensityTierList[newTier]
        
        playerDensityTier = newTier
        
        for _ in 0 ..< abs(nextPlayerCount - playerCount) {
            
            if let lastVideoPlayerVC = videoPlayerViewInstances.last as? VideoPlayerViewController {
                
                lastVideoPlayerVC.freePlayerItemResource()
                
                if let _ = lastVideoPlayerVC.view.superview {
                    lastVideoPlayerVC.view.removeFromSuperview()
                }
                
                if let _ = lastVideoPlayerVC.parent {
                    lastVideoPlayerVC.removeFromParentViewController()
                }
                
                videoPlayerViewInstances.removeLast()
            }
        }
        
        layoutOnScreenPlayers()
    }
    
    /**
        Re-calculate and animate player frames according to the on-screen player count.
     */
    private func layoutOnScreenPlayers() {
        
        let playerCount = playerDensityTierList[playerDensityTier]
        
        guard playerCount > 0 else {
            return
        }
        
        let columnCount = Int(floor(sqrt(Double(playerCount))))
        let rowCount = playerCount / columnCount
        
        let screenHeight = self.view.bounds.height
        let screenWidth = self.view.bounds.width
        let playerWidth = screenWidth / CGFloat(columnCount)
        let playerHeight = screenHeight / CGFloat(rowCount)
        
        /* Start layout players one by one. */

        for (index, playerVC) in videoPlayerViewInstances.enumerated() {

            let playerColumn = index % columnCount
            let playerRow = index / columnCount

            let x: CGFloat = CGFloat(playerColumn) * playerWidth
            let y: CGFloat = CGFloat(playerRow) * playerHeight
            
            UIView.animate(withDuration: 0.4, animations: {
                
                playerVC.view.frame = CGRect(x: x, y: y, width: playerWidth, height: playerHeight)
                playerVC.view.alpha = 1.0
            })
        }
    }
}

// MARK: - Interactions

extension RootViewController {
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        
        increasePlayerCountOnScreenToMatchTier(playerDensityTier + 1)
    }
    
    @IBAction func minusButtonTapped(_ sender: Any) {
        
        decreasePlayerCountOnScreenToMatchTier(playerDensityTier - 1)
    }
}


