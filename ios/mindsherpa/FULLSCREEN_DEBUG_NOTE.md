# 🐛 Fullscreen Video Player Issue - Debug Note

## Problem Summary
Video players transition to fullscreen mode briefly, then screen goes **blank/black** and controls become **unresponsive**. Play button toggles visually but video doesn't actually play.

## Affected Components
- **UnifiedVideoPlayer.swift** - Main player for basic & advanced courses
- **MuxVideoPlayer.swift** - Advanced course specific player  
- **VideoViews.swift** - Legacy basic course player (AVPlayerControllerView)

All use `AVPlayerViewController` wrapped in SwiftUI `UIViewControllerRepresentable`

## Technical Details

### Current Architecture
```swift
// SwiftUI View
ZStack {
    UnifiedPlayerViewControllerRepresentable(playerViewController: playerViewController)
        .frame(minHeight: 200)
        .aspectRatio(16/9, contentMode: .fit)
    
    // Custom play button overlay
    if showCustomPlayButton && !isPlaying {
        CustomPlayButtonOverlay { ... }
    }
}
```

### Player Configuration
```swift
// Current setup in setupPlayer()
let playerViewController = AVPlayerViewController(playbackID: playbackId) // Mux integration

playerViewController.allowsPictureInPicturePlayback = false
playerViewController.showsPlaybackControls = true
playerViewController.entersFullScreenWhenPlaybackBegins = false
playerViewController.exitsFullScreenWhenPlaybackEnds = false
playerViewController.canStartPictureInPictureAutomaticallyFromInline = false
playerViewController.requiresLinearPlayback = false
playerViewController.videoGravity = .resizeAspect
```

### UIViewControllerRepresentable Implementation
```swift
struct UnifiedPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        context.coordinator.retainedPlayerViewController = playerViewController
        playerViewController.videoGravity = .resizeAspect
        return playerViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var retainedPlayerViewController: AVPlayerViewController?
    }
}
```

## Suspected Root Causes

### 1. SwiftUI ↔ UIKit Bridge Issues
- `AVPlayerViewController` loses connection to its player during fullscreen transition
- SwiftUI representable doesn't properly handle view controller lifecycle during fullscreen
- Player instance gets deallocated or disconnected

### 2. Mux Player Integration
- Using `AVPlayerViewController(playbackID: playbackId)` from MuxPlayerSwift
- Mux player may have specific fullscreen handling requirements
- Possible conflict between Mux player and native AVPlayerViewController fullscreen

### 3. View Hierarchy Problems
- SwiftUI aspect ratio constraints may interfere with fullscreen
- Custom play button overlay might affect touch handling
- Frame constraints conflict with fullscreen presentation

## Debugging Steps to Try

### 1. Test with Standard AVPlayer
```swift
// Replace Mux integration temporarily
let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
let player = AVPlayer(url: url)
playerViewController.player = player
```

### 2. Simplify Representable
```swift
// Remove coordinator pattern temporarily
struct SimplePlayerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
```

### 3. Remove SwiftUI Constraints
```swift
// Test without aspect ratio constraints
UnifiedPlayerViewControllerRepresentable(playerViewController: playerViewController)
    .frame(height: 200)
// Remove: .aspectRatio(16/9, contentMode: .fit)
```

### 4. Add Fullscreen Delegate
```swift
extension YourClass: AVPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: AVPlayerViewController, 
                            willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        print("🎬 Will begin fullscreen")
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, 
                            willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        print("🎬 Will end fullscreen")
    }
}
```

## Key Files to Review
1. **mindsherpa/UnifiedVideoPlayer.swift** (lines 105-120, 434-529)
2. **mindsherpa/MuxVideoPlayer.swift** (lines 35-49, 322-417)
3. **mindsherpa/VideoViews.swift** (lines 233-301)

## Environment
- iOS 18.6 (simulator)
- Xcode project with MuxPlayerSwift integration
- SwiftUI + UIKit hybrid approach
- App version 1.2.2

## Previous Attempts
- Added coordinator pattern for stronger retention ❌
- Enhanced player configuration ❌  
- Custom lifecycle management ❌
- Frame management improvements ❌

## What Works
- ✅ Video loads and plays in inline mode
- ✅ Custom play button overlay works
- ✅ Audio plays correctly
- ✅ Progress tracking works
- ✅ Basic playback controls work in inline mode

## What Fails
- ❌ Fullscreen transition → blank screen
- ❌ Controls unresponsive in fullscreen
- ❌ Play button toggles but video doesn't play
- ❌ Must exit fullscreen to regain functionality

---

**Goal:** Fix fullscreen so videos can play in landscape mode without going blank or losing control responsiveness.

Let me know what you find! 🔍