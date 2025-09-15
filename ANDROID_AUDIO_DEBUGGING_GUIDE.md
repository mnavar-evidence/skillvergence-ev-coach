# Android Video Audio Debugging Guide

## Issue
Videos play correctly in the Android app but **no audio** is heard during playback, despite implementing comprehensive audio focus management.

## Current Implementation Status
✅ **Video Playback**: Works correctly with Mux HLS streaming
✅ **UI Controls**: Player controls respond properly
✅ **Progress Tracking**: Video progress updates correctly
❌ **Audio Output**: No audio heard despite code implementation

## Audio Implementation Added
The `VideoDetailActivity` now includes comprehensive audio management:

### 1. Audio Focus Management
```kotlin
// Audio manager and focus request setup
private lateinit var audioManager: AudioManager
private var audioFocusRequest: AudioFocusRequest? = null

// Request audio focus before playback
private fun requestAudioFocus(): Boolean
private fun handleAudioFocusChange(focusChange: Int)
private fun abandonAudioFocus()
```

### 2. ExoPlayer Audio Configuration
```kotlin
// ExoPlayer with proper audio attributes
exoPlayer = ExoPlayer.Builder(this)
    .setAudioAttributes(
        androidx.media3.common.AudioAttributes.Builder()
            .setUsage(androidx.media3.common.C.USAGE_MEDIA)
            .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
            .build(),
        true // Handle audio focus automatically
    )
    .build()
```

### 3. Lifecycle Integration
- Audio focus requested on video setup and resume
- Audio focus abandoned on pause/stop/destroy
- Proper volume control during focus changes

## Debugging Steps

### Step 1: Check Device Audio Settings
```bash
# Test these manually on the device:
1. System volume up (not muted)
2. Media volume specifically up (not just ringer volume)
3. Try playing audio in other apps (YouTube, Spotify)
4. Check if device is in silent/do-not-disturb mode
```

### Step 2: Verify Audio Focus Logs
Look for these log messages in `mindsherpa_debug.log` or Android Studio logcat:
```
🔊 Audio focus granted
🎬 Mux Player setup completed for ID: [playback_id]
🎬 Mux Player ready
```

If you see `🔇 Audio focus denied`, that indicates a system-level audio issue.

### Step 3: Test Audio Stream Directly
```kotlin
// Add this temporary debug method to VideoDetailActivity:
private fun testAudioStream() {
    // Test if the Mux HLS stream actually contains audio
    val muxUrl = "https://stream.mux.com/$muxPlaybackId.m3u8"
    logToFile(this, "🎵 Testing audio stream: $muxUrl")

    // Check ExoPlayer audio renderer status
    exoPlayer.audioFormat?.let { format ->
        logToFile(this, "🎵 Audio format: ${format.sampleMimeType}, channels: ${format.channelCount}")
    } ?: logToFile(this, "❌ No audio format detected")
}
```

### Step 4: Check Audio Renderer
```kotlin
// Add to setupVideoPlayer() after player creation:
exoPlayer.addListener(object : Player.Listener {
    override fun onAudioSessionIdChanged(audioSessionId: Int) {
        logToFile(this@VideoDetailActivity, "🎵 Audio session ID: $audioSessionId")
    }

    override fun onVolumeChanged(volume: Float) {
        logToFile(this@VideoDetailActivity, "🔊 Volume changed: $volume")
    }
})
```

### Step 5: Alternative Simple Test
Create a minimal test without audio focus:
```kotlin
// Simplify player creation for testing
exoPlayer = ExoPlayer.Builder(this).build()
exoPlayer.setMediaItem(MediaItem.fromUri(muxUrl))
exoPlayer.prepare()
exoPlayer.volume = 1.0f
exoPlayer.play()
```

### Step 6: Check Mux Stream Audio Content
Test the Mux streams directly in a browser or media player:
```bash
# Test these URLs directly:
https://stream.mux.com/MPYRvK9KnXqBafit01UdxV023S011gYphUUavHkJKu96Z8.m3u8
https://stream.mux.com/IrMUCbYqtfxeCMbDChNlqZlwxn9Q02d8nYio6a002MBFI.m3u8

# If these don't have audio in VLC/browser, the issue is with Mux content
```

## Potential Root Causes

### 1. **Mux Stream Audio Encoding**
- Mux streams might be video-only without audio tracks
- Audio codec not supported by Android ExoPlayer
- Audio track present but in unsupported format

### 2. **Android System Audio**
- Audio routing to wrong output (e.g., Bluetooth device not connected)
- System audio session conflicts
- Device-specific audio driver issues

### 3. **ExoPlayer Configuration**
- Audio renderer not properly initialized
- Audio format negotiation failure
- Media3 version compatibility issue

### 4. **App Permissions**
- Missing audio-related permissions in AndroidManifest.xml
- Audio focus request failing due to policy restrictions

## Quick Fixes to Try

### Fix 1: Add Audio Permission
Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### Fix 2: Force Audio Renderer
```kotlin
// In ExoPlayer.Builder, explicitly enable audio
.setRenderersFactory(DefaultRenderersFactory(this).setEnableAudioTrackPlaybackParams(true))
```

### Fix 3: Test with Different Source
Try a known working HLS stream with audio:
```kotlin
val testUrl = "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
```

## Files to Check
1. **`VideoDetailActivity.kt`** - Main implementation
2. **`AndroidManifest.xml`** - Permissions
3. **`build.gradle.kts`** - Media3 dependencies
4. **Device logs** - Audio focus and ExoPlayer messages

## Expected Log Output
If working correctly, you should see:
```
🔊 Audio focus granted
🎬 Mux Player setup completed for ID: MPYRvK9KnXqBafit01UdxV023S011gYphUUavHkJKu96Z8
🎬 Mux Player ready
🎵 Audio session ID: [number]
🔊 Volume changed: 1.0
```

Let me know what you find in the logs and which of these tests reveal the issue!