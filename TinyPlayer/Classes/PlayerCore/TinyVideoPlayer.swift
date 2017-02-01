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
    Constants that controls the player's interactive behavior.
    Change these values freely to best suit the needs.
 */
public struct TinyVideoPlayerConstants {
    static var seekingInterval: Float = 10.0    // in secs
    static var timeObservationInterval: Float = 0.01    // in secs
    static var bufferSize: Float = 6.0      // in secs
}


public class TinyVideoPlayer: NSObject, TinyPlayer, TinyLogging {
  
    public var loggingLevel: TinyLoggingLevel = .info
    
    public weak var delegate: TinyPlayerDelegate?

    internal var player: AVPlayer
    internal var playerItem: AVPlayerItem?
    internal var internalUrl: URL?

    /**
        Both of the following vriables have a initial value of 0 if there's no video loaded.
        When a playerItem is intialized, these two will be assigned following two rules:
        - If the corresponding properties in the MediaContext have been valued, these value will be mapped to them.
        - If no specification in the MediaContext, then 0 will be assigned to 'startPosition', and the total duration of the video will be assigned to 'endPosition'.
     */
    internal var startPosition: Float = 0.0
    internal var endPosition: Float = 0.0

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

    public var videoDuration: Float? {
        
        didSet {
            updateCommandCenterInfo()
        }
    }

    internal var currentVideoPlaybackEnded: Bool = false
    
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
            if !self.currentVideoPlaybackEnded && position >= self.endPosition {
                
                self.currentVideoPlaybackEnded = true

                self.playerItemDidPlayToEndTime(nil)

            }
        }
    }

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

    public var hidden: Bool = false
    
    public var enableAirplayMediaRoute: Bool {
        didSet {
            player.allowsExternalPlayback = enableAirplayMediaRoute
        }
    }

    /**
        Activate this switch will force the player to filter out less meaningful state transitions.
        - For example, in a player's lifecycle, the normal state transition chain woule be:
            unknown -> paused -> ready -> playing -> paused -> finished
        - When this is activated, the redundant(sometimes unnecessary) paused state will be filtered out:
            unknown -> ready -> playing -> finished
        Please switch this toggle on your own preference.
     */
    public var isPrettyfingPauseStateTransation: Bool = true

    public var playbackState: TinyPlayerState

    static let assetKeysRequiredForOptimizedPlayback = [
        "playable",
        "hasProtectedContent",
        "duration"
    ]

    /**
       This view can be inserted directly into the UI presentation structure.
    */
    public lazy var playerView: TinyVideoPlayerView = TinyVideoPlayerView()

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
    
    convenience public init(resourceUrl: URL, mediaContext: MediaContext? = nil) {

        self.init()

        switchResourceUrl(resourceUrl, mediaContext: mediaContext)
    }

    deinit {

        player.pause()
        
        if let currentPlayerItem = playerItem {
            detachObserversFrom(playerItem: currentPlayerItem)
            detachTimeObserver()
        }
        
        player.replaceCurrentItem(with: nil)

        detachObserversFrom(player: player)

        playerView.player = nil
    }

    /**
        Setting up this value triggers the media initiation process.
        Main entrance point of TinyVideoPlayer.
     */
    public func switchResourceUrl(_ resourceUrl: URL, mediaContext: MediaContext? = nil) {
        
        if resourceUrl != internalUrl {
            
            internalUrl = resourceUrl
            
            updatePlaybackState(.unknown)
            
            self.mediaContext = mediaContext
            
            let asset = AVURLAsset(url: resourceUrl)
            asset.loadValuesAsynchronously(forKeys: TinyVideoPlayer.assetKeysRequiredForOptimizedPlayback) {
                DispatchQueue.main.async {
                    self.setupPlayerWithLoadedAsset(asset: asset)
                }
            }
            
            infoLog("TinyVideoPlayer has started to load media at url: \(resourceUrl.absoluteString)")
        }
    }

    public func setupPlayerWithLoadedAsset(asset: AVAsset) {
        
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
                        if isPrettyfingPauseStateTransation {
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
                    ///TODO: How to use this notification?
                }
                
            } else if keyPath == #keyPath(AVPlayerItem.playbackBufferEmpty) {
                
                /*
                    There are two conditions that can lead to buffer empty:
                    1. Buffer is running out for the current playing item
                    2. Playback is finished
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
        This function is used to provide supportance of the isPrettyfingPauseStateTransation toggle.
     */
    func updatePauseStateWithFilteringOn() {
        
        if playbackState == .unknown || playbackState == .playing {
            return
            
        } else {
            updatePlaybackState(.paused)
        }
    }
    
    func updatePlaybackState(_ newState: TinyPlayerState) {
        
        guard newState != playbackState else {
            return
        }
        
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
    func playerItemIsReadyForPlaying(playerItem: AVPlayerItem) {
        
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
        let followUpOperations = {
            
            self.delegate?.playerIsReadyToPlay(self)
            
            if #available(iOS 10.0, tvOS 10.0, *) {
                self.playerItem?.preferredForwardBufferDuration = 0.0
            }
        }
        
        /* Jump the start point if there is any. */
        if startPosition > 0 {
            
            seekTo(position: 0.0, completion: followUpOperations)
            
        } else {
            
            followUpOperations()
        }
        
        /* Reset the videoEnded flag. */
        currentVideoPlaybackEnded = false
    }

    func playerItemDidPlayToEndTime(_ notification: Notification? = nil) {
        
        if self.player.rate != 0.0 {
            
            self.player.rate = 0.0
        }

        updatePlaybackState(.finished)
        
        delegate?.playerHasFinishedPlayingVideo(self)
    }

    func playerItemPlaybackStalled(_ notification: Notification) {
        
        updatePlaybackState(.waiting)
    }

    func failedToPrepareAssetForPlayback(error: Error) {
        
        delegate?.player(self, didEncounterFailureWithError: error)
        
        errorLog("[TinyPlayer][Error] Failed preparing asset: \(error)")
    }

    // MARK: - Player Controls

    /**
        Partially release the memory. The playerItem will be cleared, but leave the AVPlayer and the playerView will remain.
        Call this method if you want to re-use the playerView to play another video wittout re-initializing the whole class at a later time.
     */
    public func closeCurrentItem() {
        
        player.pause()
        
        if let currentPlayerItem = playerItem {
            detachObserversFrom(playerItem: currentPlayerItem)
            detachTimeObserver()
        }
        
        playerItem = nil
        
        player.replaceCurrentItem(with: nil)
    }

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

    public func pause() {
        
        player.rate = 0.0
        
        if isPrettyfingPauseStateTransation {
            /*
             When the filter is turned on, we need to reply on the external command to determin state change.
             Because the internal pause state change (using timeControlStatus) is disabled.
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
        Use this function to let the player treats the current playerItem as freshly loaded. 
     */
    public func resetPlayback() {
        
        updatePlaybackState(.ready)
        
        currentVideoPlaybackEnded = false
        
        seekTo(position: startPosition)
    }

    fileprivate var isSeeking: Bool = false

    /**
        Please aware that after finish seeking, the completion closure will be excuted on main thread.
     */
    public func seekTo(position: Float, completion: (()-> Void)? = nil) {
        
        guard isSeeking == false else { return }
        
        let timePoint: CMTime = CMTime(seconds: Double(startPosition + position), preferredTimescale: 1)
        
        if !CMTIME_IS_VALID(timePoint) {
            return
        }

        isSeeking = true
        
        player.currentItem?.cancelPendingSeeks()
        
        player.seek(to: timePoint) { completed in
            
            if completed {
                
                DispatchQueue.main.async {
                    self.isSeeking = false
                    completion?()
                }
            }
        }
    }

    public func seekForward(secs: Float, completion: (()-> Void)? = nil) {
        
        guard let position = playbackPosition,
            let totalLength = videoDuration,
            secs > 0 else { return }
        
        let destination = max(min(position + secs, totalLength), 0.0)
        
        seekTo(position: destination)
    }

    public func seekBackward(secs: Float, completion: (()-> Void)? = nil) {
        
        guard let position = playbackPosition,
            let totalLength = videoDuration,
            secs > 0 else { return }
        
        let destination = max(min(position - secs, totalLength), 0.0)
        
        seekTo(position: destination)
    }
}

/**
    By default TinyPlayer is configured to support only play, pause, seek-forward and seek-backward commands in the CommandCenter.
    Skip-forward and skip-backward is disabled before TinyPlayer doesn't know the context of the previous/next playerItems.
    Feel-free to enable more commandCenter features in your own app, e.g. the skip function, update video info, etc.
 */
public extension TinyVideoPlayer {
    
    func setupCommandCenterTriggers() {
        
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

    func updateCommandCenterInfo() {
        
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

