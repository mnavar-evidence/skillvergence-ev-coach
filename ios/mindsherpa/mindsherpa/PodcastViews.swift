//
//  PodcastViews.swift
//  mindsherpa
//
//  Created by Claude Code on 8/27/25.
//

import SwiftUI
import AVKit

// MARK: - Main Podcast View

struct PodcastView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.podcasts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "headphones.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                            .symbolRenderingMode(.hierarchical)
                        Text("No Podcasts Available")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("Podcast conversations will appear here when available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.podcasts) { podcast in
                            NavigationLink(destination: PodcastPlayerView(podcast: podcast, viewModel: viewModel)) {
                                PodcastCardView(podcast: podcast, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Podcast Card View

struct PodcastCardView: View {
    let podcast: Podcast
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Podcast Artwork
            VStack {
                if let thumbnailUrl = podcast.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        PodcastArtworkPlaceholder()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    PodcastArtworkPlaceholder()
                        .frame(width: 80, height: 80)
                }
            }
            
            // Podcast Info
            VStack(alignment: .leading, spacing: 6) {
                Text(podcast.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(podcast.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                HStack(spacing: 16) {
                    Label(podcast.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label("Episode \(podcast.episodeNumber)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Progress indicator if podcast has been started
                if let progress = viewModel.podcastProgress[podcast.id], progress.playbackPosition > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(progress.progressPercentage))%")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)
                        }
                        
                        MediaProgressIndicator(
                            progress: progress.progressDouble,
                            isCompleted: progress.isCompleted,
                            mediaType: .podcast,
                            size: .small
                        )
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Play button indicator
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Podcast Artwork Placeholder

struct PodcastArtworkPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                Image(systemName: "headphones")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)
            )
    }
}

// MARK: - Podcast Player View

struct PodcastPlayerView: View {
    let podcast: Podcast
    @ObservedObject var viewModel: EVCoachViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var progressTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 20) {
                // Podcast Artwork
                if let thumbnailUrl = podcast.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        PodcastArtworkPlaceholder()
                    }
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                } else {
                    PodcastArtworkPlaceholder()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                }
                
                // Podcast Info
                VStack(spacing: 8) {
                    Text(podcast.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("Episode \(podcast.episodeNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 40)
            .padding(.horizontal)
            
            Spacer()
            
            // Player Controls
            VStack(spacing: 24) {
                // Progress Bar
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            seekToTime(newValue)
                        }
                    ), in: 0...max(duration, 1))
                    .tint(.blue)
                    
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
                
                // Control Buttons
                HStack(spacing: 40) {
                    Button(action: skipBackward) {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .foregroundStyle(.primary)
                    }
                    
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                    }
                    
                    Button(action: skipForward) {
                        Image(systemName: "goforward.30")
                            .font(.title)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .background(.regularMaterial)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear(perform: setupPlayer)
        .onDisappear(perform: cleanupPlayer)
    }
    
    // MARK: - Player Methods
    
    private func setupPlayer() {
        guard let url = URL(string: podcast.audioUrl) else { return }
        
        player = AVPlayer(url: url)
        duration = Double(podcast.duration)
        
        // Load saved progress
        if let progress = viewModel.podcastProgress[podcast.id] {
            currentTime = Double(progress.playbackPosition)
            seekToTime(currentTime)
        }
        
        // Track podcast started
        AnalyticsManager.shared.trackPodcastEvent(.podcastStarted(
            podcastId: podcast.id,
            courseId: podcast.courseId,
            title: podcast.title
        ))
        
        startProgressTimer()
    }
    
    private func cleanupPlayer() {
        progressTimer?.invalidate()
        progressTimer = nil
        player?.pause()
        
        // Save progress
        viewModel.updatePodcastProgress(
            podcastId: podcast.id,
            playbackPosition: Int(currentTime),
            totalDuration: podcast.duration
        )
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            // Track pause
            AnalyticsManager.shared.trackPodcastEvent(.podcastPaused(
                podcastId: podcast.id,
                position: Int(currentTime),
                duration: Int(duration)
            ))
        } else {
            player.play()
            // Track resume
            AnalyticsManager.shared.trackPodcastEvent(.podcastResumed(
                podcastId: podcast.id,
                position: Int(currentTime)
            ))
        }
        isPlaying.toggle()
    }
    
    private func skipForward() {
        let newTime = min(currentTime + 30, duration)
        seekToTime(newTime)
    }
    
    private func skipBackward() {
        let newTime = max(currentTime - 15, 0)
        seekToTime(newTime)
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: cmTime)
        currentTime = time
    }
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let player = player else { return }
            currentTime = player.currentTime().seconds
            
            // Save progress periodically
            if Int(currentTime) % 10 == 0 { // Every 10 seconds
                viewModel.updatePodcastProgress(
                    podcastId: podcast.id,
                    playbackPosition: Int(currentTime),
                    totalDuration: podcast.duration
                )
            }
        }
    }
    
    private func formatTime(_ timeInterval: Double) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}