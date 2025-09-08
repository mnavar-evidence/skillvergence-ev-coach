//
//  MuxVideoPlayer.swift
//  mindsherpa
//
//  Created by Claude on 9/4/25.
//

import SwiftUI
import AVKit
import AVFoundation
import MuxPlayerSwift
import Combine

// Real Mux Player integration for advanced courses
// Provides secure video delivery with analytics

struct MuxVideoPlayer: View {
    let playbackId: String
    let advancedCourse: AdvancedCourse
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var playerViewController: AVPlayerViewController?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = false
    @State private var isLoading: Bool = true
    @State private var progressTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showCustomPlayButton: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player Area
            ZStack {
                if let playerViewController = playerViewController {
                    ZStack {
                        MuxPlayerViewControllerRepresentable(playerViewController: playerViewController)
                            .frame(minHeight: 200)
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        // Custom play button overlay
                        if showCustomPlayButton && !isPlaying {
                            MuxCustomPlayButtonOverlay {
                                // Start playing when custom play button is tapped
                                playerViewController.player?.play()
                                showCustomPlayButton = false
                                isPlaying = true
                            }
                        }
                    }
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                ProgressView("Loading Advanced Course...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Securing premium content...")
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
            
            // Course Info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(advancedCourse.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Advanced • \(String(format: "%.1f", advancedCourse.estimatedHours)) hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Certificate badge
                    VStack(spacing: 4) {
                        Image(systemName: advancedCourse.certificateType.badgeIcon)
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("\(advancedCourse.xpReward) XP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(advancedCourse.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
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
                        
                        ProgressView(value: currentTime, total: duration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
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
        // Create Mux Player with playback ID
        print("🎬 Setting up Mux Player with ID: \(playbackId)")
        
        Task {
            do {
                // Configure audio session for video playback
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetoothA2DP])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to set up audio session for video: \(error)")
                }
                
                // Create Mux Player with playback options
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
                
                // Get duration when available (iOS 16+ compatible)
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
                print("❌ Failed to setup Mux Player: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateProgress() {
        guard let playerViewController = playerViewController,
              let player = playerViewController.player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        self.currentTime = currentTime
        self.isPlaying = player.rate > 0
        
        // Update progress store for advanced courses
        progressStore.updateVideoProgress(
            videoId: advancedCourse.id,
            courseId: advancedCourse.prerequisiteCourseId,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
        
        // Check for completion (90% watched)
        if duration > 0 && currentTime / duration >= 0.9 {
            markCourseCompleted()
        }
    }
    
    private func loadSavedProgress() {
        // Load progress from ProgressStore for advanced courses
        if let progress = progressStore.videoProgress(videoId: advancedCourse.id) {
            let savedTime = progress.lastPositionSec
            
            // Seek to saved position if available
            if savedTime > 0, let player = playerViewController?.player {
                let seekTime = CMTime(seconds: savedTime, preferredTimescale: 1)
                player.seek(to: seekTime)
                
                print("⏯️ Resumed advanced course at \(Int(savedTime)) seconds")
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
        print("🧹 Cleaning up Mux Player")
        
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
    
    private func saveProgress() {
        // Progress is automatically saved via updateProgress() method
        // This method is called when the view disappears
        print("💾 Saving advanced course progress: \(currentTime)s of \(duration)s")
        
        // Ensure final progress update
        if currentTime > 0 && duration > 0 {
            progressStore.updateVideoProgress(
                videoId: advancedCourse.id,
                courseId: advancedCourse.prerequisiteCourseId,
                currentTime: currentTime,
                duration: duration,
                isPlaying: false
            )
        }
    }
    
    private func markCourseCompleted() {
        // Award XP and certificate
        let xpAwarded = Int(Double(advancedCourse.xpReward) * SubscriptionManager.shared.currentTier.xpMultiplier)
        
        // TODO: Save completion and award certificate
        print("Advanced course completed! Awarded \(xpAwarded) XP and \(advancedCourse.certificateType.displayName) certificate")
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

struct MuxPlayerViewControllerRepresentable: UIViewControllerRepresentable {
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

// MARK: - Custom Play Button Overlay for Mux

struct MuxCustomPlayButtonOverlay: View {
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

#Preview {
    MuxVideoPlayer(
        playbackId: "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
        advancedCourse: AdvancedCourse.sampleAdvancedCourses[4] // Course 5.1
    )
}