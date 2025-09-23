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
    @State private var sharedPlayer: AVPlayer?
    @State private var inlinePlayerViewController: AVPlayerViewController?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = false
    @State private var isLoading: Bool = true
    @State private var progressTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showCustomPlayButton: Bool = true
    @State private var showFullscreen: Bool = false
    
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
                if let playerViewController = inlinePlayerViewController, let player = sharedPlayer {
                    ZStack {
                        ManualPlayerRepresentable(
                            playerViewController: playerViewController,
                            player: player
                        )
                        .frame(height: 220)
                        .background(Color.black)
                        
                        // Custom play button overlay
                        if showCustomPlayButton && !isPlaying {
                            CustomPlayButtonOverlay {
                                // Start playing when custom play button is tapped
                                player.play()
                                showCustomPlayButton = false
                                isPlaying = true
                            }
                        }
                        
                        // Custom fullscreen button
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    showFullscreen = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding()
                            }
                            Spacer()
                        }
                    }
                } else if playbackId.isEmpty {
                    // No Mux ID available - show error
                    Rectangle()
                        .fill(Color.red.opacity(0.1))
                        .frame(height: 220)
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
                        .frame(height: 220)
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
                        Text("WattWorks")
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
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenPlayerView(player: sharedPlayer)
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
                
                // Create shared AVPlayer using Mux
                let muxPlayerViewController = AVPlayerViewController(playbackID: playbackId)
                guard let player = muxPlayerViewController.player else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                // Configure the shared player
                player.automaticallyWaitsToMinimizeStalling = true
                
                // Create inline player controller (separate from Mux controller)
                let inlinePlayerViewController = AVPlayerViewController()
                
                // Configure inline player settings - KEEP native controls, disable system fullscreen
                inlinePlayerViewController.showsPlaybackControls = true  // Keep native controls
                inlinePlayerViewController.entersFullScreenWhenPlaybackBegins = false
                inlinePlayerViewController.exitsFullScreenWhenPlaybackEnds = false
                inlinePlayerViewController.canStartPictureInPictureAutomaticallyFromInline = false
                inlinePlayerViewController.videoGravity = .resizeAspect
                inlinePlayerViewController.allowsPictureInPicturePlayback = false
                inlinePlayerViewController.requiresLinearPlayback = false
                
                // Disable fullscreen presentation capability entirely
                inlinePlayerViewController.modalPresentationStyle = .none
                
                // Enable landscape support but disable system fullscreen
                if #available(iOS 16.0, *) {
                    inlinePlayerViewController.allowsVideoFrameAnalysis = false
                }
                
                await MainActor.run {
                    self.sharedPlayer = player
                    self.inlinePlayerViewController = inlinePlayerViewController
                    self.isLoading = false
                    
                    // Start progress tracking timer
                    self.startProgressTimer()
                    
                    // Monitor play state to hide custom play button
                    self.monitorPlaybackState()
                }
                
                // Get duration when available
                if let asset = player.currentItem?.asset {
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
                if let player = sharedPlayer {
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
                if sharedPlayer != nil {
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
        
        // Stop and cleanup shared player
        if let player = sharedPlayer {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        
        // Clear references
        self.sharedPlayer = nil
        self.inlinePlayerViewController = nil
        self.isPlaying = false
        self.currentTime = 0
    }
    
    private func updateProgress() {
        guard let player = sharedPlayer else { return }
        
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
            if savedTime > 0, let player = sharedPlayer {
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
        guard let player = sharedPlayer else { return }
        
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

// MARK: - Simple Container for Manual Fullscreen

final class SimplePlayerContainer: UIViewController, AVPlayerViewControllerDelegate {
    let playerViewController: AVPlayerViewController
    
    init(playerViewController: AVPlayerViewController) {
        self.playerViewController = playerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Set delegate to intercept fullscreen attempts
        playerViewController.delegate = self
        
        // Add player as child VC
        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        
        NSLayoutConstraint.activate([
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        playerViewController.didMove(toParent: self)
    }
    
    // MARK: - AVPlayerViewControllerDelegate
    
    // Block all system fullscreen attempts
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        // Prevent the transition by doing nothing - system fullscreen is blocked
        print("🚫 Blocked system fullscreen attempt")
    }
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        return false
    }
}

// MARK: - Manual Fullscreen Player Representable

struct ManualPlayerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    let player: AVPlayer?
    
    func makeUIViewController(context: Context) -> SimplePlayerContainer {
        // Keep native controls but disable system fullscreen
        playerViewController.showsPlaybackControls = true
        playerViewController.videoGravity = .resizeAspect
        
        // Assign the shared player
        if let player = player {
            playerViewController.player = player
        }
        
        return SimplePlayerContainer(playerViewController: playerViewController)
    }
    
    func updateUIViewController(_ uiViewController: SimplePlayerContainer, context: Context) {
        // Ensure player assignment
        if let player = player, uiViewController.playerViewController.player !== player {
            uiViewController.playerViewController.player = player
        }
    }
}

// MARK: - Fullscreen Player View

struct FullscreenPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let player: AVPlayer?
    
    // Create a dedicated fullscreen player controller
    private let fullscreenPVC: AVPlayerViewController = {
        let pvc = AVPlayerViewController()
        pvc.modalPresentationStyle = .fullScreen
        pvc.showsPlaybackControls = true
        pvc.videoGravity = .resizeAspect
        // Disable system fullscreen since we're handling it manually
        pvc.entersFullScreenWhenPlaybackBegins = false
        pvc.exitsFullScreenWhenPlaybackEnds = false
        return pvc
    }()
    
    var body: some View {
        ZStack {
            ManualPlayerRepresentable(playerViewController: fullscreenPVC, player: player)
                .ignoresSafeArea()
            
            // Close control
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .background(Color.black.ignoresSafeArea())
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