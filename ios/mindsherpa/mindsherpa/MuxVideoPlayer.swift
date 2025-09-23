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
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player Area
            ZStack {
                if let playerViewController = inlinePlayerViewController, let player = sharedPlayer {
                    ZStack {
                        MuxPlayerViewControllerRepresentable(
                            playerViewController: playerViewController,
                            player: player
                        )
                        .frame(height: 220)
                        .background(Color.black)
                        
                        // Custom play button overlay
                        if showCustomPlayButton && !isPlaying {
                            MuxCustomPlayButtonOverlay {
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
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 220)
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
                        Text("WattWorks")
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
        .fullScreenCover(isPresented: $showFullscreen) {
            MuxFullscreenPlayerView(player: sharedPlayer)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer() {
        // Create Mux Player with playback ID
        #if DEBUG
        print("🎬 Setting up Mux Player with ID: \(playbackId)")
        #endif
        
        Task {
            do {
                // Configure audio session for video playback
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetoothA2DP])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    #if DEBUG
                    print("Failed to set up audio session for video: \(error)")
                    #endif
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
                
                // Get duration when available (iOS 16+ compatible)
                if let asset = player.currentItem?.asset {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = CMTimeGetSeconds(duration)
                    }
                }
                
                // Load saved progress
                loadSavedProgress()
                
            } catch {
                #if DEBUG
                print("❌ Failed to setup Mux Player: \(error)")
                #endif
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateProgress() {
        guard let player = sharedPlayer else { return }
        
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
            if savedTime > 0, let player = sharedPlayer {
                let seekTime = CMTime(seconds: savedTime, preferredTimescale: 1)
                player.seek(to: seekTime)
                
                #if DEBUG
                print("⏯️ Resumed advanced course at \(Int(savedTime)) seconds")
                #endif
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
        #if DEBUG
        print("🧹 Cleaning up Mux Player")
        #endif
        
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
    
    private func saveProgress() {
        // Progress is automatically saved via updateProgress() method
        // This method is called when the view disappears
        #if DEBUG
        print("💾 Saving advanced course progress: \(currentTime)s of \(duration)s")
        #endif
        
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
        
        // Save completion in progress store
        progressStore.updateVideoProgress(
            videoId: advancedCourse.id,
            courseId: advancedCourse.prerequisiteCourseId,
            currentTime: currentTime,
            duration: duration,
            isPlaying: false
        )
        
        // Generate certificate for completion
        Task { @MainActor in
            // Get user profile (you'll need to implement this based on your auth system)
            let user = getCurrentUser()
            
            // Create progress data
            let completionProgress = AdvancedCourseProgress(
                courseId: advancedCourse.id,
                watchedSeconds: currentTime,
                totalDuration: duration,
                completed: true,
                certificateEarned: true,
                completedAt: Date(),
                certificateIssuedAt: nil
            )
            
            // Generate certificate
            StudentCertificateManager.shared.generateCertificate(
                for: user,
                course: advancedCourse,
                completionData: completionProgress
            )
            
            print("🎓 Advanced course completed! Awarded \(xpAwarded) XP and generated \(advancedCourse.certificateType.displayName) certificate")
        }
    }
    
    private func getCurrentUser() -> UserProfile {
        // This should be implemented based on your authentication system
        // For now, return a placeholder user
        return UserProfile(
            id: "current_user",
            fullName: "Current User",
            email: "user@example.com",
            profileImage: nil
        )
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

// MARK: - Container VC with Fullscreen Delegate Support for Mux

final class MuxPlayerContainerViewController: UIViewController, AVPlayerViewControllerDelegate {
    let playerViewController: AVPlayerViewController
    var onFullscreenChange: ((Bool) -> Void)?
    
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
    
    // Block all system fullscreen attempts for inline player
    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        // Prevent the transition by doing nothing - system fullscreen is blocked
        print("🚫 Blocked system fullscreen attempt on Mux player")
    }
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        return false
    }
}

// MARK: - Manual Fullscreen Player Representable for Mux

struct MuxPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    let player: AVPlayer?
    
    func makeUIViewController(context: Context) -> MuxPlayerContainerViewController {
        // Keep native controls but disable system fullscreen
        playerViewController.showsPlaybackControls = true
        playerViewController.videoGravity = .resizeAspect
        playerViewController.entersFullScreenWhenPlaybackBegins = false
        playerViewController.exitsFullScreenWhenPlaybackEnds = false
        playerViewController.modalPresentationStyle = .none
        
        // Assign the shared player
        if let player = player {
            playerViewController.player = player
        }
        
        return MuxPlayerContainerViewController(playerViewController: playerViewController)
    }
    
    func updateUIViewController(_ uiViewController: MuxPlayerContainerViewController, context: Context) {
        // Ensure player assignment
        if let player = player, uiViewController.playerViewController.player !== player {
            uiViewController.playerViewController.player = player
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        // No longer needed - container VC handles everything
    }
}

// MARK: - Mux Fullscreen Player View

struct MuxFullscreenPlayerView: View {
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
            MuxPlayerViewControllerRepresentable(playerViewController: fullscreenPVC, player: player)
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