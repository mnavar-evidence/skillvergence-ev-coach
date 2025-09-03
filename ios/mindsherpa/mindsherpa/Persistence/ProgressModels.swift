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

// MARK: - Snapshot Container

public struct ProgressSnapshot: Codable {
    public let videos: [String: VideoProgressRecord]       // key: videoId
    public let courses: [String: CourseProgressRecord]     // key: courseId  
    public let activity: [String: DailyActivityRecord]     // key: yyyy-MM-dd
    
    public init() {
        self.videos = [:]
        self.courses = [:]
        self.activity = [:]
    }
    
    public init(videos: [String: VideoProgressRecord], courses: [String: CourseProgressRecord], activity: [String: DailyActivityRecord]) {
        self.videos = videos
        self.courses = courses
        self.activity = activity
    }
}