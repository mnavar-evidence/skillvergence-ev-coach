import SwiftUI
import AVKit

// MARK: - Enhanced Progress Indicator Components

struct MediaProgressIndicator: View {
    let progress: Double // 0.0 to 1.0
    let isCompleted: Bool
    let mediaType: MediaType
    let size: ProgressSize
    
    enum MediaType {
        case video, podcast, course
        
        var color: Color {
            switch self {
            case .video: return .blue
            case .podcast: return .purple
            case .course: return .green
            }
        }
        
        var completedColor: Color {
            switch self {
            case .video: return .blue
            case .podcast: return .purple
            case .course: return .green
            }
        }
    }
    
    enum ProgressSize {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
        
        var cornerRadius: CGFloat {
            return height / 2
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: size.height)
                        .cornerRadius(size.cornerRadius)
                    
                    // Progress fill
                    Rectangle()
                        .fill(isCompleted ? mediaType.completedColor : mediaType.color)
                        .frame(
                            width: geometry.size.width * max(0, min(1, progress)),
                            height: size.height
                        )
                        .cornerRadius(size.cornerRadius)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: size.height)
            
            if size != .small {
                HStack {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(mediaType.completedColor)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var progressText: String {
        if isCompleted {
            return "Completed"
        } else {
            return "\(Int(progress * 100))% watched"
        }
    }
}

struct CircularProgressIndicator: View {
    let progress: Double // 0.0 to 1.0
    let isCompleted: Bool
    let mediaType: MediaProgressIndicator.MediaType
    let size: CGFloat
    let showPercentage: Bool
    
    init(progress: Double, isCompleted: Bool, mediaType: MediaProgressIndicator.MediaType, size: CGFloat = 40, showPercentage: Bool = true) {
        self.progress = progress
        self.isCompleted = isCompleted
        self.mediaType = mediaType
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    isCompleted ? mediaType.completedColor : mediaType.color,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Center content
            if isCompleted {
                Image(systemName: "checkmark")
                    .foregroundColor(mediaType.completedColor)
                    .font(.system(size: size * 0.3, weight: .bold))
            } else if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct TimeProgressIndicator: View {
    let currentTime: Double
    let totalTime: Double
    let isCompleted: Bool
    
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return currentTime / totalTime
    }
    
    var body: some View {
        VStack(spacing: 4) {
            MediaProgressIndicator(
                progress: progress,
                isCompleted: isCompleted,
                mediaType: .video,
                size: .medium
            )
            
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(totalTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct CourseProgressSummary: View {
    let courseTitle: String
    let totalVideos: Int
    let completedVideos: Int
    let totalPodcasts: Int
    let completedPodcasts: Int
    let totalWatchTime: Double
    let watchedTime: Double
    
    private var overallProgress: Double {
        let totalItems = totalVideos + totalPodcasts
        let completedItems = completedVideos + completedPodcasts
        guard totalItems > 0 else { return 0 }
        return Double(completedItems) / Double(totalItems)
    }
    
    private var isCompleted: Bool {
        return completedVideos == totalVideos && completedPodcasts == totalPodcasts
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                CircularProgressIndicator(
                    progress: overallProgress,
                    isCompleted: isCompleted,
                    mediaType: .course,
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(courseTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(completedVideos + completedPodcasts) of \(totalVideos + totalPodcasts) completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if watchedTime > 0 {
                        Text("Watch time: \(formatDuration(watchedTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            MediaProgressIndicator(
                progress: overallProgress,
                isCompleted: isCompleted,
                mediaType: .course,
                size: .large
            )
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Videos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(completedVideos)/\(totalVideos)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("Podcasts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(completedPodcasts)/\(totalPodcasts)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if isCompleted {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Completed!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Live Progress Updates

class ProgressTracker: ObservableObject {
    @Published var currentProgress: Double = 0.0
    private var timer: Timer?
    private let updateInterval: TimeInterval = 1.0 // Update every second
    
    func startTracking<T>(media: T, viewModel: EVCoachViewModel) where T: MediaItem {
        stopTracking()
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.updateProgress(for: media, viewModel: viewModel)
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress<T>(for media: T, viewModel: EVCoachViewModel) where T: MediaItem {
        // This would be implemented based on the specific media type
        // For now, this is a placeholder structure
        DispatchQueue.main.async {
            // Update progress and save to persistence
            // Implementation would vary by media type
        }
    }
}

// MARK: - Protocol for Media Items

protocol MediaItem {
    var id: String { get }
    var duration: Int { get }
    var title: String { get }
}

extension Video: MediaItem {}
extension Podcast: MediaItem {}

// MARK: - Progress Extensions

extension VideoProgress {
    var progressDouble: Double {
        guard totalDuration > 0 else { return 0.0 }
        return Double(watchedSeconds) / Double(totalDuration)
    }
    
    var progressPercentage: Int {
        return Int(progressDouble * 100)
    }
}

extension PodcastProgress {
    var progressDouble: Double {
        guard totalDuration > 0 else { return 0.0 }
        return Double(playbackPosition) / Double(totalDuration)
    }
}