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
    let podcasts: [Podcast]? // Optional for backward compatibility
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
    
    // Manual initializer for creating Course objects programmatically
    init(id: String, title: String, description: String, level: String, estimatedHours: Double, videos: [Video], podcasts: [Podcast]? = nil, thumbnailUrl: String? = nil, sequenceOrder: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.level = level
        self.estimatedHours = estimatedHours
        self.videos = videos
        self.podcasts = podcasts
        self.thumbnailUrl = thumbnailUrl
        self.sequenceOrder = sequenceOrder
    }
    
    // Custom decoder to handle missing podcasts field gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        level = try container.decode(String.self, forKey: .level)
        estimatedHours = try container.decode(Double.self, forKey: .estimatedHours)
        videos = try container.decode([Video].self, forKey: .videos)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        sequenceOrder = try container.decodeIfPresent(Int.self, forKey: .sequenceOrder)
        
        // Handle podcasts field that may be missing from API response
        podcasts = try container.decodeIfPresent([Podcast].self, forKey: .podcasts)
    }
    
    // CodingKeys for JSON decoding
    private enum CodingKeys: String, CodingKey {
        case id, title, description, level, estimatedHours, videos, podcasts, thumbnailUrl, sequenceOrder
    }
    
}

struct Video: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let duration: Int // Duration in seconds (backend provides this)
    let videoUrl: String // Supports YouTube URLs and local files (legacy)
    let muxPlaybackId: String? // Mux playback ID for streaming
    let sequenceOrder: Int?
    let courseId: String?
    
    // Enhanced properties with defaults - these won't be in JSON from backend
    var thumbnailUrl: String? { 
        // Use uploaded video thumbnails
        return "https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/\(id).jpg"
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
        case id, title, description, duration, videoUrl, muxPlaybackId, sequenceOrder, courseId
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
    
    // Legacy YouTube support removed - all videos now use Mux
    
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

struct Podcast: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: Int // Duration in seconds
    let audioUrl: String // Can be traditional URL or Mux URL (mux://playbackId)
    let sequenceOrder: Int?
    let courseId: String?
    let episodeNumber: Int?
    let thumbnailUrl: String? // Individual episode thumbnail URL
    
    // Enhanced properties
    var transcript: String? { nil }
    var showNotes: String? { nil }
    
    // Mux support properties
    var muxPlaybackId: String? {
        // Extract Mux playback ID if audioUrl starts with "mux://"
        if audioUrl.hasPrefix("mux://") {
            return String(audioUrl.dropFirst(6))
        }
        return nil
    }
    
    var isMuxPodcast: Bool {
        return audioUrl.hasPrefix("mux://")
    }
    
    // Progress tracking properties - managed by ViewModel
    var playbackPosition: Int = 0
    var isCompleted: Bool = false
    
    // Custom CodingKeys to exclude progress properties from JSON decoding
    private enum CodingKeys: String, CodingKey {
        case id, title, description, duration, audioUrl, sequenceOrder, courseId, episodeNumber, thumbnailUrl
    }
}

struct PodcastProgress: Codable {
    let podcastId: String
    let playbackPosition: Int
    let totalDuration: Int
    let isCompleted: Bool
    let lastPlayedAt: Date
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
}

struct CoursesResponse: Codable {
    let courses: [Course]
}

struct PodcastsResponse: Codable {
    let podcasts: [Podcast]
}

struct AIRequest: Codable {
    let question: String
    let context: String?
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
    private let session = URLSession.shared
    
    func fetchCourses() -> AnyPublisher<CoursesResponse, Error> {
        let primaryURL = "\(AppConfig.apiURL)/courses"
        let fallbackURL = "\(AppConfig.fallbackBaseURL)/api/courses"
        
        return fetchFromURL(primaryURL)
            .catch { _ in
                print("⚠️ Primary URL failed, trying fallback...")
                return self.fetchFromURL(fallbackURL)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchFromURL(_ urlString: String) -> AnyPublisher<CoursesResponse, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        print("🌐 Fetching courses from: \(urlString)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CoursesResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchPodcasts() -> AnyPublisher<PodcastsResponse, Error> {
        let primaryURL = "\(AppConfig.apiURL)/podcasts"
        let fallbackURL = "\(AppConfig.fallbackBaseURL)/api/podcasts"
        
        return fetchPodcastsFromURL(primaryURL)
            .catch { _ in
                print("⚠️ Primary URL failed for podcasts, trying fallback...")
                return self.fetchPodcastsFromURL(fallbackURL)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchPodcastsFromURL(_ urlString: String) -> AnyPublisher<PodcastsResponse, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PodcastsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func askAI(question: String, context: String? = nil) -> AnyPublisher<AIResponse, Error> {
        guard let url = URL(string: "\(AppConfig.apiURL)/ai/ask") else {
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
        guard let url = URL(string: "\(AppConfig.apiURL)/video/progress") else {
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
        guard let url = URL(string: "\(AppConfig.apiURL)/video/progress/\(videoId)") else {
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
    
    func sendAnalyticsEvents(_ events: [AnalyticsEventData]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(AppConfig.apiURL)/analytics") else {
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
            .map { _ in () }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - View Model

class EVCoachViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var videos: [Video] = []
    @Published var podcasts: [Podcast] = []
    @Published var currentVideo: Video?
    @Published var currentPodcast: Podcast?
    @Published var currentCourse: Course?
    @Published var isLoading = false
    @Published var aiResponse: String = ""
    @Published var isAILoading = false
    @Published var aiError: String?
    @Published var videoProgress: [String: VideoProgress] = [:]
    @Published var podcastProgress: [String: PodcastProgress] = [:]
    @Published var selectedCategory: CourseCategory?
    @Published var shouldShowEndQuiz: Bool = false
    @Published var completedVideos: Set<String> = [] // Track videos with completed end quizzes
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var progressUpdateTimer: Timer?
    
    func loadCourses() {
        isLoading = true
        
        // Load courses first (required)
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
                    self?.isLoading = false
                    
                    // Extract podcasts from courses instead of separate API call
                    self?.extractPodcastsFromCourses()
                }
            })
            .store(in: &cancellables)
    }
    
    private func extractPodcastsFromCourses() {
        // Extract all podcasts from courses that have them
        var allPodcasts: [Podcast] = []
        
        for course in courses {
            if let coursePodcasts = course.podcasts {
                allPodcasts.append(contentsOf: coursePodcasts)
            }
        }
        
        // If no podcasts found in courses, use sample data
        if allPodcasts.isEmpty {
            print("📻 No podcasts found in courses, using sample data")
            allPodcasts = createSamplePodcasts()
        } else {
            print("📻 Found \(allPodcasts.count) podcasts in courses")
        }
        
        self.podcasts = allPodcasts
    }
    
    // Legacy method - kept for backward compatibility but no longer used
    private func loadPodcasts() {
        // This method is deprecated - podcasts now come from courses
        extractPodcastsFromCourses()
    }
    
    private func createSamplePodcasts() -> [Podcast] {
        return [
            // Course 1: High Voltage Safety Foundation (4 episodes)
            Podcast(
                id: "podcast-1-1", 
                title: "High Voltage Safety Fundamentals", 
                description: "Essential safety protocols and risk assessment for working with high voltage EV systems", 
                duration: 1680, 
                audioUrl: "mux://i4QEDflyN1yzdnioCjcVDiNZeTOQbLjwsmkm00bjlsBo",
                sequenceOrder: 1, 
                courseId: "1",
                episodeNumber: 1,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/hv-safety-fundamentals.jpg"
            ),
            Podcast(
                id: "podcast-1-2", 
                title: "Personal Protective Equipment for EV Technicians", 
                description: "Complete guide to PPE selection, usage, and maintenance for high voltage work", 
                duration: 1440, 
                audioUrl: "mux://oXa02RGavP5mdWedJ279l4g02z01gkioUAM9mQEdxAsq9g",
                sequenceOrder: 2, 
                courseId: "1",
                episodeNumber: 2,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-ppe-guide.jpg"
            ),
            Podcast(
                id: "podcast-1-3", 
                title: "Lockout/Tagout Procedures for EVs", 
                description: "Step-by-step LOTO procedures specific to electric vehicle maintenance and repair", 
                duration: 1320, 
                audioUrl: "mux://LN73nvqZArkimShNSSuIuROSuJmOjTZYcvy02bGxhz02U",
                sequenceOrder: 3, 
                courseId: "1",
                episodeNumber: 3,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-loto-procedures.jpg"
            ),
            Podcast(
                id: "podcast-1-4", 
                title: "Emergency Response for EV Incidents", 
                description: "Critical emergency procedures for high voltage incidents and fire safety protocols", 
                duration: 1560, 
                audioUrl: "mux://QbrH2jxPRfrWncstf4VDsqwQ01017KGu1BDJ02x8ePixOg",
                sequenceOrder: 4, 
                courseId: "1",
                episodeNumber: 4,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-emergency-response.jpg"
            ),
            
            // Course 2: Electrical Fundamentals (4 episodes)
            Podcast(
                id: "podcast-2-1", 
                title: "From Spark Plugs to Silent Power: EV Evolution", 
                description: "Explore the evolution from traditional combustion engines to electric powertrains", 
                duration: 1650, 
                audioUrl: "mux://LyloSfhndkLxpz024h1Fu6rBVRJupQmTODYh55cMm3gs",
                sequenceOrder: 1, 
                courseId: "2",
                episodeNumber: 1,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/spark-plugs-episode.jpg"
            ),
            Podcast(
                id: "podcast-2-2", 
                title: "DC vs AC: Understanding EV Power Systems", 
                description: "Deep dive into direct current vs alternating current in electric vehicle applications", 
                duration: 1380, 
                audioUrl: "mux://7xaPgCXLyOeJEU801PxiOKRaC00YT4iAi7K2ade400bRJc",
                sequenceOrder: 2, 
                courseId: "2",
                episodeNumber: 2,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/dc-vs-ac-power.jpg"
            ),
            Podcast(
                id: "podcast-2-3", 
                title: "Ohm's Law in Electric Vehicle Circuits", 
                description: "Practical applications of electrical fundamentals in EV system diagnostics", 
                duration: 1260, 
                audioUrl: "mux://wi6uJiUJtKLLrmr01KG52G7HSnUz4fSM446r00DZMyz14",
                sequenceOrder: 3, 
                courseId: "2",
                episodeNumber: 3,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ohms-law-ev.jpg"
            ),
            Podcast(
                id: "podcast-2-4", 
                title: "Electrifying the Road: EV Motor Physics", 
                description: "Understanding electric motor physics, power delivery, and efficiency principles", 
                duration: 1800, 
                audioUrl: "mux://yywkj01kgEEY02M7L00PuybVyQcvDTEagEtH86kenvqt8w",
                sequenceOrder: 4, 
                courseId: "2",
                episodeNumber: 4,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-motors-episode.jpg"
            ),
            
            // Course 3: EV System Components (3 episodes)
            Podcast(
                id: "podcast-3-1", 
                title: "EV Powertrain Architecture Deep Dive", 
                description: "Comprehensive overview of electric vehicle powertrain components and integration", 
                duration: 1620, 
                audioUrl: "mux://gJw7gTkf4xwNAzY6zMp00EKTi200UcRaLMu7UF01802AwmI",
                sequenceOrder: 1, 
                courseId: "3",
                episodeNumber: 1,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-powertrain-arch.jpg"
            ),
            Podcast(
                id: "podcast-3-2", 
                title: "Inverters and Power Electronics", 
                description: "Understanding DC-AC conversion, motor controllers, and power management systems", 
                duration: 1500, 
                audioUrl: "mux://LEp1g5FWhZF1d7HcAFKYfBMLt82abDCFxqNh6TNNibg",
                sequenceOrder: 2, 
                courseId: "3",
                episodeNumber: 2,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/inverters-power-electronics.jpg"
            ),
            Podcast(
                id: "podcast-3-3", 
                title: "Regenerative Braking Systems", 
                description: "How EVs capture kinetic energy and convert it back to electrical power", 
                duration: 1200, 
                audioUrl: "mux://rBNRQgJd0002pHnYED57YYThbNjPhndVJDdVks1pIbV00E",
                sequenceOrder: 3, 
                courseId: "3",
                episodeNumber: 3,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/regenerative-braking.jpg"
            ),
            
            // Course 4: EV Charging Systems (4 episodes)
            Podcast(
                id: "podcast-4-1", 
                title: "Demystifying EV Batteries: Chemistry to Performance", 
                description: "From lead-acid to lithium-ion, understanding battery technologies and energy storage", 
                duration: 1920, 
                audioUrl: "mux://4hS0142g7wTaRPJZt7rj01BvK8j45wNGhYMhMfu9CynX4",
                sequenceOrder: 1, 
                courseId: "4",
                episodeNumber: 1,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-batteries-episode.jpg"
            ),
            Podcast(
                id: "podcast-4-2", 
                title: "Charging Standards and Protocols", 
                description: "Understanding Level 1, 2, and DC fast charging standards and communication protocols", 
                duration: 1740, 
                audioUrl: "mux://zKO2aEoOlkL59Y00EiPZNq3TUUeJ6XFb4XG004XBQoHD00",
                sequenceOrder: 2, 
                courseId: "4",
                episodeNumber: 2,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/charging-standards.jpg"
            ),
            Podcast(
                id: "podcast-4-3", 
                title: "Battery Management Systems Explained", 
                description: "How BMS monitors, protects, and optimizes battery performance and longevity", 
                duration: 1440, 
                audioUrl: "mux://hDJ1ctkmzHpafohwPdSyWoO019OYjhUdVwuvhrKQEf014",
                sequenceOrder: 3, 
                courseId: "4",
                episodeNumber: 3,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/battery-management-systems.jpg"
            ),
            Podcast(
                id: "podcast-4-4", 
                title: "Thermal Management in EV Charging", 
                description: "Heat generation, cooling systems, and thermal challenges in high-power charging", 
                duration: 1320, 
                audioUrl: "mux://ox8w3uqDkMICb5KToyQE8XbhpVor7XP7wOZqrCMlKhU",
                sequenceOrder: 4, 
                courseId: "4",
                episodeNumber: 4,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/thermal-management.jpg"
            ),
            
            // Course 5: Advanced EV Systems (3 episodes)
            Podcast(
                id: "podcast-5-1", 
                title: "Vehicle-to-Grid Technology", 
                description: "How EVs can feed power back to the electrical grid and smart energy management", 
                duration: 1680, 
                audioUrl: "mux://lnY6lcvRpV1eQxXIWQ9CS3L6sE53WppNh4SdpLa98nI",
                sequenceOrder: 1, 
                courseId: "5",
                episodeNumber: 1,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/vehicle-to-grid.jpg"
            ),
            Podcast(
                id: "podcast-5-2", 
                title: "Autonomous Driving and EV Integration", 
                description: "The intersection of self-driving technology and electric vehicle systems", 
                duration: 1560, 
                audioUrl: "mux://di1HuLrR5qSCxCVTkf01WbIvCKIJODqP9l4IV1MeilRA",
                sequenceOrder: 2, 
                courseId: "5",
                episodeNumber: 2,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/autonomous-ev-integration.jpg"
            ),
            Podcast(
                id: "podcast-5-3", 
                title: "The Future of Electric Transportation", 
                description: "Emerging technologies, solid-state batteries, and the next generation of EVs", 
                duration: 1800, 
                audioUrl: "mux://Pecxte8db863F3TdikLFCf3QEFnol4ODTq4LJBY013pA",
                sequenceOrder: 3, 
                courseId: "5",
                episodeNumber: 3,
                thumbnailUrl: "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/future-ev-transport.jpg"
            )
        ]
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
                DispatchQueue.main.async {
                    self?.aiResponse = response.answer
                    self?.aiError = nil
                }
            })
            .store(in: &cancellables)
    }
    
    private func createContext() -> String {
        var contextParts: [String] = []
        
        // Add current video context if available
        if let currentVideo = currentVideo {
            contextParts.append("Currently watching: \(currentVideo.title)")
        }
        
        // Add focused context about EV training
        contextParts.append("You are an AI assistant for an EV technician training app covering high voltage safety, electrical fundamentals, EV system components, charging systems, and advanced EV technologies.")
        
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
    
    func updateVideoProgress(videoId: String, watchedSeconds: Int, totalDuration: Int, isPlaying: Bool = true) {
        // Update local state immediately
        let progress = VideoProgress(
            videoId: videoId,
            watchedSeconds: watchedSeconds,
            totalDuration: totalDuration,
            isCompleted: watchedSeconds >= totalDuration - 10,
            lastWatchedAt: Date()
        )
        videoProgress[videoId] = progress
        
        // Also update new progress store with real progress data (async to avoid MainActor issues)
        // Only update watch time accumulation when actually playing
        if let currentCourse = currentCourse {
            Task { @MainActor in
                ProgressStore.shared.updateVideoProgress(
                    videoId: videoId,
                    courseId: currentCourse.id,
                    currentTime: Double(watchedSeconds),
                    duration: Double(totalDuration),
                    isPlaying: isPlaying
                )
            }
        }

        // If the video has effectively been completed (e.g. user watched nearly the
        // entire duration), also mark it as completed in the completedVideos set.
        // Without adding the video ID here, course completion indicators will only
        // update after the user passes an end-of-video quiz. By inserting the
        // video into `completedVideos` when progress.isCompleted is true, the
        // UI can reflect completed status immediately and persist it across
        // sessions.  The end-of-video quiz will still run and can update this
        // set as appropriate.
        if progress.isCompleted {
            completedVideos.insert(videoId)
        }
        
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

    // MARK: - Course Progress Summary

    /// Returns a summary of progress and watch time for a specific course.
    ///
    /// This function normalises course identifiers, as some backends prefix
    /// course IDs with "course-" (e.g. "course-1") while others use just
    /// numeric strings (e.g. "1").  It counts the number of completed
    /// videos and podcasts, calculates the overall completion fraction and
    /// sums the watched seconds for all media in the course.  Use this
    /// summary to drive the CourseProgressSummary view.
    func getCourseProgressSummary(courseId: String) -> (videosCompleted: Int, totalVideos: Int, podcastsCompleted: Int, totalPodcasts: Int, overallProgress: Double, totalWatchTime: Double) {
        func normalize(_ id: String?) -> String {
            guard let id = id else { return "" }
            return id.replacingOccurrences(of: "course-", with: "")
        }
        let normalizedCourseId = normalize(courseId)
        let courseVideos = videos.filter { normalize($0.courseId) == normalizedCourseId }
        let coursePodcasts = podcasts.filter { normalize($0.courseId) == normalizedCourseId }
        
        // A video is considered completed if it appears in the completedVideos set
        // OR if its corresponding VideoProgress entry reports isCompleted == true.
        let videosCompleted = courseVideos.filter { video in
            completedVideos.contains(video.id) || (videoProgress[video.id]?.isCompleted ?? false)
        }.count

        let totalVideos = courseVideos.count
        let totalPodcasts = coursePodcasts.count
        
        // A podcast is considered completed if its PodcastProgress entry reports
        // isCompleted == true.
        let podcastsCompleted = coursePodcasts.filter { podcast in
            podcastProgress[podcast.id]?.isCompleted ?? false
        }.count
        let totalItems = totalVideos + totalPodcasts
        let completedItems = videosCompleted + podcastsCompleted
        let overallProgress = totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0.0
        var totalWatchTime: Double = 0
        for video in courseVideos {
            if let progress = videoProgress[video.id] {
                totalWatchTime += Double(progress.watchedSeconds)
            }
        }
        return (videosCompleted, totalVideos, podcastsCompleted, totalPodcasts, overallProgress, totalWatchTime)
    }
    
    // MARK: - Podcast Progress Tracking
    
    func updatePodcastProgress(podcastId: String, playbackPosition: Int, totalDuration: Int) {
        let progress = PodcastProgress(
            podcastId: podcastId,
            playbackPosition: playbackPosition,
            totalDuration: totalDuration,
            isCompleted: playbackPosition >= totalDuration - 10, // Within 10 seconds of end
            lastPlayedAt: Date()
        )
        podcastProgress[podcastId] = progress
        
        // Update backend - TODO: Implement API call when backend is ready
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
}

