//
//  PodcastViews.swift
//  mindsherpa
//
//  Created by Claude on 8/28/25.
//

import SwiftUI
import AVKit
import AVFoundation
import MediaPlayer

struct PodcastView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    @State private var selectedCourse: Course?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading podcasts...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.podcasts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "podcast")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Podcasts Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Podcasts will appear here once they're added to your courses.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    ForEach(groupedPodcasts(), id: \.course.id) { group in
                        PodcastCourseSection(
                            course: group.course,
                            podcasts: group.podcasts,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding()
        }
        .sheet(item: $viewModel.currentPodcast) { podcast in
            PodcastPlayerView(podcast: podcast, viewModel: viewModel, shouldAutoPlay: viewModel.shouldAutoPlayPodcast)
        }
    }
    
    private func groupedPodcasts() -> [(course: Course, podcasts: [Podcast])] {
        let courses = viewModel.courses
        var groups: [(course: Course, podcasts: [Podcast])] = []
        
        for course in courses {
            let coursePodcasts = viewModel.podcasts.filter { podcast in
                let normalizedPodcastCourseId = podcast.courseId?.replacingOccurrences(of: "course-", with: "") ?? ""
                let normalizedCourseId = course.id.replacingOccurrences(of: "course-", with: "")
                return normalizedPodcastCourseId == normalizedCourseId
            }
            
            if !coursePodcasts.isEmpty {
                groups.append((course: course, podcasts: coursePodcasts.sorted { $0.sequenceOrder ?? 0 < $1.sequenceOrder ?? 0 }))
            }
        }
        
        return groups
    }
}

struct PodcastCourseSection: View {
    let course: Course
    let podcasts: [Podcast]
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(course.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(podcasts.count) episode\(podcasts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            
            ForEach(podcasts) { podcast in
                PodcastCardView(podcast: podcast, viewModel: viewModel)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PodcastArtworkPlaceholder: View {
    let courseId: String?
    
    private var courseInfo: (gradient: LinearGradient, icon: String) {
        let normalizedCourseId = courseId?.replacingOccurrences(of: "course-", with: "") ?? ""
        
        switch normalizedCourseId {
        case "2", "electrical-fundamentals":
            return (
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                "bolt.fill"
            )
        case "3", "battery-technology":
            return (
                LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                "battery.100percent"
            )
        case "4", "ev-charging-systems":
            return (
                LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                "car.fill"
            )
        default:
            return (
                LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                "waveform"
            )
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(courseInfo.gradient)
            .overlay(
                Image(systemName: courseInfo.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            )
    }
}

struct PodcastCardView: View {
    let podcast: Podcast
    @ObservedObject var viewModel: EVCoachViewModel
    
    private var progress: PodcastProgress? {
        viewModel.podcastProgress[podcast.id]
    }
    
    private var progressPercentage: Double {
        guard let progress = progress, progress.totalDuration > 0 else { return 0 }
        return Double(progress.playbackPosition) / Double(progress.totalDuration)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Podcast artwork
            VStack {
                if let thumbnailUrl = podcast.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        PodcastArtworkPlaceholder(courseId: podcast.courseId)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    PodcastArtworkPlaceholder(courseId: podcast.courseId)
                        .frame(width: 60, height: 60)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(podcast.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if !podcast.description.isEmpty {
                    Text(podcast.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(formatDuration(podcast.duration))
                        .font(.caption)

                    if podcast.isMuxPodcast {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let progress = progress, progress.playbackPosition > 0 {
                        Spacer()
                        Text("Played \(formatDuration(progress.playbackPosition))")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
                .foregroundStyle(.secondary)

                if progressPercentage > 0 {
                    ProgressView(value: progressPercentage)
                        .tint(.purple)
                }
            }

            Spacer()

            // Play button - separate from card tap
            Button {
                // Play button - navigate with autoplay
                viewModel.playPodcast(podcast, autoPlay: true)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            // Card tap - navigate without autoplay
            viewModel.playPodcast(podcast, autoPlay: false)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

struct PodcastPlayerView: View {
    let podcast: Podcast
    @ObservedObject var viewModel: EVCoachViewModel
    let shouldAutoPlay: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var isLoadingAudio = false
    @State private var audioError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    Spacer()
                    Text("Podcast Player")
                        .font(.headline)
                    Spacer()
                    Button("", action: {})
                        .disabled(true)
                        .hidden()
                }
                .padding()
                
                Spacer()
                
                // Artwork
                ZStack {
                    if let thumbnailUrl = podcast.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            PodcastArtworkPlaceholder(courseId: podcast.courseId)
                        }
                        .frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    } else {
                        PodcastArtworkPlaceholder(courseId: podcast.courseId)
                            .frame(width: 250, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                }
                
                // Track info
                VStack(spacing: 8) {
                    Text(podcast.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    if !podcast.description.isEmpty {
                        Text(podcast.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal)
                
                // Progress slider
                VStack(spacing: 8) {
                    Slider(value: $currentTime, in: 0...duration) { editing in
                        if !editing {
                            player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                        }
                    }
                    .tint(.purple)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Controls
                HStack(spacing: 40) {
                    Button {
                        seekBackward()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    }
                    .disabled(isLoadingAudio || player == nil)
                    
                    Button {
                        togglePlayPause()
                    } label: {
                        if isLoadingAudio {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 64, height: 64)
                        } else {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.purple)
                        }
                    }
                    .disabled(isLoadingAudio || player == nil)
                    
                    Button {
                        seekForward()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                    .disabled(isLoadingAudio || player == nil)
                }
                
                // Error message
                if let error = audioError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                await setupPlayer()
            }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() async {
        isLoadingAudio = true
        audioError = nil
        
        // Configure audio session for background playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Handle Mux URLs vs traditional URLs
        if podcast.isMuxPodcast {
            // For Mux podcasts, create AVPlayer using Mux streaming
            guard let muxId = podcast.muxPlaybackId else {
                audioError = "Invalid Mux playback ID"
                isLoadingAudio = false
                return
            }
            
            // Create Mux player for audio streaming
            // Use Mux HLS URL for audio streaming
            let muxHLSUrl = URL(string: "https://stream.mux.com/\(muxId).m3u8")!
            player = AVPlayer(url: muxHLSUrl)
        } else {
            // Traditional audio URL handling
            guard let url = URL(string: podcast.audioUrl) else { 
                audioError = "Invalid audio URL"
                isLoadingAudio = false
                return 
            }
            player = AVPlayer(url: url)
        }
        
        // Observe time updates
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            
            // Update progress in view model
            viewModel.updatePodcastProgress(
                podcastId: podcast.id,
                playbackPosition: Int(currentTime),
                totalDuration: Int(duration)
            )
            
            // Update now playing info with current time
            updateNowPlayingInfo()
        }
        
        // Setup Media Player Command Center for lock screen controls
        setupMediaPlayerCommandCenter()
        
        // Get duration
        if let item = player?.currentItem {
            do {
                let durationTime = try await item.asset.load(.duration)
                self.duration = durationTime.seconds.isFinite ? durationTime.seconds : 0
                
                // Restore playback position if exists
                if let progress = viewModel.podcastProgress[podcast.id], progress.playbackPosition > 0 {
                    currentTime = Double(progress.playbackPosition)
                    await player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                }

                // Auto-play if requested
                if shouldAutoPlay {
                    player?.play()
                    isPlaying = true
                }

                isLoadingAudio = false
            } catch {
                audioError = "Failed to load audio: \(error.localizedDescription)"
                isLoadingAudio = false
            }
        } else {
            audioError = "Unable to create player item"
            isLoadingAudio = false
        }
    }
    
    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
        
        // Clear now playing info and command center
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let newTime = max(0, currentTime - 15)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let newTime = min(duration, currentTime + 15)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func setupMediaPlayerCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Enable play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            guard let player = self.player else { return .commandFailed }
            player.play()
            self.isPlaying = true
            self.updateNowPlayingInfo()
            return .success
        }
        
        // Enable pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            guard let player = self.player else { return .commandFailed }
            player.pause()
            self.isPlaying = false
            self.updateNowPlayingInfo()
            return .success
        }
        
        // Enable skip backward command
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { _ in
            self.seekBackward()
            return .success
        }
        
        // Enable skip forward command
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { _ in
            self.seekForward()
            return .success
        }
        
        // Set up Now Playing info
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = podcast.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "MindSherpa EV Training"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Set artwork if available (you can add podcast artwork here)
        // nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
        //     // Return podcast artwork image here
        // }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

struct PodcastView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EVCoachViewModel()
        viewModel.courses = [
            Course(
                id: "electrical-fundamentals", 
                title: "Electrical Fundamentals", 
                description: "Master the electrical principles powering electric vehicles", 
                level: "Intermediate", 
                estimatedHours: 8.0, 
                videos: [], 
                podcasts: nil, 
                thumbnailUrl: nil, 
                sequenceOrder: 1
            )
        ]
        viewModel.podcasts = [
            Podcast(id: "1", title: "Electrifying the Road: Unpacking the Physics and Power of EV Motors", description: "Deep dive into electric vehicle motor physics, power delivery systems, and the fundamental principles that make EVs work", duration: 1800, audioUrl: "https://skillvergence.mindsherpa.ai/podcasts/Electrifying_the_Road__Unpacking_the_Physics_and_Power_of_EV_Motors.m4a", sequenceOrder: 1, courseId: "electrical-fundamentals", episodeNumber: 1, thumbnailUrl: nil),
            Podcast(id: "2", title: "Introduction to EV Safety", description: "Learn the fundamentals of working safely with electric vehicles", duration: 1500, audioUrl: "https://example.com/audio2.mp3", sequenceOrder: 2, courseId: "electrical-fundamentals", episodeNumber: 2, thumbnailUrl: nil)
        ]
        return PodcastView(viewModel: viewModel)
    }
}