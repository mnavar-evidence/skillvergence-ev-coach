//
//  VideoViews.swift
//  mindsherpa
//
//  Created by Claude Code on 8/27/25.
//

import SwiftUI
import AVKit
import WebKit

// MARK: - VideoPlayerView

struct VideoPlayerView: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEndQuiz = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Video Player
            VStack(spacing: 0) {
                if let youtubeId = video.youtubeVideoId {
                    YouTubePlayerView(videoId: youtubeId, viewModel: viewModel, video: video)
                        .aspectRatio(16/9, contentMode: .fit)
                } else {
                    // Local video file or direct URL
                    AVPlayerControllerView(url: URL(string: video.videoUrl), viewModel: viewModel, video: video)
                        .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .background(Color.black)
            
            // Back button removed - VideoDetailView handles navigation
        }
        .onAppear {
            viewModel.selectVideo(video)
        }
        .onDisappear {
            viewModel.stopVideoProgressTracking()
        }
        .sheet(isPresented: $showEndQuiz) {
            if let quiz = video.endOfVideoQuiz {
                EndOfVideoQuizView(
                    quiz: quiz,
                    video: video,
                    viewModel: viewModel,
                    onDismiss: {
                        showEndQuiz = false
                    }
                )
            }
        }
        .onReceive(viewModel.$shouldShowEndQuiz) { shouldShow in
            if shouldShow && video.endOfVideoQuiz != nil {
                showEndQuiz = true
                viewModel.shouldShowEndQuiz = false // Reset the trigger
            }
        }
    }
}

// MARK: - YouTube Player View

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    let viewModel: EVCoachViewModel
    let video: Video
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.isScrollEnabled = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Extract the 'si' parameter from the original URL for enhanced embed
        let siParameter = extractSiParameter(from: video.videoUrl) ?? ""
        let embedParams = siParameter.isEmpty ? "" : "?si=\(siParameter)"
        
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background-color: black; }
                .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe width="560" 
                        height="315" 
                        src="https://www.youtube.com/embed/\(videoId)\(embedParams)" 
                        title="YouTube video player" 
                        frameborder="0" 
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
                        referrerpolicy="strict-origin-when-cross-origin" 
                        allowfullscreen>
                </iframe>
            </div>
            <script>
                // Simple progress tracking for end-of-video detection
                var startTime = Date.now();
                var elapsed = 0;
                var videoDuration = \(video.duration);
                var hasTriggeredEndQuiz = false;
                
                var progressInterval = setInterval(function() {
                    // Only track progress when page is visible and focused
                    if (!document.hidden && document.hasFocus()) {
                        elapsed = Math.floor((Date.now() - startTime) / 1000);
                        
                        // Send progress update
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.progressUpdate) {
                            window.webkit.messageHandlers.progressUpdate.postMessage({
                                videoId: '\(video.id)',
                                watchedSeconds: elapsed,
                                totalDuration: videoDuration
                            });
                        }
                        
                        // Check if video is near completion (within last 30 seconds or at 90% completion)
                        if (!hasTriggeredEndQuiz && elapsed >= Math.max(videoDuration - 30, videoDuration * 0.9)) {
                            hasTriggeredEndQuiz = true;
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoNearEnd) {
                                window.webkit.messageHandlers.videoNearEnd.postMessage({
                                    videoId: '\(video.id)',
                                    elapsed: elapsed,
                                    duration: videoDuration
                                });
                            }
                        }
                    }
                }, 2000); // Check every 2 seconds
                
                // Clean up interval when page becomes hidden
                document.addEventListener('visibilitychange', function() {
                    if (document.hidden && progressInterval) {
                        clearInterval(progressInterval);
                        progressInterval = null;
                    }
                });
                
                // Pause timer when window loses focus
                window.addEventListener('blur', function() {
                    if (progressInterval) {
                        clearInterval(progressInterval);
                        progressInterval = null;
                    }
                });
            </script>
        </body>
        </html>
        """
        
        uiView.loadHTMLString(embedHTML, baseURL: nil)
        
        // Start progress tracking
        viewModel.startVideoProgressTracking(for: video.id, duration: video.duration)
    }
    
    private func extractSiParameter(from url: String) -> String? {
        if let urlComponents = URLComponents(string: url),
           let queryItems = urlComponents.queryItems {
            return queryItems.first(where: { $0.name == "si" })?.value
        }
        return nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let viewModel: EVCoachViewModel
        private weak var webView: WKWebView?
        
        init(viewModel: EVCoachViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
            
            // Clean up existing handlers first
            let userContentController = webView.configuration.userContentController
            userContentController.removeScriptMessageHandler(forName: "progressUpdate")
            userContentController.removeScriptMessageHandler(forName: "videoNearEnd")
            
            // Add new handlers
            userContentController.add(self, name: "progressUpdate")
            userContentController.add(self, name: "videoNearEnd")
        }
        
        deinit {
            // Clean up message handlers when coordinator is destroyed
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "progressUpdate")
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "videoNearEnd")
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "progressUpdate":
                if let messageBody = message.body as? [String: Any],
                   let videoId = messageBody["videoId"] as? String,
                   let watchedSeconds = messageBody["watchedSeconds"] as? Int,
                   let totalDuration = messageBody["totalDuration"] as? Int {
                    
                    viewModel.updateVideoProgress(videoId: videoId, watchedSeconds: watchedSeconds, totalDuration: totalDuration)
                }
                
            case "videoNearEnd":
                if let messageBody = message.body as? [String: Any],
                   let videoId = messageBody["videoId"] as? String,
                   let elapsed = messageBody["elapsed"] as? Int,
                   let duration = messageBody["duration"] as? Int {
                    
                    viewModel.triggerEndOfVideoQuiz(videoId: videoId, watchedSeconds: elapsed, totalDuration: duration)
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - AVPlayer Controller View

struct AVPlayerControllerView: UIViewControllerRepresentable {
    let url: URL?
    let viewModel: EVCoachViewModel
    let video: Video
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        if let url = url {
            let player = AVPlayer(url: url)
            controller.player = player
            
            // Add periodic time observer for progress tracking
            let interval = CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let watchedSeconds = Int(time.seconds)
                viewModel.updateVideoProgress(videoId: video.id, watchedSeconds: watchedSeconds, totalDuration: video.duration)
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update if needed
    }
}

// MARK: - Course Detail View

struct CourseDetailView: View {
    let course: Course
    @ObservedObject var viewModel: EVCoachViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Course Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: course.category.icon)
                            .font(.title)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(course.category.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            let completionPct = course.completionPercentage(with: viewModel.videoProgress)
                            Text("\(Int(completionPct))%")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Continue Watching Button
                    if let nextVideo = getNextVideo() {
                        NavigationLink {
                            VideoPage(video: nextVideo, viewModel: viewModel)
                        } label: {
                            ContinueWatchingButton(video: nextVideo, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 12)
                    }
                    
                    // Enhanced Progress Summary
                    let progressSummary = viewModel.getCourseProgressSummary(courseId: course.id)
                    CourseProgressSummary(
                        courseTitle: course.title,
                        totalVideos: progressSummary.totalVideos,
                        completedVideos: progressSummary.videosCompleted,
                        totalPodcasts: progressSummary.totalPodcasts,
                        completedPodcasts: progressSummary.podcastsCompleted,
                        totalWatchTime: course.estimatedHours * 3600, // Convert to seconds
                        watchedTime: progressSummary.totalWatchTime
                    )
                    .padding(.top, 12)
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                    
                    // Course Stats
                    HStack(spacing: 16) {
                        StatView(title: "Videos", value: "\(course.videos.count)", icon: "play.circle.fill")
                        StatView(title: "Duration", value: formatHours(course.estimatedHours), icon: "clock.fill")
                        StatView(title: "Level", value: course.skillLevel.displayName, icon: "chart.bar.fill")
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Video List
                VideoListView(videos: course.videos, viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "\(minutes)m"
        } else {
            let roundedHours = hours.rounded()
            return "\(Int(roundedHours))h"
        }
    }
    
    private func getNextVideo() -> Video? {
        // Sort videos by sequence order
        let sortedVideos = course.videos.sorted { $0.sequenceOrder ?? 0 < $1.sequenceOrder ?? 0 }
        
        // Find first incomplete video
        for video in sortedVideos {
            let progress = viewModel.videoProgress[video.id]
            if progress == nil || !progress!.isCompleted {
                return video
            }
        }
        
        // If all videos are complete, return nil
        return nil
    }
}

// MARK: - Video List View

struct VideoListView: View {
    let videos: [Video]
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Content")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(videos, id: \.id) { video in
                    NavigationLink(
                        destination: VideoPage(video: video, viewModel: viewModel)
                            .onAppear { viewModel.selectVideo(video) }
                    ) {
                        VideoRowView(video: video, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Video Row View

struct VideoRowView: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        let progress = viewModel.videoProgress[video.id]
        
        HStack(spacing: 12) {
            // Video Thumbnail
            AsyncImage(url: video.thumbnailUrl.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                case .failure(_):
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.3))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                        )
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tertiary)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tertiary)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(video.formattedDuration)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(4)
                    }
                }
            )
            
            // Video Info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(video.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Enhanced Progress indicator with percentage
                HStack(spacing: 8) {
                    if let progress = progress, progress.watchedSeconds > 0 {
                        // Progress bar
                        MediaProgressIndicator(
                            progress: progress.progressDouble,
                            isCompleted: progress.isCompleted,
                            mediaType: .video,
                            size: .small
                        )
                        
                        // Percentage text
                        Text("\(Int(progress.progressDouble * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(progress.isCompleted ? .green : .blue)
                            .frame(width: 35, alignment: .trailing)
                    } else {
                        // Empty state - just show duration
                        HStack {
                            Text("Not started")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Completion status
                if let progress = progress, progress.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Completed")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
        )
    }
}

// MARK: - Continue Watching Button

struct ContinueWatchingButton: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Play Icon
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Progress-aware title
                let progress = viewModel.videoProgress[video.id]
                if let progress = progress, progress.watchedSeconds > 0 {
                    Text("Continue watching")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(video.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        Text("\(Int(progress.progressDouble * 100))% watched")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Circle()
                            .fill(.secondary)
                            .frame(width: 3, height: 3)
                        
                        Text(video.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Start watching")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(video.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Video Detail View (Replaced with VideoPage.swift for crash safety)

// MARK: - Quiz View

struct QuizView: View {
    let quiz: Quiz
    @ObservedObject var viewModel: EVCoachViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(quiz.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(quiz.questions) { question in
                        QuestionView(
                            question: question,
                            selectedAnswer: selectedAnswers[question.id],
                            showingResults: showingResults
                        ) { answerIndex in
                            selectedAnswers[question.id] = answerIndex
                        }
                    }
                    
                    if !showingResults {
                        Button("Submit Quiz") {
                            showingResults = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .disabled(selectedAnswers.count != quiz.questions.count)
                    } else {
                        VStack(spacing: 16) {
                            Text("Quiz Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            
                            let correctAnswers = selectedAnswers.values.enumerated().filter { index, answer in
                                quiz.questions[index].correctAnswerIndex == answer
                            }.count
                            
                            Text("Score: \(correctAnswers)/\(quiz.questions.count)")
                                .font(.headline)
                            
                            Button("Close") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Question View

struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let showingResults: Bool
    let onAnswerSelected: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.headline)
                .fontWeight(.medium)
            
            ForEach(question.options.indices, id: \.self) { index in
                Button(action: {
                    if !showingResults {
                        onAnswerSelected(index)
                    }
                }) {
                    HStack {
                        Text(question.options[index])
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if showingResults {
                            if index == question.correctAnswerIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if selectedAnswer == index {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        } else if selectedAnswer == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor(for: index))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor(for: index), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(showingResults)
            }
            
            if showingResults, let explanation = question.explanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func backgroundColor(for index: Int) -> Color {
        if showingResults {
            if index == question.correctAnswerIndex {
                return .green.opacity(0.2)
            } else if selectedAnswer == index {
                return .red.opacity(0.2)
            }
        } else if selectedAnswer == index {
            return .blue.opacity(0.2)
        }
        return .clear
    }
    
    private func borderColor(for index: Int) -> Color {
        if showingResults {
            if index == question.correctAnswerIndex {
                return .green
            } else if selectedAnswer == index {
                return .red
            }
        } else if selectedAnswer == index {
            return .blue
        }
        return Color(.quaternaryLabel)
    }
}

// MARK: - Quiz Countdown View

struct QuizCountdownView: View {
    let secondsRemaining: Int
    @State private var pulseScale: Double = 1.0
    
    private var countdownColor: Color {
        switch secondsRemaining {
        case 26...30:
            return .blue
        case 11...25:
            return .orange
        case 1...10:
            return .red
        default:
            return .gray
        }
    }
    
    private var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(countdownColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("Quiz in")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(formattedTime)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(countdownColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(countdownColor.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(pulseScale)
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: secondsRemaining) {
            if secondsRemaining <= 5 {
                startIntensePulse()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = secondsRemaining <= 10 ? 1.1 : 1.05
        }
    }
    
    private func startIntensePulse() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
}

// MARK: - End of Video Quiz View

struct EndOfVideoQuizView: View {
    let quiz: EndOfVideoQuiz
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    let onDismiss: () -> Void
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showingResults = false
    @State private var score: Double = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Video Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(quiz.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if !showingResults {
                    Text("Answer these questions to get credit for watching this video:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(quiz.questions) { question in
                            EndOfVideoQuestionView(
                                question: question,
                                selectedAnswer: selectedAnswers[question.id],
                                showingResults: showingResults,
                                onAnswerSelected: { answerIndex in
                                    selectedAnswers[question.id] = answerIndex
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !showingResults {
                        Button(action: {
                            submitQuiz()
                        }) {
                            Text("Submit Quiz")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(selectedAnswers.count != quiz.questions.count)
                    } else {
                        let passed = score >= quiz.passingScore
                        
                        VStack(spacing: 8) {
                            Text(passed ? "Congratulations! 🎉" : "Not quite right 🤔")
                                .font(.headline)
                                .foregroundColor(passed ? .green : .orange)
                            
                            Text("Score: \(Int(score * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !passed {
                                Text("You need \(Int(quiz.passingScore * 100))% to get credit for this video")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            if !passed && quiz.isRequired {
                                Button("Try Again") {
                                    resetQuiz()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                            
                            Button(passed ? "Complete Video" : "Skip for Now") {
                                completeQuiz(passed: passed)
                                onDismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func submitQuiz() {
        // Calculate score
        let correctAnswers = quiz.questions.filter { question in
            selectedAnswers[question.id] == question.correctAnswerIndex
        }.count
        
        score = Double(correctAnswers) / Double(quiz.questions.count)
        showingResults = true
    }
    
    private func resetQuiz() {
        selectedAnswers.removeAll()
        showingResults = false
        score = 0
    }
    
    private func completeQuiz(passed: Bool) {
        viewModel.completeEndOfVideoQuiz(videoId: video.id, passed: passed)
    }
}

struct EndOfVideoQuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let showingResults: Bool
    let onAnswerSelected: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
            
            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button(action: {
                        if !showingResults {
                            onAnswerSelected(index)
                        }
                    }) {
                        HStack {
                            Text(option)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            
                            if showingResults {
                                if index == question.correctAnswerIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if selectedAnswer == index {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            } else if selectedAnswer == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(backgroundColor(for: index))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor(for: index), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(showingResults)
                }
            }
            
            if showingResults && selectedAnswer == question.correctAnswerIndex {
                Text(question.explanation ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func backgroundColor(for index: Int) -> Color {
        if showingResults {
            if index == question.correctAnswerIndex {
                return .green.opacity(0.1)
            } else if selectedAnswer == index {
                return .red.opacity(0.1)
            }
        } else if selectedAnswer == index {
            return .blue.opacity(0.1)
        }
        return .clear
    }
    
    private func borderColor(for index: Int) -> Color {
        if showingResults {
            if index == question.correctAnswerIndex {
                return .green
            } else if selectedAnswer == index {
                return .red
            }
        } else if selectedAnswer == index {
            return .blue
        }
        return Color(.quaternaryLabel)
    }
}


// MARK: - Supporting Views

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
