//
//  TinyVideoPlayer.swift
//  Leanr
//
//  Created by Kevin Chen on 29/11/2016.
//  Copyright © 2016 Magic Internet. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

/**
    This struct defines constants that controls the player's interactive behavior.
    Feel free to change these values to best suit your needs.
 */
public struct TinyVideoPlayerConstants {
    
    /** 
        This defines how far the player will seek forwards/backwards when user interacts with buttons in command center. 
     */
    static let seekingInterval: Float = 10.0    // in secs
    
    /** 
        This defines how frequently the playing time will be updated. 
     */
    static let timeObservationInterval: Float = 0.01    // in secs
    
    /** 
        This defines how long the player should buffer the content before start playing. 
     */
    static let bufferSize: Float = 6.0      // in secs
}

public class TinyVideoPlayer: NSObject, TinyPlayer, TinyLogging {
  
    /* Feel free to set this value to .none to disable the logging behavior of TinyPlayer. */
    public var loggingLevel: TinyLoggingLevel = .info
    
    public weak var delegate: TinyPlayerDelegate?
    internal var player: AVPlayer
    internal var playerItem: AVPlayerItem?
    internal var internalUrl: URL?

    /**
        After the playerItem initialization, this value will match the one set in the MediaContext.
        If not present in the MediaContext, it will be set to 0.0.
     */
    internal var startPosition: Float = 0.0

    /**
        After the playerItem initialization, this value will match the one set in the MediaContext.
        If not present in the MediaContext, it will be set to the total duration of the video.
     */
    internal var endPosition: Float = 0.0

    /**
        The mediaContext object that are used to store context information for the loaded playerItem.
     */
    public var mediaContext: MediaContext? {
        
        didSet {
            
            if let start = mediaContext?.startPosition {
                self.startPosition = start
            }
            
            if let end = mediaContext?.endPosition {
                self.endPosition = end
            }

            updateCommandCenterInfo()
        }
    }

    /**
        The duration of the current loaded playerItem. 
        It's calculated based on the startPosition and endPosition properties.
     */
    public var videoDuration: Float? {
        
        didSet {
            updateCommandCenterInfo()
        }
    }

    internal var currentVideoPlaybackEnded: Bool = false
    
    /**
        Indicates the elapsed playback time of the current playing item.
        - Note: The playbackPosition is a relative value.
        It's calculated in consideration of the startPosition and endPosition properties.
     */
    public var playbackPosition: Float? {
        
        didSet {
            
            guard let position = playbackPosition, position != oldValue else {
                return
            }
            
            guard let progress = playbackProgress else {
                return
            }
            
            delegate?.player(self, didUpdatePlaybackPosition: position, playbackProgress: progress)
            
            /* Set the current video to be completed if it matches the 'endPosition' tag.*/
            if !self.currentVideoPlaybackEnded && position >= self.endPosition - self.startPosition {
                
                self.currentVideoPlaybackEnded = true

                self.playerItemDidPlayToEndTime(nil)

            }
        }
    }

    /**
        Indicates the playback progress in terms of the whole video duration.
        - Note: The playbackProgess is a relative value.
          It's calculated in consideration of the startPosition and endPosition properties.
     */
    public var playbackProgress: Float? {
        
        guard let duration = videoDuration else {
            return nil
        }
        
        guard let position = playbackPosition, position >= 0 else {
            return 0.0
        }
        
        return position / duration
    }

    public var bufferProgress: Float?
    
    public var enableAirplayMediaRoute: Bool {
        didSet {
            player.allowsExternalPlayback = enableAirplayMediaRoute
        }
    }

    /**
        Activate this switch will force the player to filter out less meaningful state transitions.
     
        - When this toggle is deactivated, in a player's lifecycle, the normal state transition chain woule look like:
            unknown -> paused -> ready -> playing -> paused -> finished
        - When this toggle is activated, the redundant(sometimes unnecessary) paused state will be filtered out:
            unknown -> ready -> playing -> finished
     
        Feel free to set this toggle on your own preference.
     */
    public var isPrettyfyingPauseStateTransation: Bool = true

    public var playbackState: TinyPlayerState

    static let assetKeysRequiredForOptimizedPlayback = [
        "playable",
        "hasProtectedContent",
        "duration"
    ]

    /**
       Each TinyVideoPlayer owns a playerView for content drawing.
       This view can be inserted directly into your UI presentation hierachy.
     */
    public let playerView: TinyVideoPlayerView = TinyVideoPlayerView()
    
    /**
        Use the hidden property to control whether to show the playing content or not.
     */
    public var hidden: Bool = false {
        
        didSet {
            if hidden {
                playerView.isHidden = true
                
            } else {
                playerView.isHidden = false
            }
        }
    }

    // MAKR: - Lifecycle

    public override init() {
        
        self.player = AVPlayer()
        
        self.playbackState = .unknown
        
        self.enableAirplayMediaRoute = true

        super.init()
        
        attachObserversOn(player: self.player)
        
        /* Command center configuration. */
        setupCommandCenterTriggers()
        
        #if os(iOS)
        mediaRouteManager.delegate = self
        #endif
    }
    
    /**
        This is a convenience init method for quickly loading a media at the initialization phase.
     */
    convenience public init(resourceUrl: URL, mediaContext: MediaContext? = nil) {

        self.init()

        switchResourceUrl(resourceUrl, mediaContext: mediaContext)
    }

    deinit {

        player.pause()
        
        detachTimeObserver()

        if let currentPlayerItem = playerItem {
            detachObserversFrom(playerItem: currentPlayerItem)
        }
        
        player.replaceCurrentItem(with: nil)

        detachObserversFrom(player: player)

        playerView.player = nil
    }

    /**
        Call this method triggers the initialization process of the media item at the specific url.
        
        - parameter resourceUrl: The url to the media resource you wish TinyVideoPlayer to play.
        - parameter mediaContext: Specify additional metadata for the to be loaded media item.
     
        Use this method to switch content for TinyVideoPlayer.
     */
    public func switchResourceUrl(_ resourceUrl: URL, mediaContext: MediaContext? = nil) {
        
        if resourceUrl != internalUrl {
            
            internalUrl = resourceUrl
            
            self.mediaContext = mediaContext

            closeCurrentItem()

            updatePlaybackState(.unknown)
            
            let asset = AVURLAsset(url: resourceUrl)
            asset.loadValuesAsynchronously(forKeys: TinyVideoPlayer.assetKeysRequiredForOptimizedPlayback) {
                DispatchQueue.main.async {
                    self.setupPlayerWithLoadedAsset(asset: asset)
                }
            }
            
            infoLog("TinyVideoPlayer has started to load media at url: \(resourceUrl.absoluteString)")
        }
    }

    fileprivate func setupPlayerWithLoadedAsset(asset: AVAsset) {
        
        /* Load AVAsset keys asynchronized to optimizing the initial loading behavior (not block the UI). */
        var shouldCancel: Bool = false
        
        for key in TinyVideoPlayer.assetKeysRequiredForOptimizedPlayback {
            var error: NSError?
            let keyStatus = asset.statusOfValue(forKey: key, error: &error)
            if keyStatus == AVKeyValueStatus.failed {
                errorLog("[TinyPlayer][Error]: AVAsset loading key \(key) failed: \(error)")
                shouldCancel = true
            }
        }
        
        if shouldCancel {
            failedToPrepareAssetForPlayback(error: TinyVideoPlayerError.assetDownloadFailed)
            return
        }
        
        /* Early exit. */
        if (!asset.isPlayable) {
            failedToPrepareAssetForPlayback(error: TinyVideoPlayerError.assetNotPlayable)
            return
        }
        
        /* Safely remove the old AVPlayerItem, then create a new Instance based on the successfully loaded AVAsset. */
        if let currentPlayerItem = playerItem {
            detachObserversFrom(playerItem: currentPlayerItem)
            detachTimeObserver()
        }
        
        playerItem = AVPlayerItem(asset: asset)

        /* iOS 10 optimization for preventing stall at the beginning. */
        if #available(iOS 10.0, tvOS 10.0, *) {
            playerItem!.preferredForwardBufferDuration = TimeInterval(TinyVideoPlayerConstants.bufferSize)
        }
        
        /* Re-attach necessary obsevers. */
        attachObserversOn(playerItem: playerItem!)
        
        /* Attach an AVPlayerItem to player immediately triggers the media preparation, KVO works after here. */
        bufferProgress = 0.0
        player.replaceCurrentItem(with: playerItem)
    }
  
    // MARK: - Key-Value Obsevation & Notification Center Obsevation
  
    fileprivate var TinyVideoPlayerAVPlayerItemObservationContext = 0
    fileprivate var TinyVideoPlayerAVPlayerObservationContext = 0

    fileprivate func detachObserversFrom(playerItem: AVPlayerItem) {
        
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackBufferEmpty))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackLikelyToKeepUp))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
     
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: playerItem)
    }

    fileprivate func attachObserversOn(playerItem: AVPlayerItem) {
        
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerItemObservationContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerItemObservationContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackBufferEmpty),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerItemObservationContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackLikelyToKeepUp),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerItemObservationContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerItemObservationContext)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidPlayToEndTime(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemPlaybackStalled(_:)),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: playerItem)
    }

    fileprivate func detachObserversFrom(player: AVPlayer) {
        
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem))
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            /*
                Changing between the playing, paused, waitingToPlayAtSpecifiedRate states.
                Working when the 'automaticallyWaitsToMinimizeStalling' property is enabled.
             */
            player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
            
            /*
                The reason of AVPlayer's waiting, when the timeControlStatus property changes to the
                .waitingToPlayAtSpecifiedRate state.
             */
            player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.reasonForWaitingToPlay))
        }
    }

    fileprivate func attachObserversOn(player: AVPlayer) {
        
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate),
                           options: [.new],
                           context: &TinyVideoPlayerAVPlayerObservationContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem),
                           options: [.old, .new],
                           context: &TinyVideoPlayerAVPlayerObservationContext)
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerObservationContext)
            player.addObserver(self, forKeyPath: #keyPath(AVPlayer.reasonForWaitingToPlay),
                               options: [.new],
                               context: &TinyVideoPlayerAVPlayerObservationContext)
        }
    }

    // MAKR: - Timer Observation
    
    var timeObservationToken: Any?
    
    fileprivate func attachTimeObserver() {
        
        let interval = CMTimeMakeWithSeconds(Float64(TinyVideoPlayerConstants.timeObservationInterval), CMTimeScale(NSEC_PER_SEC))
        
        if !CMTIME_IS_VALID(interval) {
            return
        }
        
        timeObservationToken = player.addPeriodicTimeObserver(forInterval: interval,
                                       queue: nil) { [weak self] cmTime in
                                        
                                        let timeElapsed = Float(CMTimeGetSeconds(cmTime))
                                        
                                        if let start = self?.startPosition,
                                            let end = self?.endPosition {
                                            self?.playbackPosition = fmin(fmax(timeElapsed - start, 0.0), end - start)
                                        }
        }
    }

    fileprivate func detachTimeObserver() {
        
        guard let observationToken = timeObservationToken else {
            return
        }
        
        player.removeTimeObserver(observationToken)
        
        timeObservationToken = nil
    }

    // MAKR: - KVO callbacks
    
    override public func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        guard context == &TinyVideoPlayerAVPlayerObservationContext ||
            context == &TinyVideoPlayerAVPlayerItemObservationContext else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
        }
        
        if context == &TinyVideoPlayerAVPlayerObservationContext {
            
            if #available(iOS 10.0, tvOS 10.0, *) {
                /*
                    Using the new timeControlStatus in iOS/tvOS 10 is a more effective way of tracking player status.
                 */
                if keyPath == #keyPath(AVPlayer.timeControlStatus) {
                
                    guard let player = object as? AVPlayer else {
                        return
                    }
                    
                    switch player.timeControlStatus {
                        
                    case .paused:
                        if isPrettyfyingPauseStateTransation {
                            updatePauseStateWithFilteringOn()
                        } else {
                            updatePlaybackState(.paused)
                        }
                        
                    case .playing:
                        updatePlaybackState(.playing)
                        
                    case .waitingToPlayAtSpecifiedRate:
                        updatePlaybackState(.waiting)
                        if let reason = player.reasonForWaitingToPlay {
                            infoLog("Playing is waiting because \(reason)")
                        }
                    }
                }
            }
            
        } else if context == &TinyVideoPlayerAVPlayerItemObservationContext {
            
            guard let playerItem = object as? AVPlayerItem else {
                return
            }

            if keyPath == #keyPath(AVPlayerItem.status) {
                
                let status: AVPlayerItemStatus
                if let statusCode = change?[.newKey] as? NSNumber {
                    status = AVPlayerItemStatus(rawValue: statusCode.intValue)!
                } else {
                    status = .unknown
                }
                
                switch status {
                    
                case .readyToPlay:
                    updatePlaybackState(.ready)
                    
                case .failed:
                    videoDuration = nil
                    if let error = playerItem.error {
                        failedToPrepareAssetForPlayback(error: error)
                    }
                    
                default:
                    videoDuration = nil
                    break
                }
                
            } else if keyPath == #keyPath(AVPlayerItem.playbackLikelyToKeepUp) {
                
                if playerItem.isPlaybackLikelyToKeepUp {
                    delegate?.playerIsLikelyToKeepUpPlaying(self)
                }
                
            } else if keyPath == #keyPath(AVPlayerItem.playbackBufferEmpty) {
                
                /*
                    Please note that there are two conditions that can trigger value changes for this property:
                    - Buffer is running out for the current playing item
                    - Playback for the current video is finished
                    We need to filter out the second case.
                 */
                if playerItem.isPlaybackBufferEmpty && player.rate > 0 {
                    updatePlaybackState(.waiting)
                }
                
            } else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
                
                if let timeRanges = change?[.newKey] as? [NSValue],
                   let firstRangeValue = timeRanges.first?.timeRangeValue {
                    
                    let start = max(Float(firstRangeValue.start.seconds) - self.startPosition, 0.0)
                    let end = min(Float(firstRangeValue.end.seconds), self.endPosition - self.startPosition)
                    
                    guard start <= end else {
                        return
                    }
                    
                    verboseLog("Loaded content in range, start: \(start), end: \(end)")
                    delegate?.player(self, didUpdateBufferRange: start...end)
                    
                    /*
                        Update the buffering progress value.
                        A progress value is only valid if the buffered time is adjecent to the current position.
                     */
                    let currentPosition: Float = self.playbackPosition ?? 0.0

                    if currentPosition >= start {
                        let catchedSecs = end - currentPosition
                        if catchedSecs >= 0 {
                            bufferProgress = catchedSecs / TinyVideoPlayerConstants.bufferSize
                            
                            if bufferProgress! <= Float(2.0) {
                                infoLog("Buffering progress: \(bufferProgress! * 100)%")
                            }
                        }
                    } else {
                        bufferProgress = 0.0
                    }
                }
                
            }
        }
    }

    /**
        This function is used to provide supportance of the isPrettyfyingPauseStateTransation toggle.
     */
    fileprivate func updatePauseStateWithFilteringOn() {
        
        if playbackState == .unknown || playbackState == .playing {
            return
            
        } else {
            updatePlaybackState(.paused)
        }
    }
    
    /**
        Update playback state and decide whether to propagate the state change to it's delegate.
      */
    fileprivate func updatePlaybackState(_ newState: TinyPlayerState) {
        
        guard newState != playbackState else {
            return
        }
        
        /* 
            When the player has passed the .ready state once (move to waiting, playing, etc.), 
            it should not go back to the .ready state, unless the resetPlayback() method is called.
         */
        if newState == .ready && newState.rawValue <= playbackState.rawValue {
            return
        }
        
        updateCommandCenterInfo()
        
        delegate?.player(self, didChangePlaybackStateFromState: playbackState, toState: newState)
        
        playbackState = newState
        
        if newState == .ready {
            
            guard let playerItem = self.playerItem else {
                return
            }
            
            playerItemIsReadyForPlaying(playerItem: playerItem)
        }
    }
    
    /**
        This method only get called once each time a new video is loaded.
     */
    fileprivate func playerItemIsReadyForPlaying(playerItem: AVPlayerItem) {
        
        /* Link the initilized AVPlayer to the TinyVideoPlayerView. */
        playerView.player = player
        
        /* Calculate the start/end position. */
        if endPosition == 0 {
            endPosition = Float(playerItem.duration.seconds)
        }
        videoDuration = endPosition - startPosition
        
        /* Attach time observer immediately right after starting media preparation. */
        attachTimeObserver()
        
        delegate?.player(self, didUpdateSeekableRange: 0...videoDuration!)
        
        /* This closure will be executed on the main thread. */
        let followUpOperations = { (succeed: Bool) in
            
            self.delegate?.playerIsReadyToPlay(self)
            
            if #available(iOS 10.0, tvOS 10.0, *) {
                self.playerItem?.preferredForwardBufferDuration = 0.0
            }
        }
        
        /* Jump the start point if there is one present. */
        if startPosition > 0 {
            
            seekTo(position: 0.0, completion: followUpOperations)
            
        } else {
            
            followUpOperations(true)
        }
        
        /* Reset the videoEnded flag. */
        currentVideoPlaybackEnded = false
    }

    internal func playerItemDidPlayToEndTime(_ notification: Notification? = nil) {
        
        if player.rate != 0.0 {
            
            player.rate = 0.0
        }

        updatePlaybackState(.finished)
        
        delegate?.playerHasFinishedPlayingVideo(self)
    }

    internal func playerItemPlaybackStalled(_ notification: Notification) {
        
        updatePlaybackState(.waiting)
    }

    fileprivate func failedToPrepareAssetForPlayback(error: Error) {
        
        delegate?.player(self, didEncounterFailureWithError: error)
        
        errorLog("[TinyPlayer][Error] Failed preparing asset: \(error)")
    }

    // MARK: - Player Controls

    /**
        Partially release the memory. The playerItem will be cleared, but leave the AVPlayer and the playerView in place.
        Call this method if you want to call switchResourceUrl(:) at a later time to re-use the playerView to 
        play another video wittout re-initializing the whole class.
     */
    public func closeCurrentItem() {
        
        player.pause()
        
        detachTimeObserver()

        currentVideoPlaybackEnded = true
        
        playbackPosition = 0.0
 
        if let currentPlayerItem = playerItem {
            detachObserversFrom(playerItem: currentPlayerItem)
        }
        
        playerItem = nil
        
        player.replaceCurrentItem(with: nil)
    }

    /**
        Play the currently loaded video content.
     */
    public func play() {
        /*
            Please note set the rate to 1 doesn't garantee a instant playback.
         */
        player.rate = 1.0
        
        /*
            Prefer to use the timeControlStatus property to accurately retrieve player state.
         */
        if #available(iOS 10.0, tvOS 10.0, *) {
            return
        }
        
        updatePlaybackState(.playing)
    }

    /**
        Pause the currently loaded video content.
     */
    public func pause() {
        
        player.rate = 0.0
        
        if isPrettyfyingPauseStateTransation {
            /*
                When the filter is turned on, we have to manually notify the state change.
                Because that the internal pause state observation of the playerItem (with timeControlStatus) is disabled.
             */
            updatePlaybackState(.paused)
        }

        /*
            Prefer to use the timeControlStatus property to accurately retrieve player state.
         */
        if #available(iOS 10.0, tvOS 10.0, *) {
            return
        }

        updatePlaybackState(.paused)
    }

    /**
        Reset all playback status.
        Use this function to let the player consider the current playerItem as a freshly loaded one.
     */
    public func resetPlayback() {
        
        updatePlaybackState(.ready)
        
        currentVideoPlaybackEnded = false
        
        seekTo(position: startPosition)
    }

    private var isSeeking: Bool = false

    /**
        Seek to a certain position.
     
        - parameter position: Where the player should seek to.
        - parameter completion: After seeking this closure will be excuted.
        - parameter cancelPreviousSeeking: Force cancelling all the pending seeking actions. 
          The completion block will be called by passing a **false** parameter.
     
        - Note: After the seeking operation, the completion closure will be excuted on the main thread.
     */
    public func seekTo(position: Float, cancelPreviousSeeking: Bool = true, completion: ((Bool)-> Void)? = nil) {
        
        if cancelPreviousSeeking {
            player.currentItem?.cancelPendingSeeks()
            isSeeking = false
        }
        
        guard isSeeking == false else {
            completion?(false)
            return
        }
        
        let timePoint: CMTime = CMTime(seconds: Double(startPosition + position), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        /* Validate the CMTime object. An invalid CMTime can cause crash when calling seek(to:) method. */
        if !CMTIME_IS_VALID(timePoint) {
            return
        }

        isSeeking = true
        
        player.seek(to: timePoint) { completed in
            
            DispatchQueue.main.async { [unowned self]  in
                self.isSeeking = false
                completion?(completed)
            }
        }
    }

    /**
        Seek forward in specific seconds.
        
        - parameter secs: In how far (secs) should the player perform the seek operation.
        - parameter completion: This closure will be excuted in the Main thread after seeking.
     
        - Note: The seeking behaviour will only be performed inside the valid playable timespan.
     */
    public func seekForward(secs: Float, completion: ((Bool)-> Void)? = nil) {
        
        guard let position = playbackPosition,
            let totalLength = videoDuration,
            secs > 0 else { return }
        
        let destination = max(min(position + secs, totalLength), 0.0)
        
        seekTo(position: destination, completion: completion)
    }

    /**
        Seek backwards in specific seconds.
     
        - parameter secs: In how far (secs) should the player perform the seek operation.
        - parameter completion: This closure will be excuted in the Main thread after seeking.

        - Note: The seeking behaviour will only be performed inside the valid playable timespan.
     */
    public func seekBackward(secs: Float, completion: ((Bool)-> Void)? = nil) {
        
        guard let position = playbackPosition,
            let totalLength = videoDuration,
            secs > 0 else { return }
        
        let destination = max(min(position - secs, totalLength), 0.0)
        
        seekTo(position: destination, completion: completion)
    }
}

// MARK: - CommandCenter Info Updater

/**
    TinyVideoPlayer is configured to support the play, pause, seek-forward and seek-backward commands in the CommandCenter.
    Skip-forward and skip-backward are disabled because TinyVideoPlayer doesn't have the context of the previous/next playerItems.
    Feel-free to enable more commandCenter features in your own app, e.g. the skip function, update video info, etc.
 */
public extension TinyVideoPlayer {
    
    /*
        Only need to setup once at the initial phase of the TinyVideoPlayer.
     */
    public func setupCommandCenterTriggers() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        let seekForwardCommand = commandCenter.seekForwardCommand
        seekForwardCommand.isEnabled = true
        seekForwardCommand.addTarget { event -> MPRemoteCommandHandlerStatus in

            guard let _ = self.playerItem else {
                
                if #available(iOS 9.1, *) {
                    return .noActionableNowPlayingItem
                } else {
                    return .commandFailed
                }
            }

            guard let position = self.playbackPosition else {
                return .commandFailed
            }
            
            self.seekTo(position: position + TinyVideoPlayerConstants.seekingInterval)
            return .success
        }
        
        let seekBackwardCommand = commandCenter.seekBackwardCommand
        seekBackwardCommand.isEnabled = true
        seekBackwardCommand.addTarget { event -> MPRemoteCommandHandlerStatus in

            guard let _ = self.playerItem else {
                
                if #available(iOS 9.1, *) {
                    return .noActionableNowPlayingItem
                } else {
                    return .commandFailed
                }
            }

            guard let position = self.playbackPosition else {
                return .commandFailed
            }

            self.seekTo(position: position + TinyVideoPlayerConstants.seekingInterval)
            return .success
        }
        
        let playCommand = commandCenter.playCommand
        playCommand.isEnabled = true
        playCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            
            guard let _ = self.playerItem else {
                
                if #available(iOS 9.1, *) {
                    return .noActionableNowPlayingItem
                } else {
                    return .commandFailed
                }
            }
            
            self.player.rate = 1.0
            return .success
        }

        let pauseCommand = commandCenter.pauseCommand
        pauseCommand.isEnabled = true
        pauseCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            
            guard let _ = self.playerItem else {
                
                if #available(iOS 9.1, *) {
                    return .noActionableNowPlayingItem
                } else {
                    return .commandFailed
                }
            }
            
            self.player.rate = 0.0
            return .success
        }
        
        updateCommandCenterInfo()
    }

    /**
        This function can be called freely at anytime to update the current playing media info in the CommandCenter.
     */
    public func updateCommandCenterInfo() {
        
        var infoDict = [String: Any]()
        
        if let position = self.playbackPosition {
            infoDict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        }

        if let duration = self.videoDuration {
            infoDict[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            if let progress = self.playbackProgress {
                infoDict[MPNowPlayingInfoPropertyPlaybackProgress] = progress
            }
        }
        
        if let videoTitle = self.mediaContext?.videoTitle {
            infoDict[MPMediaItemPropertyTitle] = videoTitle
            
        } else {
            
            /* Extract the common keys from the video metadata and find the title info. */
            if let metatDataItems = playerItem?.asset.commonMetadata {
                
                if let titleItem = (metatDataItems.filter {
                        $0.commonKey == AVMetadataCommonKeyTitle
                    }.first) {
                    
                    infoDict[MPMediaItemPropertyTitle] = titleItem.stringValue
                }
            }
        }
        
        if let artistName = self.mediaContext?.artistName {
            infoDict[MPMediaItemPropertyArtist] = artistName
        }
        
        if let thumbnail = self.mediaContext?.thumbnailImage {
            
            let artwork: MPMediaItemArtwork
            
            if #available(iOS 10.0, tvOS 10.0, *) {
                artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300.0, height: 300.0)) { _ in
                    return thumbnail
                }
            } else {
                artwork = MPMediaItemArtwork(image: thumbnail)
            }
            
            infoDict[MPMediaItemPropertyArtwork] = artwork
        }
        
        infoDict[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = infoDict
    }
}

