// VideoPage.swift
import SwiftUI
import AVKit

/// Use this view as the destination when you tap a lesson.
struct VideoPage: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    @StateObject private var vm = VideoVM()   // important: StateObject here

    var body: some View {
        VStack(spacing: 16) {
            // Smart video player - YouTube or AVPlayer based on URL
            if let youtubeId = video.youtubeVideoId {
                // YouTube Video
                YouTubePlayerView(videoId: youtubeId, viewModel: viewModel, video: video)
                    .frame(height: 260)
                    .background(Color.black)
            } else {
                // Direct video file or stream
                switch vm.state {
                case .idle, .loading:
                    ProgressView("Loading video…")
                        .frame(height: 260)
                        .background(Color.black)
                case .ready(let player):
                    VideoPlayer(player: player)
                        .frame(height: 260)
                        .onDisappear {
                            // Pause when leaving
                            player.pause()
                        }
                case .failed(let error):
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text("Video Load Failed")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 260)
                    .background(Color.black)
                    .foregroundStyle(.white)
                }
            }

            // Video Info Section
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label("\(video.duration / 60):\(String(format: "%02d", video.duration % 60))", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                    }
                    
                    Text(video.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    // Optional transcript section
                    if let transcript = video.transcript {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transcript")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(transcript)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(video.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { 
            // Only load with VideoVM if not a YouTube video
            if video.youtubeVideoId == nil, let url = URL(string: video.videoUrl) {
                vm.load(from: url)
            }
            // Track video view
            viewModel.selectVideo(video)
        }
        .onDisappear {
            // Stop progress tracking when navigating away
            viewModel.stopVideoProgressTracking()
        }
    }
}