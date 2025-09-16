//
//  ProgressModels.swift
//  mindsherpa
//
//  Basic data models for video progress tracking
//  Step 1: Just data structures, no functionality yet
//

import Foundation

// MARK: - Basic Progress Models

public struct VideoProgressRecord: Codable, Hashable {
    public let videoId: String
    public let courseId: String
    public let lastPositionSec: Double
    public let watchedSec: Double
    public let completed: Bool
    public let completedAt: Date?
    public let updatedAt: Date
}

public struct CourseProgressRecord: Codable, Hashable {
    public let courseId: String
    public let videoCount: Int
    public let completedCount: Int
    public let watchedSecTotal: Double
    public let updatedAt: Date
}

public struct DailyActivityRecord: Codable, Hashable {
    public let day: Date  // normalized to local midnight
    public let watchedSecDay: Double
}

public struct AIInteractionRecord: Codable, Hashable {
    public let interactionId: String
    public let timestamp: Date
    public let question: String
    public let xpAwarded: Int

    public init(interactionId: String, timestamp: Date, question: String, xpAwarded: Int = 10) {
        self.interactionId = interactionId
        self.timestamp = timestamp
        self.question = question
        self.xpAwarded = xpAwarded
    }
}

// MARK: - Snapshot Container

public struct ProgressSnapshot: Codable {
    public let videos: [String: VideoProgressRecord]       // key: videoId
    public let courses: [String: CourseProgressRecord]     // key: courseId
    public let activity: [String: DailyActivityRecord]     // key: yyyy-MM-dd
    public let aiInteractions: [String: AIInteractionRecord] // key: interactionId

    public init() {
        self.videos = [:]
        self.courses = [:]
        self.activity = [:]
        self.aiInteractions = [:]
    }

    public init(videos: [String: VideoProgressRecord], courses: [String: CourseProgressRecord], activity: [String: DailyActivityRecord], aiInteractions: [String: AIInteractionRecord] = [:]) {
        self.videos = videos
        self.courses = courses
        self.activity = activity
        self.aiInteractions = aiInteractions
    }
}