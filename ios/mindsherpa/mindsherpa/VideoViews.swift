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
    @Environment(\.presentationMode) var presentationMode
    @State private var showEndQuiz = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Unified Mux Video Player
            UnifiedVideoPlayer(video: video)
                .background(Color.black)
            
            // Floating Back Button
            Button(action: { 
                presentationMode.wrappedValue.dismiss() 
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 50)  // Account for safe area
            .padding(.leading, 16)
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
        
        // Check for resume position from ProgressStore
        let resumeSeconds = ProgressStore.shared.videoProgress(videoId: video.id)?.lastPositionSec ?? 0
        
        // Build embed parameters
        var embedParams = ""
        if !siParameter.isEmpty {
            embedParams += "?si=\(siParameter)"
        }
        if resumeSeconds > 5 { // Only resume if more than 5 seconds watched
            let separator = embedParams.isEmpty ? "?" : "&"
            embedParams += "\(separator)start=\(Int(resumeSeconds))"
        }
        
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
                    // Always track elapsed time when page is visible
                    if (!document.hidden) {
                        elapsed = Math.floor((Date.now() - startTime) / 1000);
                        
                        // Send progress update
                        window.webkit.messageHandlers.progressUpdate.postMessage({
                            videoId: '\(video.id)',
                            watchedSeconds: elapsed,
                            totalDuration: videoDuration
                        });
                        
                        // Check if video is near completion (within last 30 seconds or at 90% completion)
                        if (!hasTriggeredEndQuiz && elapsed >= Math.max(videoDuration - 30, videoDuration * 0.9)) {
                            hasTriggeredEndQuiz = true;
                            window.webkit.messageHandlers.videoNearEnd.postMessage({
                                videoId: '\(video.id)',
                                elapsed: elapsed,
                                duration: videoDuration
                            });
                        }
                    }
                }, 2000); // Check every 2 seconds
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
            let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let watchedSeconds = Int(time.seconds)
                let isPlaying = player.rate > 0 // Only track progress when actually playing
                viewModel.updateVideoProgress(videoId: video.id, watchedSeconds: watchedSeconds, totalDuration: video.duration, isPlaying: isPlaying)
            }
            
            // Add seek event tracking to immediately capture manual scrubbing
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemTimeJumped,
                object: player.currentItem,
                queue: .main
            ) { _ in
                // Immediately save position when user seeks/scrubs (regardless of play state)
                let currentTime = Int(player.currentTime().seconds)
                viewModel.updateVideoProgress(videoId: video.id, watchedSeconds: currentTime, totalDuration: video.duration, isPlaying: true)
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
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Course Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    
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
                            let completionPct = calculateCompletionPercentage()
                            Text("\(Int(completionPct))%")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Progress Bar
                    let completionPct = calculateCompletionPercentage()
                    ProgressView(value: completionPct / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                    
                    // Course-specific Continue Watching - shows best video to continue with
                    if let continueVideo = getVideoToContinue() {
                        NavigationLink {
                            VideoPage(video: continueVideo, viewModel: viewModel)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Continue Watching")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Text(continueVideo.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    
                                    if let progressRecord = ProgressStore.shared.videoProgress(videoId: continueVideo.id) {
                                        if progressRecord.completed {
                                            Text("Completed")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("\(Int(progressRecord.lastPositionSec / Double(continueVideo.duration) * 100))% watched")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        Text("Start watching")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }

                    
                    Text(course.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                    
                    // Course Stats
                    HStack(spacing: 16) {
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
        .navigationBarHidden(true)
        .onAppear {
            viewModel.selectCourse(course)
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours < 1.0 {
            let minutes = Int(hours * 60)
            return "\(minutes)m"
        } else if hours == 1.0 {
            return "1h"
        } else {
            // Only round when >= 1 hour to avoid showing 1h when it's really 46 minutes
            let roundedHours = hours.rounded()
            return "\(Int(roundedHours))h"
        }
    }

    /// Returns the next incomplete video in the course based on sequence order.
    /// If all videos are complete, returns nil.  This enables the "Continue Watching"
    /// button at the top of the course detail page.
    private func calculateCompletionPercentage() -> Double {
        let totalVideos = course.videos.count
        guard totalVideos > 0 else { return 0 }
        
        let completedCount = course.videos.filter { video in
            ProgressStore.shared.videoProgress(videoId: video.id)?.completed ?? false
        }.count
        
        return Double(completedCount) / Double(totalVideos) * 100.0
    }
    
    private func getVideoToContinue() -> Video? {
        var mostRecentVideo: Video? = nil
        var mostRecentDate: Date = Date.distantPast
        
        // Look through all videos in this course to find the most recently watched incomplete one
        for video in course.videos {
            if let progressRecord = ProgressStore.shared.videoProgress(videoId: video.id) {
                // Only consider videos that have progress but are NOT completed
                if progressRecord.watchedSec > 30 && !progressRecord.completed {
                    if progressRecord.updatedAt > mostRecentDate {
                        mostRecentDate = progressRecord.updatedAt
                        mostRecentVideo = video
                    }
                }
            }
        }
        
        // If no incomplete videos with progress, return the first unwatched video
        if mostRecentVideo == nil {
            let sortedVideos = course.videos.sorted { ($0.sequenceOrder ?? 0) < ($1.sequenceOrder ?? 0) }
            for video in sortedVideos {
                let progressRecord = ProgressStore.shared.videoProgress(videoId: video.id)
                if progressRecord == nil || (!progressRecord!.completed && progressRecord!.watchedSec <= 30) {
                    return video // First unwatched or barely started video
                }
            }
        }
        
        return mostRecentVideo
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
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(videos, id: \.id) { video in
                        NavigationLink {
                            VideoPage(video: video, viewModel: viewModel)
                        } label: {
                            VideoRowView(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Remote Image View (AsyncImage alternative)

struct RemoteImageView: View {
    let url: URL?
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
        }
        .onAppear {
            guard let url = url, uiImage == nil else { return }
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let img = UIImage(data: data) {
                        await MainActor.run { self.uiImage = img }
                    }
                } catch {
                    // Keep placeholder on error
                }
            }
        }
    }
}

// MARK: - Video Row View

struct VideoRowView: View {
    // Store only the properties we need, avoid the full Video object
    let videoId: String
    let videoTitle: String
    let videoDuration: Int
    
    init(video: Video) {
        // Extract only the stored properties, avoid computed properties
        self.videoId = video.id
        self.videoTitle = video.title
        self.videoDuration = video.duration
    }
    
    var body: some View {
        // Baby step 2: Add duration and play icon
        HStack {
            AsyncImage(url: URL(string: "https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/\(videoId).jpg")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_), .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 80, height: 50)
            .cornerRadius(6)
            .overlay(
                VStack {
                    Spacer()
                    // Progress bar at bottom of thumbnail
                    if let progressRecord = ProgressStore.shared.videoProgress(videoId: videoId) {
                        let progress = progressRecord.completed ? 1.0 : (progressRecord.lastPositionSec > 0 && videoDuration > 0 ? progressRecord.lastPositionSec / Double(videoDuration) : 0.0)
                        if progress > 0 {
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(progressRecord.completed ? Color.green : Color.blue)
                                        .frame(width: geometry.size.width * progress)
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: geometry.size.width * (1 - progress))
                                }
                            }
                            .frame(height: 2)
                            .cornerRadius(1)
                            .padding(.horizontal, 2)
                            .padding(.bottom, 2)
                        }
                    }
                }
            )
            .overlay(
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(videoTitle)
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack {
                    Text("\(videoDuration / 60):\(String(format: "%02d", videoDuration % 60))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Progress indicator
                    if let progressRecord = ProgressStore.shared.videoProgress(videoId: videoId) {
                        if progressRecord.completed {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("100%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        } else if progressRecord.lastPositionSec > 0 && videoDuration > 0 {
                            Text("\(Int(progressRecord.lastPositionSec / Double(videoDuration) * 100))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}


// MARK: - Video Detail View

struct VideoDetailView: View {
    let video: Video
    @ObservedObject var viewModel: EVCoachViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingQuiz = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                if video.quiz != nil {
                    Button("Take Quiz") {
                        showingQuiz = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Video Player
                    VideoPlayerView(video: video, viewModel: viewModel)
                    
                    // Video Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Video Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text(video.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 16) {
                                Label(video.formattedDuration, systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let progress = viewModel.videoProgress[video.id] {
                                    Label("\(Int(Double(progress.watchedSeconds) / Double(video.duration) * 100))% complete", systemImage: "chart.line.uptrend.xyaxis")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text(video.description)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        // Transcript (if available)
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
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingQuiz) {
            if let quiz = video.quiz {
                QuizView(quiz: quiz, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.selectVideo(video)
        }
    }
}

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
