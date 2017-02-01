//
//  AirplayManager.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 19/01/2017.
//  Copyright © 2017 Xi Chen. All rights reserved.
//

#if os(iOS)

import AVFoundation
import MediaPlayer

public enum MediaRouteState {
    case airplayPlayback
    case airplayPlaybackMirroring
    case routeOff
}

public class MediaRouteManager: TinyLogging {
    
    public static let sharedManager = MediaRouteManager()
    
    public weak var delegate: MediaRouteManagerDelegate?
    
    public var onStateChangeClosure: ((MediaRouteState) -> Void)?
    
    public var mediaRouteState: MediaRouteState = .routeOff {
        didSet {
            delegate?.mediaRouteStateHasChangedTo(state: self.mediaRouteState)
        }
    }
    
    public var loggingLevel: TinyLoggingLevel = .info
    
    private let volumnView = MPVolumeView(frame: .zero)
  
    private init() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.MPVolumeViewWirelessRouteActiveDidChange,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { [unowned self] notification in
                                                
                                                    var newState: MediaRouteState = self.mediaRouteState
                                                
                                                    if self.isAirPlayConnected {
                                                        
                                                        if self.isAirPlayPlaybackActive {
                                                            
                                                            newState = .airplayPlayback
                                                            self.verboseLog("Airplay playback activated!")
                                                            
                                                        } else if self.isAirplayMirroringActive {
                                                            
                                                            newState = .airplayPlaybackMirroring
                                                            self.verboseLog("Airplay playback mirroring activated!")
                                                        }

                                                    } else {
                                                        newState = .routeOff
                                                        self.verboseLog("External playback deactivated!")
                                                    }
                                                
                                                    self.delegate?.mediaRouteStateHasChangedTo(state: newState)
                                               })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.MPVolumeViewWirelessRoutesAvailableDidChange,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { [unowned self] notification in
                                                
                                                    self.delegate?.wirelessRouteAvailabilityChanged(available: self.volumnView.areWirelessRoutesAvailable)
                                               })
    }
  
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var isAirPlayConnected: Bool {
        
        return volumnView.isWirelessRouteActive
    }

    /** 
        This read-only variable tells wether the current media playback is routed wirelessly via mirroring mode.
     */
    var isAirplayMirroringActive: Bool {
        
        if isAirPlayConnected {
            
            let screens = UIScreen.screens
            if screens.count > 1 {
                return screens[1].mirrored == UIScreen.main
            }
        }
        
        return false
    }

    /**
        This read-only variable tells wether the current video stream is routed to an Airplay capable device.
     */
    var isAirPlayPlaybackActive: Bool {
        
        return isAirPlayConnected && !isAirplayMirroringActive
    }

    /**
        This read-only variable tells wether the current video stream is routed via a HDMI cable.
     */
    var isWiredPlaybackActive: Bool {
        
        if isAirPlayPlaybackActive {
            return false
        }
        
        let screens = UIScreen.screens
        if screens.count > 1 {
            return screens[1].mirrored == UIScreen.main
        }
        
        return false
    }
}

public protocol MediaRouteManagerDelegate: class {
    
    var mediaRouteManager: MediaRouteManager { get }
    
    /**
        This delegate method is get called whenever the media route state is changed.
        This can be a consequence of switching on/off Airplay or connect the device to a external display with HDMI cable.
     */
    func mediaRouteStateHasChangedTo(state: MediaRouteState)
    
    func wirelessRouteAvailabilityChanged(available: Bool)
}

#endif
