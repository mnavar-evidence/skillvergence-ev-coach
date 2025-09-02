//
//  AnalyticsManager.swift
//  mindsherpa
//
//  Created by Claude Code on 8/27/25.
//

import Foundation
import Combine

// MARK: - Analytics Event Types

enum AnalyticsEvent {
    case appLaunched
    case sessionStarted
    case sessionEnded(duration: TimeInterval)
    
    // Video Events
    case videoStarted(videoId: String, courseId: String, title: String)
    case videoPaused(videoId: String, position: Int, duration: Int)
    case videoResumed(videoId: String, position: Int)
    case videoProgressUpdate(videoId: String, progressPercentage: Int, watchedSeconds: Int, totalDuration: Int)
    case videoCompleted(videoId: String, courseId: String, totalDuration: Int)
    case videoSkipped(videoId: String, fromPosition: Int, toPosition: Int)
    
    // Podcast Events
    case podcastStarted(podcastId: String, courseId: String, title: String)
    case podcastPaused(podcastId: String, position: Int, duration: Int)
    case podcastResumed(podcastId: String, position: Int)
    case podcastProgressUpdate(podcastId: String, progressPercentage: Int, playbackPosition: Int, totalDuration: Int)
    case podcastCompleted(podcastId: String, courseId: String, totalDuration: Int)
    case podcastSkipped(podcastId: String, fromPosition: Int, toPosition: Int)
    
    // Quiz Events
    case quizStarted(videoId: String, quizType: String)
    case quizAnswered(videoId: String, questionId: String, answer: String, isCorrect: Bool)
    case quizCompleted(videoId: String, score: Int, totalQuestions: Int, passed: Bool)
    case quizRetaken(videoId: String, attempt: Int)
    
    // AI Interaction Events
    case aiQuestionAsked(question: String, context: String, courseId: String?)
    case aiResponseReceived(question: String, response: String, responseTime: TimeInterval)
    case aiQuickQuestionUsed(quickQuestion: String)
    
    // Course and Learning Events
    case courseStarted(courseId: String, title: String)
    case courseCompleted(courseId: String, completionPercentage: Double, totalTime: TimeInterval)
    case courseProgressUpdated(courseId: String, completionPercentage: Double)
    
    // Navigation and UI Events
    case tabSwitched(from: Int, to: Int, tabName: String)
    case screenViewed(screenName: String)
    case actionPerformed(action: String, context: [String: Any])
    
    // Learning Pattern Events
    case studySessionStarted(sessionType: String) // video, podcast, mixed
    case studySessionEnded(sessionType: String, duration: TimeInterval, contentConsumed: Int)
    case learningStreakUpdated(streakDays: Int)
    case achievementUnlocked(achievementType: String, value: Any)
}

// MARK: - Analytics Data Models

struct AnalyticsEventData: Codable {
    let eventType: String
    let timestamp: Date
    let deviceId: String
    let sessionId: String
    let parameters: [String: AnyCodable]
    let deviceInfo: [String: AnyCodable]
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = "unknown"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encode(String(describing: value))
        }
    }
}

// MARK: - Analytics Manager

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let deviceManager = DeviceManager.shared
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // Session Management
    @Published private(set) var currentSessionId: String = ""
    @Published private(set) var sessionStartTime: Date = Date()
    @Published private(set) var currentStudySession: StudySession?
    
    // Event Queue for offline support
    private var eventQueue: [AnalyticsEventData] = []
    private let eventQueueKey = "AnalyticsEventQueue"
    private let maxQueueSize = 1000
    
    // Learning Metrics
    @Published private(set) var dailyStudyTime: TimeInterval = 0
    @Published private(set) var weeklyStudyTime: TimeInterval = 0
    @Published private(set) var currentStreak: Int = 0
    
    private init() {
        startNewSession()
        loadEventQueue()
        setupPeriodicFlush()
    }
    
    // MARK: - Session Management
    
    private func startNewSession() {
        currentSessionId = UUID().uuidString
        sessionStartTime = Date()
        
        track(.sessionStarted)
    }
    
    func endSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        track(.sessionEnded(duration: duration))
        flushEvents()
    }
    
    // MARK: - Event Tracking
    
    func track(_ event: AnalyticsEvent) {
        let eventData = createEventData(from: event)
        
        // Add to queue
        eventQueue.append(eventData)
        
        // Limit queue size
        if eventQueue.count > maxQueueSize {
            eventQueue.removeFirst(eventQueue.count - maxQueueSize)
        }
        
        // Save queue to disk
        saveEventQueue()
        
        // Try to flush immediately for critical events
        if isCriticalEvent(event) {
            flushEvents()
        }
        
        print("📊 Analytics: \(eventData.eventType) tracked")
    }
    
    private func createEventData(from event: AnalyticsEvent) -> AnalyticsEventData {
        var parameters: [String: AnyCodable] = [:]
        var eventType: String = ""
        
        switch event {
        case .appLaunched:
            eventType = "app_launched"
            
        case .sessionStarted:
            eventType = "session_started"
            
        case .sessionEnded(let duration):
            eventType = "session_ended"
            parameters["duration"] = AnyCodable(duration)
            
        case .videoStarted(let videoId, let courseId, let title):
            eventType = "video_started"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["course_id"] = AnyCodable(courseId)
            parameters["title"] = AnyCodable(title)
            
        case .videoPaused(let videoId, let position, let duration):
            eventType = "video_paused"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["position"] = AnyCodable(position)
            parameters["duration"] = AnyCodable(duration)
            parameters["progress_percentage"] = AnyCodable(Double(position) / Double(duration) * 100)
            
        case .videoResumed(let videoId, let position):
            eventType = "video_resumed"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["position"] = AnyCodable(position)
            
        case .videoProgressUpdate(let videoId, let progressPercentage, let watchedSeconds, let totalDuration):
            eventType = "video_progress_update"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["progress_percentage"] = AnyCodable(progressPercentage)
            parameters["watched_seconds"] = AnyCodable(watchedSeconds)
            parameters["total_duration"] = AnyCodable(totalDuration)
            
        case .videoCompleted(let videoId, let courseId, let totalDuration):
            eventType = "video_completed"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["course_id"] = AnyCodable(courseId)
            parameters["total_duration"] = AnyCodable(totalDuration)
            
        case .videoSkipped(let videoId, let fromPosition, let toPosition):
            eventType = "video_skipped"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["from_position"] = AnyCodable(fromPosition)
            parameters["to_position"] = AnyCodable(toPosition)
            parameters["skip_distance"] = AnyCodable(toPosition - fromPosition)
            
        case .podcastStarted(let podcastId, let courseId, let title):
            eventType = "podcast_started"
            parameters["podcast_id"] = AnyCodable(podcastId)
            parameters["course_id"] = AnyCodable(courseId)
            parameters["title"] = AnyCodable(title)
            
        case .podcastPaused(let podcastId, let position, let duration):
            eventType = "podcast_paused"
            parameters["podcast_id"] = AnyCodable(podcastId)
            parameters["position"] = AnyCodable(position)
            parameters["duration"] = AnyCodable(duration)
            
        case .podcastProgressUpdate(let podcastId, let progressPercentage, let playbackPosition, let totalDuration):
            eventType = "podcast_progress_update"
            parameters["podcast_id"] = AnyCodable(podcastId)
            parameters["progress_percentage"] = AnyCodable(progressPercentage)
            parameters["playback_position"] = AnyCodable(playbackPosition)
            parameters["total_duration"] = AnyCodable(totalDuration)
            
        case .podcastCompleted(let podcastId, let courseId, let totalDuration):
            eventType = "podcast_completed"
            parameters["podcast_id"] = AnyCodable(podcastId)
            parameters["course_id"] = AnyCodable(courseId)
            parameters["total_duration"] = AnyCodable(totalDuration)
            
        case .quizStarted(let videoId, let quizType):
            eventType = "quiz_started"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["quiz_type"] = AnyCodable(quizType)
            
        case .quizCompleted(let videoId, let score, let totalQuestions, let passed):
            eventType = "quiz_completed"
            parameters["video_id"] = AnyCodable(videoId)
            parameters["score"] = AnyCodable(score)
            parameters["total_questions"] = AnyCodable(totalQuestions)
            parameters["passed"] = AnyCodable(passed)
            parameters["score_percentage"] = AnyCodable(Double(score) / Double(totalQuestions) * 100)
            
        case .aiQuestionAsked(let question, let context, let courseId):
            eventType = "ai_question_asked"
            parameters["question"] = AnyCodable(question)
            parameters["context"] = AnyCodable(context)
            parameters["question_length"] = AnyCodable(question.count)
            if let courseId = courseId {
                parameters["course_id"] = AnyCodable(courseId)
            }
            
        case .aiResponseReceived(let question, let response, let responseTime):
            eventType = "ai_response_received"
            parameters["question"] = AnyCodable(question)
            parameters["response_length"] = AnyCodable(response.count)
            parameters["response_time"] = AnyCodable(responseTime)
            
        case .courseStarted(let courseId, let title):
            eventType = "course_started"
            parameters["course_id"] = AnyCodable(courseId)
            parameters["title"] = AnyCodable(title)
            
        case .courseCompleted(let courseId, let completionPercentage, let totalTime):
            eventType = "course_completed"
            parameters["course_id"] = AnyCodable(courseId)
            parameters["completion_percentage"] = AnyCodable(completionPercentage)
            parameters["total_time"] = AnyCodable(totalTime)
            
        case .tabSwitched(let from, let to, let tabName):
            eventType = "tab_switched"
            parameters["from_tab"] = AnyCodable(from)
            parameters["to_tab"] = AnyCodable(to)
            parameters["tab_name"] = AnyCodable(tabName)
            
        case .screenViewed(let screenName):
            eventType = "screen_viewed"
            parameters["screen_name"] = AnyCodable(screenName)
            
        case .learningStreakUpdated(let streakDays):
            eventType = "learning_streak_updated"
            parameters["streak_days"] = AnyCodable(streakDays)
            
        // Add other cases as needed
        default:
            eventType = "unknown_event"
        }
        
        // Convert device info to AnyCodable
        let deviceInfoAnyCodable = deviceManager.deviceInfo.mapValues { AnyCodable($0) }
        
        return AnalyticsEventData(
            eventType: eventType,
            timestamp: Date(),
            deviceId: deviceManager.deviceId,
            sessionId: currentSessionId,
            parameters: parameters,
            deviceInfo: deviceInfoAnyCodable
        )
    }
    
    private func isCriticalEvent(_ event: AnalyticsEvent) -> Bool {
        switch event {
        case .appLaunched, .sessionStarted, .sessionEnded, .videoCompleted, .courseCompleted:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Event Queue Management
    
    private func loadEventQueue() {
        if let data = UserDefaults.standard.data(forKey: eventQueueKey),
           let queue = try? JSONDecoder().decode([AnalyticsEventData].self, from: data) {
            eventQueue = queue
        }
    }
    
    private func saveEventQueue() {
        if let data = try? JSONEncoder().encode(eventQueue) {
            UserDefaults.standard.set(data, forKey: eventQueueKey)
        }
    }
    
    private func setupPeriodicFlush() {
        // Flush events every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.flushEvents()
        }
    }
    
    func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToFlush = eventQueue
        
        // Send to backend
        apiService.sendAnalyticsEvents(eventsToFlush)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Analytics flush failed: \(error)")
                }
            }, receiveValue: { _ in
                // Clear sent events from queue
                DispatchQueue.main.async {
                    self.eventQueue.removeAll()
                    self.saveEventQueue()
                    print("✅ Analytics events flushed successfully")
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Study Session Tracking
    
    func startStudySession(type: String) {
        currentStudySession = StudySession(
            id: UUID().uuidString,
            type: type,
            startTime: Date(),
            deviceId: deviceManager.deviceId
        )
        
        track(.studySessionStarted(sessionType: type))
    }
    
    func endStudySession(contentConsumed: Int = 0) {
        guard let session = currentStudySession else { return }
        
        let duration = Date().timeIntervalSince(session.startTime)
        track(.studySessionEnded(sessionType: session.type, duration: duration, contentConsumed: contentConsumed))
        
        // Update daily study time
        updateStudyMetrics(duration)
        
        currentStudySession = nil
    }
    
    private func updateStudyMetrics(_ sessionDuration: TimeInterval) {
        dailyStudyTime += sessionDuration
        weeklyStudyTime += sessionDuration
        
        // Update streak if studying for first time today
        // This is a simplified implementation - you might want to track this more precisely
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastStudyDate = UserDefaults.standard.object(forKey: "LastStudyDate") as? Date ?? Date.distantPast
        let lastStudyDay = calendar.startOfDay(for: lastStudyDate)
        
        if today != lastStudyDay {
            let daysBetween = calendar.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysBetween > 1 {
                // Gap in studying
                currentStreak = 1
            }
            
            UserDefaults.standard.set(Date(), forKey: "LastStudyDate")
            track(.learningStreakUpdated(streakDays: currentStreak))
        }
    }
    
    // MARK: - Convenience Methods
    
    func trackVideoEvent(_ event: AnalyticsEvent) {
        track(event)
        
        // Auto-manage study sessions for video events
        switch event {
        case .videoStarted:
            if currentStudySession?.type != "video" {
                endStudySession()
                startStudySession(type: "video")
            }
        case .videoCompleted:
            // Content consumed +1
            break
        default:
            break
        }
    }
    
    func trackPodcastEvent(_ event: AnalyticsEvent) {
        track(event)
        
        // Auto-manage study sessions for podcast events
        switch event {
        case .podcastStarted:
            if currentStudySession?.type != "podcast" {
                endStudySession()
                startStudySession(type: "podcast")
            }
        default:
            break
        }
    }
}

// MARK: - Supporting Models

struct StudySession {
    let id: String
    let type: String
    let startTime: Date
    let deviceId: String
}