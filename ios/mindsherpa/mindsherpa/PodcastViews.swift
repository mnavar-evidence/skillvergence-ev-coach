//
//  PodcastViews.swift
//  mindsherpa
//
//  Created by Claude on 8/28/25.
//

import SwiftUI
import AVKit

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
            PodcastPlayerView(podcast: podcast, viewModel: viewModel)
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
        Button {
            viewModel.currentPodcast = podcast
        } label: {
            HStack(spacing: 16) {
                // Podcast artwork placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.purple.gradient)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "podcast.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
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
                
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    
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
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.purple.gradient)
                        .frame(width: 250, height: 250)
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "podcast.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
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
                    
                    Button {
                        togglePlayPause()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.purple)
                    }
                    
                    Button {
                        seekForward()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: podcast.audioUrl) else { return }
        
        player = AVPlayer(url: url)
        
        // Observe time updates
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            
            // Update progress in view model
            viewModel.updatePodcastProgress(
                podcastId: podcast.id,
                playbackPosition: Int(currentTime),
                totalDuration: Int(duration)
            )
        }
        
        // Get duration
        if let item = player?.currentItem {
            duration = item.asset.duration.seconds.isFinite ? item.asset.duration.seconds : 0
            
            // Restore playback position if exists
            if let progress = viewModel.podcastProgress[podcast.id], progress.playbackPosition > 0 {
                currentTime = Double(progress.playbackPosition)
                player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
            }
        }
    }
    
    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
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
}

#Preview {
    let viewModel = EVCoachViewModel()
    // Add sample podcasts for preview
    viewModel.podcasts = [
        Podcast(id: "1", title: "Introduction to EV Safety", description: "Learn the fundamentals of working safely with electric vehicles", duration: 1800, audioUrl: "https://example.com/audio1.mp3", sequenceOrder: 1, courseId: "1", episodeNumber: 1),
        Podcast(id: "2", title: "Battery Technology Deep Dive", description: "Understanding lithium-ion batteries and safety protocols", duration: 2400, audioUrl: "https://example.com/audio2.mp3", sequenceOrder: 2, courseId: "1", episodeNumber: 2)
    ]
    return PodcastView(viewModel: viewModel)
}