//
//  UnifiedVideoPlayer.swift
//  mindsherpa
//
//  Created by Claude on 9/5/25.
//

import SwiftUI
import AVKit
import AVFoundation
import MuxPlayerSwift
import Combine

// Unified Mux Player for both basic and advanced courses
// Replaces YouTube player with consistent Mux streaming

struct UnifiedVideoPlayer: View {
    let video: Video?
    let advancedCourse: AdvancedCourse?
    
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var playerViewController: AVPlayerViewController?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = false
    @State private var isLoading: Bool = true
    @State private var progressTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showCustomPlayButton: Bool = true
    
    // Computed properties for unified handling
    private var playbackId: String {
        if let advancedCourse = advancedCourse {
            return advancedCourse.muxPlaybackId
        } else if let video = video {
            // First try to get from video's muxPlaybackId field
            if let muxId = video.muxPlaybackId, !muxId.isEmpty {
                return muxId
            }
            // Fall back to migration mapping
            return MuxMigrationData.getMuxPlaybackId(for: video.id) ?? ""
        }
        return ""
    }
    
    private var videoTitle: String {
        if let advancedCourse = advancedCourse {
            return advancedCourse.title
        } else if let video = video {
            return video.title
        } else {
            return "Video"
        }
    }
    
    private var videoDescription: String {
        if let advancedCourse = advancedCourse {
            return advancedCourse.description
        } else if let video = video {
            return video.description
        } else {
            return ""
        }
    }
    
    private var videoId: String {
        if let advancedCourse = advancedCourse {
            return advancedCourse.id
        } else if let video = video {
            return video.id
        } else {
            return ""
        }
    }
    
    private var courseId: String {
        if let advancedCourse = advancedCourse {
            return advancedCourse.prerequisiteCourseId
        } else if let video = video {
            return video.courseId ?? ""
        } else {
            return ""
        }
    }
    
    private var isAdvancedCourse: Bool {
        return advancedCourse != nil
    }
    
    // Initialize with either basic video or advanced course
    init(video: Video) {
        self.video = video
        self.advancedCourse = nil
    }
    
    init(advancedCourse: AdvancedCourse) {
        self.video = nil
        self.advancedCourse = advancedCourse
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player Area
            ZStack {
                if let playerViewController = playerViewController {
                    ZStack {
                        UnifiedPlayerViewControllerRepresentable(playerViewController: playerViewController)
                            .frame(minHeight: 200)
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        // Custom play button overlay
                        if showCustomPlayButton && !isPlaying {
                            CustomPlayButtonOverlay {
                                // Start playing when custom play button is tapped
                                playerViewController.player?.play()
                                showCustomPlayButton = false
                                isPlaying = true
                            }
                        }
                    }
                } else if playbackId.isEmpty {
                    // No Mux ID available - show error
                    Rectangle()
                        .fill(Color.red.opacity(0.1))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.red)
                                Text("Video Not Available")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("Mux playback ID missing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                ProgressView("Loading video...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text(isAdvancedCourse ? "Securing premium content..." : "Preparing course video...")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        )
                }
                
                // Custom branding overlay (bottom-right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Skillvergence")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                    }
                }
            }
            
            // Video Info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(videoTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isAdvancedCourse {
                            Text("Advanced • \(String(format: "%.1f", advancedCourse?.estimatedHours ?? 0)) hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Course • \(video?.formattedDuration ?? "0:00")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Course badge
                    VStack(spacing: 4) {
                        if isAdvancedCourse {
                            Image(systemName: advancedCourse?.certificateType.badgeIcon ?? "star.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text("\(advancedCourse?.xpReward ?? 0) XP")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("50 XP")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if !videoDescription.isEmpty {
                    Text(videoDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Progress bar
                if duration > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(currentTime, duration), total: duration)
                            .progressViewStyle(LinearProgressViewStyle(tint: isAdvancedCourse ? .orange : .blue))
                            .scaleEffect(y: 0.8)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            setupPlayer()
            setupBackgroundHandling()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer() {
        guard !playbackId.isEmpty else {
            isLoading = false
            return
        }
        
        Task {
            do {
                // Configure audio session for video playback
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetoothA2DP])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to set up audio session for video: \(error)")
                }
                
                // Create Mux Player with proper configuration to avoid rebuffer warnings
                let playerViewController = AVPlayerViewController(playbackID: playbackId)
                
                // Configure player settings for proper fullscreen support
                playerViewController.allowsPictureInPicturePlayback = false
                playerViewController.showsPlaybackControls = true
                playerViewController.entersFullScreenWhenPlaybackBegins = false
                playerViewController.exitsFullScreenWhenPlaybackEnds = false
                playerViewController.canStartPictureInPictureAutomaticallyFromInline = false
                
                // Always show play button for better UX
                playerViewController.requiresLinearPlayback = false
                
                // Force specific video gravity
                playerViewController.videoGravity = .resizeAspect
                
                // Enable landscape fullscreen
                if #available(iOS 16.0, *) {
                    playerViewController.allowsVideoFrameAnalysis = false
                }
                
                // Ensure player doesn't get deallocated
                playerViewController.player?.automaticallyWaitsToMinimizeStalling = true
                
                // Configure MUX player to disable manual rebuffer tracking
                if let player = playerViewController.player {
                    // Disable automatic rebuffer detection to avoid the warning
                    player.automaticallyWaitsToMinimizeStalling = true
                }
                
                await MainActor.run {
                    self.playerViewController = playerViewController
                    self.isLoading = false
                    
                    // Ensure controls are visible initially for better UX
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        playerViewController.showsPlaybackControls = true
                    }
                    
                    // Start progress tracking timer
                    self.startProgressTimer()
                    
                    // Monitor play state to hide custom play button
                    self.monitorPlaybackState()
                }
                
                // Get duration when available
                if let player = playerViewController.player,
                   let asset = player.currentItem?.asset {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = CMTimeGetSeconds(duration)
                    }
                }
                
                // Load saved progress
                loadSavedProgress()
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func startProgressTimer() {
        // Stop any existing timer first
        stopProgressTimer()
        
        // Create new timer for progress tracking
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func setupBackgroundHandling() {
        // Handle app going to background/foreground
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { _ in
                // App going to background - pause and save progress
                if let player = playerViewController?.player {
                    player.pause()
                }
                saveProgress()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                // App fully in background - stop timer
                stopProgressTimer()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                // App coming back to foreground - restart timer if player exists
                if playerViewController != nil {
                    startProgressTimer()
                }
            }
            .store(in: &cancellables)
    }
    
    private func cleanupPlayer() {
        // Stop progress timer
        stopProgressTimer()
        
        // Cancel all background notifications
        cancellables.removeAll()
        
        // Save final progress
        saveProgress()
        
        // Stop and cleanup player
        if let playerViewController = playerViewController,
           let player = playerViewController.player {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        
        // Clear references
        self.playerViewController = nil
        self.isPlaying = false
        self.currentTime = 0
    }
    
    private func updateProgress() {
        guard let playerViewController = playerViewController,
              let player = playerViewController.player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        self.currentTime = currentTime
        self.isPlaying = player.rate > 0
        
        // Update progress store
        progressStore.updateVideoProgress(
            videoId: videoId,
            courseId: courseId,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
        
        // Check for completion (85% watched or near end)
        if duration > 0 {
            let watchPercentage = currentTime / duration
            if watchPercentage >= 0.85 || (duration - currentTime <= 30 && watchPercentage >= 0.70) {
                markVideoCompleted()
            }
        }
    }
    
    private func loadSavedProgress() {
        // Load progress from ProgressStore
        if let progress = progressStore.videoProgress(videoId: videoId) {
            let savedTime = progress.lastPositionSec
            
            // Seek to saved position if available
            if savedTime > 0, let player = playerViewController?.player {
                let seekTime = CMTime(seconds: savedTime, preferredTimescale: 1)
                player.seek(to: seekTime)
                
            }
        }
    }
    
    private func saveProgress() {
        // Progress is automatically saved via updateProgress() method
        // Ensure final progress update
        if currentTime > 0 && duration > 0 {
            progressStore.updateVideoProgress(
                videoId: videoId,
                courseId: courseId,
                currentTime: currentTime,
                duration: duration,
                isPlaying: false
            )
        }
    }
    
    private func markVideoCompleted() {
        // Calculate XP award
        let baseXP = isAdvancedCourse ? (advancedCourse?.xpReward ?? 150) : 50
        let tierMultiplier = SubscriptionManager.shared.currentTier.xpMultiplier
        let _ = Int(Double(baseXP) * tierMultiplier)
        
    }
    
    private func monitorPlaybackState() {
        guard let player = playerViewController?.player else { return }
        
        // Monitor playback state to hide custom play button when playing
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .playing {
                    self.isPlaying = true
                    self.showCustomPlayButton = false
                } else if status == .paused {
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - SwiftUI Wrapper for AVPlayerViewController

struct UnifiedPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Store reference in coordinator to prevent deallocation
        context.coordinator.retainedPlayerViewController = playerViewController
        
        // Additional configuration for fullscreen support
        playerViewController.videoGravity = .resizeAspect
        
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Ensure we're working with the same instance
        guard uiViewController === context.coordinator.retainedPlayerViewController else {
            return
        }
        
        // Ensure consistent configuration
        if uiViewController.videoGravity != .resizeAspect {
            uiViewController.videoGravity = .resizeAspect
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var retainedPlayerViewController: AVPlayerViewController?
        
        deinit {
            retainedPlayerViewController?.player?.pause()
            retainedPlayerViewController = nil
        }
    }
}

// MARK: - Custom Play Button Overlay

struct CustomPlayButtonOverlay: View {
    let onPlay: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
            
            // Play button
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                        .offset(x: 2, y: 0) // Slight offset for visual center
                }
            }
            .buttonStyle(.plain)
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Preview

#Preview("Basic Video") {
    // This would need a sample Video with Mux ID
    UnifiedVideoPlayer(video: Video(
        id: "1-1",
        title: "High Voltage Safety Basics",
        description: "Learn the fundamentals of high voltage safety",
        duration: 600,
        videoUrl: "", // Legacy - not used
        muxPlaybackId: nil, // Will use MuxMigrationData mapping
        sequenceOrder: 1,
        courseId: "course_1"
    ))
}

#Preview("Advanced Course") {
    UnifiedVideoPlayer(advancedCourse: AdvancedCourse.sampleAdvancedCourses[0])
}