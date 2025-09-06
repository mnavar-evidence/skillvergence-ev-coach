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
            // Unified Mux Video Player
            UnifiedVideoPlayer(video: video)
                .frame(height: 260)

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
            // Track video view
            viewModel.selectVideo(video)
        }
        .onDisappear {
            // Stop progress tracking when navigating away
            viewModel.stopVideoProgressTracking()
        }
    }
}