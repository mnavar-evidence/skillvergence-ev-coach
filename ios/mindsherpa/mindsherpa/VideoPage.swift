// VideoPage.swift
import SwiftUI
import AVKit

/// Use this view as the destination when you tap a lesson.
struct VideoPage: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    @StateObject private var vm = VideoVM()   // important: StateObject here

    var body: some View {
        // UnifiedVideoPlayer handles all video info display, no need for duplication
        UnifiedVideoPlayer(video: video)
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