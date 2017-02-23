# TinyPlayer

[![CI Status](http://img.shields.io/travis/xiaohu557/TinyPlayer.svg?style=flat)](https://travis-ci.org/xiaohu557/TinyPlayer)
[![Version](https://img.shields.io/cocoapods/v/TinyPlayer.svg?style=flat)](http://cocoapods.org/pods/TinyPlayer)
[![License](https://img.shields.io/cocoapods/l/TinyPlayer.svg?style=flat)](http://cocoapods.org/pods/TinyPlayer)
[![Platform](https://img.shields.io/cocoapods/p/TinyPlayer.svg?style=flat)](http://cocoapods.org/pods/TinyPlayer)

TinyPlayer is simple, elegant and highly efficient  video player for iOS and tvOS. It is based on Apple’s AVFoundation framework.

## Why?

Served as the core player component of our Quazer[http://apple.co/2blYuqq] app, we have spent quite some effort to build it up while following the industry best practices in terms of maximal utilizing Apple’s AVFoundation framework. AVFoundation is very powerful but not that easy to take control. To unleash the most potential of it, an experienced developer will also need some time to set up everything correctly. We alleviate the burden of developers who needs the media playback support in their apps by providing an easy-to-use player component that encapsulates all the complexities within.


## Features

- **Lightweight**
- **Simple**: integrate with just a few lines of code
- **Modern**: fully utilize the modern APIs from iOS/tvOS 10
- **Efficient**
- **Controls**
- **Various Formats**: play all common video/audio formats (mpeg/mov/avi/mp4/ts/mp3/aac/ac3/…).
- **Streaming / HLS**: support video Streaming and HLS out-of-the-box
- **Airplay**
- **CommandCenter**

## Example

To run the example project, clone the repo, and run `pod install` from the `Examples` directory first. Open the `TinyPlayerDemo+Benchmark.xcworkspace` and select a building theme to run.

There are currently two executable projects inside the workspace:

- `TinyPlayerDemo`: A very simple demonstration on how to link the player to a UIViewController.
- `TinyPlayerBenchmark`: This project demonstrates how efficiently TinyPlayer can run. The latest test shows that iPhone 6s can handle up to 16 players simultaneously on screen  while all of them are playing 720p contents. And this only consumes 7.2 MB of memory in total! Try it for yourself. 😉

## Requirements

The minimum system requirement of TinyPlayer is iOS 9.1 and tvOS 9.1 due to the lack of some API support in the previous system releases.

## Installation

TinyPlayer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TinyPlayer"
```

## Usage

TinyPlayer can be understand as a data modal manager that exposes an inter-connected view instance to the outside world to provide an easy integration into your existing view hierarchy. States handling and business logics are encapsulated inside to avoid complexities. You can interact with it using the exposed interfaces defined in the TinyPlayer protocol.

You may initiate it with a url:

```swift
import TinyPlayer

let mediaUrl = …
let player = TinyVideoPlayer(resourceUrl: mediaUrl)
```

We recommend to put the player instance in your view model. To attach the player view to one of your view controllers, put the following lines in your view controller’s loading procedure, like:

```swift
override func viewWillAppear(_ animated: Bool) {
	super.viewWillAppear(animated)
	let aPlayerView = player.playerView
	self.view.addSubview(aPlayerView)
}
```

That’s it! Now you can send commands to the player instance, e.g.:

```swift
/// start playback
player.play()

/// or stop playback
player.pause()

/// or seek to some position
player.seekTo(position: xxx)

/// or seek to some position with completion closure
player.seekTo(position: xxx, cancelPreviousSeeking: true) { succeed in
	/// do something…
}

/// or close the playing media item to release its memory
player.closeCurrentItem()

/// or reset playback of the current media item
player.resetPlayback()
```

Sometimes you want to specify a playback context or want to take a precise control over the playback content. In this case, you could use the `MediaContext` struct like this:

```swift
let mediaContext = MediaContext(videoTitle: “Example”,
								artistName: "TinyPlayerDemo”,
								startPosition: 5.0,   /// start playing from this position
								endPosition: 0.0,     /// play to the end of the video
								thumbnailImage: UIImage(some image…))
let player = TinyVideoPlayer(resourceUrl: mediaUrl, mediaContext: mediaContext)
```

To be able to react on the player’s state changes, you can assign a delegate to the player instance:

```swift
player.delegate = self
```

Then you can implement the following delegate methods to gain more controls:

```swfit
func player(_ player: TinyPlayer, didChangePlaybackStateFromState oldState: TinyPlayerState, toState newState: TinyPlayerState) {
	…		
}

func player(_ player: TinyPlayer, didUpdatePlaybackPosition position: Float, playbackProgress: Float) {
	…		
}

func player(_ player: TinyPlayer, didUpdateBufferRange range: ClosedRange<Float>) {
	…		
}

func player(_ player: TinyPlayer, didUpdateSeekableRange range: ClosedRange<Float>) {
	…		
}

public func player(_ player: TinyPlayer, didEncounterFailureWithError error: Error) {
	…		
}

func playerIsReadyToPlay(_ player: TinyPlayer) {
	…		
}

func playerHasFinishedPlayingVideo(_ player: TinyPlayer) {
	…		
}
```

## Features upcoming

- Ads playback support
- VAST standards support
- Offline video content caching
- …

## Author

Xi Chen(xiaohu557), kevinchen@me.com

## License

TinyPlayer is available under the MIT license. See the LICENSE file for more info.
