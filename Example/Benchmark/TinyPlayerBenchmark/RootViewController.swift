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
    
    var videoPlayerArray: Array<VideoPlayerViewController> = []
    
    /**
        This matches the tier corresponds to the tierCountList property. 
        It can also be understandable as the index of that array.
     */
    var playerCountTier: Int = 0
    
    /**
        The pre-defined tiers of the number of on-screen videoPlayers.
     */
    let playerCountTierList: Array<Int> = [0, 1, 2, 4, 6, 8, 9, 12, 16]
    
    var videoPlayerViewInstances: Array<UIViewController> = []

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        addMorePlayersOnScreenToMatchTier(1)
    }
    
    func addMorePlayersOnScreenToMatchTier(_ newTier: Int) {
        
        guard playerCountTier < newTier && newTier < playerCountTierList.count else {
            return
        }
        
        let playerCount = playerCountTierList[playerCountTier]
        let nextPlayerCount = playerCountTierList[newTier]
        
        playerCountTier = newTier
            
        for _ in 0 ..< nextPlayerCount - playerCount {
        
            let videoPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayerViewController") as! VideoPlayerViewController
        
            self.addChildViewController(videoPlayerVC)
            self.view.insertSubview(videoPlayerVC.view, belowSubview: addMoreButton)
            videoPlayerVC.view.frame = CGRect(x: 0.0,
                                              y: 0.0,
                                              width: 10.0,
                                              height: 10.0)
            
            videoPlayerViewInstances.append(videoPlayerVC)
        }
        
        layoutOnScreenPlayers()
    }
    
    func reducePlayerCountOnScreenForTier(_ newTier: Int) {
        
        guard playerCountTier > newTier && newTier >= 0 else {
            return
        }
        
        let playerCount = playerCountTierList[playerCountTier]
        let nextPlayerCount = playerCountTierList[newTier]
        
        playerCountTier = newTier
        
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
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func layoutOnScreenPlayers() {
        
        let playerCount = playerCountTierList[playerCountTier]
        
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
            })
        }
    }
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        
        addMorePlayersOnScreenToMatchTier(playerCountTier + 1)
    }
    
    @IBAction func minusButtonTapped(_ sender: Any) {
        
        reducePlayerCountOnScreenForTier(playerCountTier - 1)
    }
}


