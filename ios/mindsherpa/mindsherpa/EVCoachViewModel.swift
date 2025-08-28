import SwiftUI
import Combine
import Foundation

// MARK: - Data Models

struct Course: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let level: String
    let estimatedHours: Double
    let videos: [Video]
    let thumbnailUrl: String?
    let sequenceOrder: Int?
    
    // Enhanced properties with defaults for backward compatibility
    var category: CourseCategory {
        // Map courses to specific categories based on title
        switch title {
        case "High Voltage Safety Foundation":
            return .electricalSafety
        case "Electrical Fundamentals":
            return .electricalFundamentals
        case "Advanced Electrical Diagnostics":
            return .evSystemComponents
        case "EV Charging Systems":
            return .batteryTechnology
        case "Advanced EV Systems":
            return .advancedEvSystems
        default:
            // Fallback logic for other courses
            if title.lowercased().contains("datacenter") || title.lowercased().contains("server") {
                return .datacenterTechnician
            } else if title.lowercased().contains("automotive") && !title.lowercased().contains("ev") {
                return .automotive
            } else if title.lowercased().contains("safety") {
                return .electricalSafety
            } else {
                return .evTechnician
            }
        }
    }
    
    var instructorName: String? { nil }
    
    var skillLevel: SkillLevel {
        // Parse from level string
        if level.lowercased().contains("1") || level.lowercased().contains("beginner") {
            return .beginner
        } else if level.lowercased().contains("2") || level.lowercased().contains("intermediate") {
            return .intermediate
        } else if level.lowercased().contains("3") || level.lowercased().contains("advanced") {
            return .advanced
        } else if level.lowercased().contains("expert") {
            return .expert
        } else {
            return .beginner
        }
    }
    
    func completionPercentage(with videoProgress: [String: VideoProgress]) -> Double {
        guard !videos.isEmpty else { return 0 }
        let completedVideos = videos.filter { video in
            videoProgress[video.id]?.isCompleted ?? false
        }.count
        return Double(completedVideos) / Double(videos.count) * 100
    }
}

struct Video: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: Int // Duration in seconds (backend provides this)
    let videoUrl: String // Supports YouTube URLs and local files
    let sequenceOrder: Int?
    let courseId: String?
    
    // Enhanced properties with defaults - these won't be in JSON from backend
    var thumbnailUrl: String? { 
        if let youtubeId = youtubeVideoId {
            return "https://img.youtube.com/vi/\(youtubeId)/hqdefault.jpg"
        }
        return nil
    }
    var transcript: String? { nil }
    var quiz: Quiz? { nil }
    var endOfVideoQuiz: EndOfVideoQuiz? { 
        // Generate end-of-video quiz based on video content
        return generateEndOfVideoQuiz()
    }
    
    // Progress tracking properties - managed by ViewModel
    var watchedSeconds: Int = 0
    var isCompleted: Bool = false
    
    // Custom CodingKeys to exclude progress properties from JSON decoding
    private enum CodingKeys: String, CodingKey {
        case id, title, description, duration, videoUrl, sequenceOrder, courseId
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        guard duration > 0 else { return 0 }
        return min(Double(watchedSeconds) / Double(duration) * 100, 100)
    }
    
    var youtubeVideoId: String? {
        if videoUrl.contains("youtube.com/watch?v=") {
            return videoUrl.components(separatedBy: "v=").last?.components(separatedBy: "&").first
        } else if videoUrl.contains("youtu.be/") {
            return videoUrl.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        return nil
    }
    
    private func generateEndOfVideoQuiz() -> EndOfVideoQuiz? {
        // Generate end-of-video quiz based on video content
        switch id {
        case "1-1": // EV Safety Pyramid - Who's Allowed to Touch
            return EndOfVideoQuiz(
                id: "\(id)-endquiz",
                title: "Safety Knowledge Check",
                questions: [
                    QuizQuestion(
                        id: "\(id)-q1",
                        question: "Who is qualified to work on high voltage EV systems?",
                        options: ["Anyone with basic electrical knowledge", "Only certified HV technicians", "Automotive mechanics with experience", "Shop supervisors only"],
                        correctAnswerIndex: 1,
                        explanation: "Only technicians with proper high voltage certification and training are qualified to work on EV systems above 50V."
                    ),
                    QuizQuestion(
                        id: "\(id)-q2",
                        question: "What voltage level requires specialized HV training?",
                        options: ["Above 12V", "Above 24V", "Above 50V", "Above 100V"],
                        correctAnswerIndex: 2,
                        explanation: "Systems above 50V DC or 30V AC are considered high voltage and require specialized training."
                    )
                ],
                passingScore: 0.8,
                isRequired: true
            )
            
        case "1-2": // High Voltage Hazards Overview
            return EndOfVideoQuiz(
                id: "\(id)-endquiz",
                title: "High Voltage Safety Check",
                questions: [
                    QuizQuestion(
                        id: "\(id)-q1",
                        question: "What is the primary danger when working with EV high voltage systems?",
                        options: ["Fire risk", "Electric shock/electrocution", "Chemical burns", "Mechanical injury"],
                        correctAnswerIndex: 1,
                        explanation: "Electric shock and electrocution are the primary hazards due to voltages typically ranging from 200-800V DC."
                    )
                ],
                passingScore: 1.0,
                isRequired: true
            )
            
        case "2-1": // Basic Circuit Components & Configuration
            return EndOfVideoQuiz(
                id: "\(id)-endquiz",
                title: "Circuit Fundamentals Check",
                questions: [
                    QuizQuestion(
                        id: "\(id)-q1",
                        question: "In a series circuit, what happens to current?",
                        options: ["Current varies at each component", "Current is the same throughout", "Current increases at each resistor", "Current decreases at each component"],
                        correctAnswerIndex: 1,
                        explanation: "In series circuits, current remains constant throughout all components."
                    )
                ],
                passingScore: 1.0,
                isRequired: true
            )
            
        case "4-1": // Battery Types and Chemistry
            return EndOfVideoQuiz(
                id: "\(id)-endquiz",
                title: "Battery Technology Check",
                questions: [
                    QuizQuestion(
                        id: "\(id)-q1",
                        question: "What is the most common EV battery chemistry?",
                        options: ["Lead-acid", "Nickel-metal hydride", "Lithium-ion", "Sodium-ion"],
                        correctAnswerIndex: 2,
                        explanation: "Lithium-ion batteries are the most common in EVs due to their high energy density and relatively light weight."
                    )
                ],
                passingScore: 1.0,
                isRequired: true
            )
            
        default:
            // Default end-of-video quiz for all videos
            return EndOfVideoQuiz(
                id: "\(id)-endquiz",
                title: "Video Comprehension Check",
                questions: [
                    QuizQuestion(
                        id: "\(id)-q1",
                        question: "Did you watch this entire video?",
                        options: ["Yes, I watched it completely", "I skipped some parts", "I only watched the beginning", "I didn't really watch it"],
                        correctAnswerIndex: 0,
                        explanation: "To get credit for this video, you need to watch it completely and understand the content."
                    )
                ],
                passingScore: 1.0, // Must get the question right
                isRequired: true
            )
        }
    }
}

struct Quiz: Codable, Identifiable {
    let id: String
    let title: String
    let questions: [QuizQuestion]
    var isCompleted: Bool = false
    var score: Double?
}

struct EndOfVideoQuiz: Codable, Identifiable {
    let id: String
    let title: String
    let questions: [QuizQuestion]
    let passingScore: Double // e.g., 0.8 for 80%
    let isRequired: Bool // Must pass to get credit for watching video
}

struct QuizQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String?
}

enum CourseCategory: String, Codable, CaseIterable {
    case evTechnician = "ev_technician"
    case datacenterTechnician = "datacenter_technician"
    case automotive = "automotive"
    case electricalSafety = "electrical_safety"
    case electricalFundamentals = "electrical_fundamentals"
    case evSystemComponents = "ev_system_components"
    case batteryTechnology = "battery_technology"
    case advancedEvSystems = "advanced_ev_systems"
    
    var displayName: String {
        switch self {
        case .evTechnician: return "EV Technician"
        case .datacenterTechnician: return "Datacenter Technician"
        case .automotive: return "Automotive"
        case .electricalSafety: return "Electrical Safety"
        case .electricalFundamentals: return "Electrical Fundamentals"
        case .evSystemComponents: return "EV System Components"
        case .batteryTechnology: return "Battery Technology"
        case .advancedEvSystems: return "Advanced EV Systems"
        }
    }
    
    var icon: String {
        switch self {
        case .evTechnician: return "bolt.car.fill"
        case .datacenterTechnician: return "server.rack"
        case .automotive: return "car.fill"
        case .electricalSafety: return "exclamationmark.triangle.fill"
        case .electricalFundamentals: return "bolt.circle.fill"
        case .evSystemComponents: return "car.rear.and.tire.marks"
        case .batteryTechnology: return "battery.100.bolt"
        case .advancedEvSystems: return "gearshape.2.fill"
        }
    }
}

enum SkillLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct VideoProgress: Codable {
    let videoId: String
    let watchedSeconds: Int
    let totalDuration: Int
    let isCompleted: Bool
    let lastWatchedAt: Date
    let deviceId: String?
    
    // Backward compatibility initializer
    init(videoId: String, watchedSeconds: Int, totalDuration: Int, isCompleted: Bool, lastWatchedAt: Date, deviceId: String? = nil) {
        self.videoId = videoId
        self.watchedSeconds = watchedSeconds
        self.totalDuration = totalDuration
        self.isCompleted = isCompleted
        self.lastWatchedAt = lastWatchedAt
        self.deviceId = deviceId ?? DeviceManager.shared.deviceId
    }
}

struct Podcast: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let audioUrl: String
    let duration: Int // in seconds
    let courseId: String
    let thumbnailUrl: String?
    let publishedAt: Date
    let episodeNumber: Int
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PodcastProgress: Codable {
    let podcastId: String
    let playbackPosition: Int // in seconds
    let totalDuration: Int
    let isCompleted: Bool
    let lastPlayedAt: Date
    let deviceId: String?
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0.0 }
        return Double(playbackPosition) / Double(totalDuration) * 100.0
    }
    
    // Backward compatibility initializer
    init(podcastId: String, playbackPosition: Int, totalDuration: Int, isCompleted: Bool, lastPlayedAt: Date, deviceId: String? = nil) {
        self.podcastId = podcastId
        self.playbackPosition = playbackPosition
        self.totalDuration = totalDuration
        self.isCompleted = isCompleted
        self.lastPlayedAt = lastPlayedAt
        self.deviceId = deviceId ?? DeviceManager.shared.deviceId
    }
}

struct CoursesResponse: Codable {
    let courses: [Course]
}

struct AIRequest: Codable {
    let question: String
    let context: String?
    let deviceId: String?
    
    init(question: String, context: String? = nil, deviceId: String? = nil) {
        self.question = question
        self.context = context
        self.deviceId = deviceId ?? DeviceManager.shared.deviceId
    }
}

struct AIResponse: Codable {
    let response: String
    let context: String?
    let timestamp: String?
    
    // Keep backward compatibility
    var answer: String {
        return response
    }
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case noResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noResponse:
            return "No response from AI service"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - API Service

class APIService {
    private let baseURL = AppConfig.apiURL
    private let session = URLSession.shared
    
    func fetchCourses() -> AnyPublisher<CoursesResponse, Error> {
        guard let url = URL(string: "\(baseURL)/courses") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CoursesResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func askAI(question: String, context: String? = nil) -> AnyPublisher<AIResponse, Error> {
        guard let url = URL(string: "\(baseURL)/ai/ask") else {
            return Fail(error: AIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let request = AIRequest(question: question, context: context)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: AIResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    return AIError.serverError("Failed to decode response: \(decodingError.localizedDescription)")
                } else if let urlError = error as? URLError {
                    return AIError.serverError("Network error: \(urlError.localizedDescription)")
                } else {
                    return error
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateVideoProgress(videoId: String, watchedSeconds: Int, totalDuration: Int) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/video/progress") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        let progress = VideoProgress(
            videoId: videoId,
            watchedSeconds: watchedSeconds,
            totalDuration: totalDuration,
            isCompleted: watchedSeconds >= totalDuration - 10, // Consider completed if within 10 seconds of end
            lastWatchedAt: Date()
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(progress)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .map { _ in () }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getVideoProgress(videoId: String) -> AnyPublisher<VideoProgress?, Error> {
        guard let url = URL(string: "\(baseURL)/video/progress/\(videoId)") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: VideoProgress?.self, decoder: JSONDecoder())
            .catch { _ in Just(nil).setFailureType(to: Error.self) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Analytics Methods
    
    func sendAnalyticsEvents(_ events: [AnalyticsEventData]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/analytics/events") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(events)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .map { _ in () } // Convert to Void
            .catch { _ in Just(()).setFailureType(to: Error.self) } // Don't fail on analytics errors
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - View Model

class EVCoachViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var videos: [Video] = []
    @Published var currentVideo: Video?
    @Published var currentCourse: Course?
    @Published var isLoading = false
    @Published var aiResponse: String = ""
    @Published var isAILoading = false
    @Published var aiError: String?
    @Published var videoProgress: [String: VideoProgress] = [:]
    @Published var podcasts: [Podcast] = []
    @Published var podcastProgress: [String: PodcastProgress] = [:]
    @Published var selectedCategory: CourseCategory?
    @Published var shouldShowEndQuiz: Bool = false
    @Published var completedVideos: Set<String> = [] // Track videos with completed end quizzes
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var progressUpdateTimer: Timer?
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Persistence Keys
    private let videoProgressKey = "VideoProgress"
    private let completedVideosKey = "CompletedVideos"
    private let podcastProgressKey = "PodcastProgress"
    
    init() {
        loadProgressFromStorage()
        analyticsManager.track(.appLaunched)
    }
    
    func loadCourses() {
        isLoading = true
        
        apiService.fetchCourses()
            .sink(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                
                if case .failure(let error) = completion {
                    print("Failed to fetch courses: \(error)")
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {
                    self?.courses = response.courses
                    self?.videos = response.courses.flatMap { $0.videos }
                    self?.loadPodcasts()
                }
            })
            .store(in: &cancellables)
    }
    
    func askAI(question: String) {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            aiError = "Please enter a question"
            return
        }
        
        isAILoading = true
        aiError = nil
        
        // Create context from current course content
        let context = createContext()
        
        // Track AI question
        analyticsManager.track(.aiQuestionAsked(
            question: question,
            context: context,
            courseId: currentCourse?.id
        ))
        
        let startTime = Date()
        apiService.askAI(question: question, context: context)
            .sink(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isAILoading = false
                }
                
                if case .failure(let error) = completion {
                    DispatchQueue.main.async {
                        self?.aiError = error.localizedDescription
                        self?.aiResponse = ""
                    }
                }
            }, receiveValue: { [weak self] response in
                let responseTime = Date().timeIntervalSince(startTime)
                
                DispatchQueue.main.async {
                    self?.aiResponse = response.answer
                    self?.aiError = nil
                    
                    // Track AI response received
                    self?.analyticsManager.track(.aiResponseReceived(
                        question: question,
                        response: response.answer,
                        responseTime: responseTime
                    ))
                }
            })
            .store(in: &cancellables)
    }
    
    private func createContext() -> String {
        var contextParts: [String] = []
        
        // Add current video context if available
        if let currentVideo = currentVideo {
            contextParts.append("Current video: \(currentVideo.title) - \(currentVideo.description)")
        }
        
        // Add course titles and descriptions
        let courseContext = courses.map { "Course: \($0.title) - \($0.description)" }.joined(separator: ". ")
        if !courseContext.isEmpty {
            contextParts.append(courseContext)
        }
        
        return contextParts.joined(separator: ". ")
    }
    
    func clearAIResponse() {
        aiResponse = ""
        aiError = nil
    }
    
    // MARK: - Video Management
    
    func selectCourse(_ course: Course) {
        currentCourse = course
        videos = course.videos
        loadVideoProgress(for: course.videos)
    }
    
    func selectVideo(_ video: Video) {
        currentVideo = video
        // Reset end quiz state for new video
        shouldShowEndQuiz = false
        
        // Track video started
        analyticsManager.trackVideoEvent(.videoStarted(
            videoId: video.id,
            courseId: video.courseId ?? "",
            title: video.title
        ))
    }
    
    func loadVideoProgress(for videos: [Video]) {
        for video in videos {
            apiService.getVideoProgress(videoId: video.id)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load progress for video \(video.id): \(error)")
                    }
                }, receiveValue: { [weak self] progress in
                    if let progress = progress {
                        self?.videoProgress[video.id] = progress
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    func updateVideoProgress(videoId: String, watchedSeconds: Int, totalDuration: Int) {
        // Update local state immediately
        let progress = VideoProgress(
            videoId: videoId,
            watchedSeconds: watchedSeconds,
            totalDuration: totalDuration,
            isCompleted: watchedSeconds >= totalDuration - 10,
            lastWatchedAt: Date()
        )
        videoProgress[videoId] = progress
        
        // Track video completion if completed
        if progress.isCompleted {
            analyticsManager.trackVideoEvent(.videoCompleted(
                videoId: videoId,
                courseId: currentVideo?.courseId ?? "",
                totalDuration: totalDuration
            ))
        }
        
        // Save progress to local storage immediately
        saveProgressToStorage()
        
        // Update backend
        apiService.updateVideoProgress(videoId: videoId, watchedSeconds: watchedSeconds, totalDuration: totalDuration)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to update video progress: \(error)")
                }
            }, receiveValue: { _ in
                // Progress updated successfully
            })
            .store(in: &cancellables)
    }
    
    func startVideoProgressTracking(for videoId: String, duration: Int) {
        stopVideoProgressTracking()
        
        var currentTime = videoProgress[videoId]?.watchedSeconds ?? 0
        
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            currentTime += 5
            self?.updateVideoProgress(videoId: videoId, watchedSeconds: currentTime, totalDuration: duration)
        }
    }
    
    func stopVideoProgressTracking() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }
    
    // MARK: - End of Video Quiz Management
    
    func triggerEndOfVideoQuiz(videoId: String, watchedSeconds: Int, totalDuration: Int) {
        // Only trigger if this video has an end quiz and user hasn't completed it yet
        guard let currentVideo = currentVideo,
              currentVideo.id == videoId,
              currentVideo.endOfVideoQuiz != nil,
              !completedVideos.contains(videoId) else { return }
        
        // Update progress before showing quiz
        updateVideoProgress(videoId: videoId, watchedSeconds: watchedSeconds, totalDuration: totalDuration)
        
        // Trigger the quiz
        shouldShowEndQuiz = true
    }
    
    func completeEndOfVideoQuiz(videoId: String, passed: Bool) {
        if passed {
            // Mark video as completed - user gets credit for watching
            completedVideos.insert(videoId)
            
            // Save completed videos to storage immediately
            saveProgressToStorage()
            
            // Mark video progress as completed in the backend
            if let currentVideo = currentVideo, currentVideo.id == videoId {
                updateVideoProgress(videoId: videoId, watchedSeconds: currentVideo.duration, totalDuration: currentVideo.duration)
            }
        }
        // If they didn't pass, no credit is given - they can retake the quiz
    }
    
    func getCoursesByCategory(_ category: CourseCategory) -> [Course] {
        return courses.filter { $0.category == category }
    }
    
    var coursesGroupedByCategory: [CourseCategory: [Course]] {
        Dictionary(grouping: courses, by: { $0.category })
    }
    
    // MARK: - Progress Persistence
    
    private func loadProgressFromStorage() {
        // Load video progress
        if let progressData = UserDefaults.standard.data(forKey: videoProgressKey),
           let decodedProgress = try? JSONDecoder().decode([String: VideoProgress].self, from: progressData) {
            videoProgress = decodedProgress
        }
        
        // Load completed videos
        if let completedData = UserDefaults.standard.data(forKey: completedVideosKey),
           let decodedCompleted = try? JSONDecoder().decode(Set<String>.self, from: completedData) {
            completedVideos = decodedCompleted
        }
        
        // Load podcast progress
        if let podcastData = UserDefaults.standard.data(forKey: podcastProgressKey),
           let decodedPodcastProgress = try? JSONDecoder().decode([String: PodcastProgress].self, from: podcastData) {
            podcastProgress = decodedPodcastProgress
        }
    }
    
    private func saveProgressToStorage() {
        // Save video progress
        if let progressData = try? JSONEncoder().encode(videoProgress) {
            UserDefaults.standard.set(progressData, forKey: videoProgressKey)
        }
        
        // Save completed videos
        if let completedData = try? JSONEncoder().encode(completedVideos) {
            UserDefaults.standard.set(completedData, forKey: completedVideosKey)
        }
        
        // Save podcast progress
        if let podcastData = try? JSONEncoder().encode(podcastProgress) {
            UserDefaults.standard.set(podcastData, forKey: podcastProgressKey)
        }
        
        // Ensure data is written to disk
        UserDefaults.standard.synchronize()
    }
    
    func clearAllProgress() {
        videoProgress.removeAll()
        completedVideos.removeAll()
        podcastProgress.removeAll()
        UserDefaults.standard.removeObject(forKey: videoProgressKey)
        UserDefaults.standard.removeObject(forKey: completedVideosKey)
        UserDefaults.standard.removeObject(forKey: podcastProgressKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Enhanced Progress Methods
    
    func updateVideoProgress(videoId: String, currentTime: Double, totalDuration: Double, isCompleted: Bool = false) {
        let watchedSeconds = Int(currentTime)
        let totalSeconds = Int(totalDuration)
        
        let progress = VideoProgress(
            videoId: videoId,
            watchedSeconds: watchedSeconds,
            totalDuration: totalSeconds,
            isCompleted: isCompleted || (currentTime >= totalDuration * 0.95), // Auto-complete at 95%
            lastWatchedAt: Date(),
            deviceId: DeviceManager.shared.deviceId
        )
        
        videoProgress[videoId] = progress
        
        if progress.isCompleted {
            completedVideos.insert(videoId)
        }
        
        saveProgressToStorage()
        
        // Track analytics
        AnalyticsManager.shared.track(.videoProgressUpdate(
            videoId: videoId,
            progressPercentage: Int(progress.progressDouble * 100),
            watchedSeconds: watchedSeconds,
            totalDuration: totalSeconds
        ))
        
        if progress.isCompleted && !completedVideos.contains(videoId) {
            AnalyticsManager.shared.track(.videoCompleted(
                videoId: videoId,
                courseId: getCourseId(for: videoId) ?? "",
                totalDuration: totalSeconds
            ))
        }
    }
    
    func updatePodcastProgress(podcastId: String, currentTime: Double, totalDuration: Double, isCompleted: Bool = false) {
        let playbackSeconds = Int(currentTime)
        let totalSeconds = Int(totalDuration)
        
        let progress = PodcastProgress(
            podcastId: podcastId,
            playbackPosition: playbackSeconds,
            totalDuration: totalSeconds,
            isCompleted: isCompleted || (currentTime >= totalDuration * 0.95), // Auto-complete at 95%
            lastPlayedAt: Date(),
            deviceId: DeviceManager.shared.deviceId
        )
        
        podcastProgress[podcastId] = progress
        saveProgressToStorage()
        
        // Track analytics
        AnalyticsManager.shared.track(.podcastProgressUpdate(
            podcastId: podcastId,
            progressPercentage: Int(progress.progressPercentage),
            playbackPosition: playbackSeconds,
            totalDuration: totalSeconds
        ))
        
        if progress.isCompleted {
            AnalyticsManager.shared.track(.podcastCompleted(
                podcastId: podcastId,
                courseId: getPodcastCourseId(for: podcastId) ?? "",
                totalDuration: totalSeconds
            ))
        }
    }
    
    func getCourseProgressSummary(courseId: String) -> (videosCompleted: Int, totalVideos: Int, podcastsCompleted: Int, totalPodcasts: Int, overallProgress: Double, totalWatchTime: Double) {
        let courseVideos = videos.filter { $0.courseId == courseId }
        let coursePodcasts = podcasts.filter { $0.courseId == courseId }
        
        let videosCompleted = courseVideos.filter { completedVideos.contains($0.id) }.count
        let podcastsCompleted = coursePodcasts.filter { podcastProgress[$0.id]?.isCompleted == true }.count
        
        let totalVideos = courseVideos.count
        let totalPodcasts = coursePodcasts.count
        let totalItems = totalVideos + totalPodcasts
        let completedItems = videosCompleted + podcastsCompleted
        
        let overallProgress = totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0.0
        
        // Calculate total watch time
        var totalWatchTime: Double = 0
        for video in courseVideos {
            if let progress = videoProgress[video.id] {
                totalWatchTime += Double(progress.watchedSeconds)
            }
        }
        for podcast in coursePodcasts {
            if let progress = podcastProgress[podcast.id] {
                totalWatchTime += Double(progress.playbackPosition)
            }
        }
        
        return (videosCompleted, totalVideos, podcastsCompleted, totalPodcasts, overallProgress, totalWatchTime)
    }
    
    private func getCourseId(for videoId: String) -> String? {
        return videos.first { $0.id == videoId }?.courseId
    }
    
    private func getPodcastCourseId(for podcastId: String) -> String? {
        return podcasts.first { $0.id == podcastId }?.courseId
    }
    
    func getVideoProgress(for videoId: String) -> VideoProgress? {
        return videoProgress[videoId]
    }
    
    func getPodcastProgress(for podcastId: String) -> PodcastProgress? {
        return podcastProgress[podcastId]
    }
    
    func isVideoCompleted(_ videoId: String) -> Bool {
        return completedVideos.contains(videoId) || videoProgress[videoId]?.isCompleted == true
    }
    
    func isPodcastCompleted(_ podcastId: String) -> Bool {
        return podcastProgress[podcastId]?.isCompleted == true
    }
    
    // MARK: - Podcast Methods
    
    func loadPodcasts() {
        // For now, use sample podcast data - in the future this will call API
        let samplePodcasts = [
            Podcast(
                id: "podcast-1-1",
                title: "Understanding EV Safety Fundamentals",
                description: "A deep dive conversation about the core principles of electric vehicle safety, covering who can work on high voltage systems and why proper training matters.",
                audioUrl: "https://example.com/podcasts/ev-safety-fundamentals.mp3",
                duration: 1680, // 28 minutes
                courseId: "1",
                thumbnailUrl: nil,
                publishedAt: Date(),
                episodeNumber: 1
            ),
            Podcast(
                id: "podcast-2-1", 
                title: "Electrical Circuits Explained Simply",
                description: "Breaking down complex electrical concepts into easy-to-understand analogies and practical examples for EV technicians.",
                audioUrl: "https://example.com/podcasts/electrical-circuits-explained.mp3",
                duration: 1320, // 22 minutes
                courseId: "2",
                thumbnailUrl: nil,
                publishedAt: Date(),
                episodeNumber: 2
            ),
            Podcast(
                id: "podcast-3-1",
                title: "Advanced Diagnostics Deep Dive",
                description: "Expert discussion on using oscilloscopes and advanced measurement tools for EV system diagnostics.",
                audioUrl: "https://example.com/podcasts/advanced-diagnostics.mp3", 
                duration: 1920, // 32 minutes
                courseId: "3",
                thumbnailUrl: nil,
                publishedAt: Date(),
                episodeNumber: 3
            )
        ]
        
        self.podcasts = samplePodcasts
    }
    
    func updatePodcastProgress(podcastId: String, playbackPosition: Int, totalDuration: Int) {
        let progress = PodcastProgress(
            podcastId: podcastId,
            playbackPosition: playbackPosition,
            totalDuration: totalDuration,
            isCompleted: playbackPosition >= totalDuration - 30, // Consider completed if within 30 seconds of end
            lastPlayedAt: Date()
        )
        
        podcastProgress[podcastId] = progress
        
        // Track podcast completion if completed
        if progress.isCompleted {
            if let podcast = podcasts.first(where: { $0.id == podcastId }) {
                analyticsManager.trackPodcastEvent(.podcastCompleted(
                    podcastId: podcastId,
                    courseId: podcast.courseId,
                    totalDuration: totalDuration
                ))
            }
        }
        
        saveProgressToStorage()
    }
}

