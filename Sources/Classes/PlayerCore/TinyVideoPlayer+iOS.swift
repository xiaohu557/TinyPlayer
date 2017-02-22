//
//  TinyVideoPlayer+iOS.swift
//  Pods
//
//  Created by Kevin Chen on 31/01/2017.
//
//

#if os(iOS)

import Foundation

/**
     Support external media route management.
     - Note: This extension is made for iOS!
 */
extension TinyVideoPlayer: MediaRouteManagerDelegate {
    
    public var mediaRouteManager: MediaRouteManager {
        get {
            return MediaRouteManager.sharedManager
        }
    }
    
    public func mediaRouteStateHasChangedTo(state: MediaRouteState) {
        infoLog("Media route state has been updated to: \(state)")
    }
    
    public func wirelessRouteAvailabilityChanged(available: Bool) {
        infoLog("Wireless route availability changed: \(available)")
    }
}

#endif
