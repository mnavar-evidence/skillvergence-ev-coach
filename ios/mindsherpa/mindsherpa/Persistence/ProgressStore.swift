//
//  ProgressStore.swift
//  mindsherpa
//
//  Simple in-memory progress store (Step 3)
//  No disk operations yet, just in-memory tracking
//

import Foundation

@MainActor
public class ProgressStore: ObservableObject {
    public static let shared = ProgressStore()
    
    // Simple in-memory storage
    private var snapshot = ProgressSnapshot()
    
    // File location for JSON storage
    private let storageURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("progress.json")
    }()
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Read Methods
    
    public func videoProgress(videoId: String) -> VideoProgressRecord? {
        return snapshot.videos[videoId]
    }
    
    public func courseProgress(courseId: String) -> CourseProgressRecord? {
        return snapshot.courses[courseId]
    }
    
    // MARK: - Write Methods
    
    public func updateVideoProgress(videoId: String, courseId: String, currentTime: Double, duration: Double) {
        let now = Date()
        
        // Get existing or create new
        let existing = snapshot.videos[videoId]
        let watchedSec = max(existing?.watchedSec ?? 0, currentTime)
        let completed = duration - currentTime <= 10 // completed if within 10 seconds of end
        
        let record = VideoProgressRecord(
            videoId: videoId,
            courseId: courseId,
            lastPositionSec: currentTime,
            watchedSec: watchedSec,
            completed: completed,
            completedAt: completed ? now : existing?.completedAt,
            updatedAt: now
        )
        
        // Store in memory
        var updatedVideos = snapshot.videos
        updatedVideos[videoId] = record
        
        snapshot = ProgressSnapshot(videos: updatedVideos, courses: snapshot.courses, activity: snapshot.activity)
        
        // Save to disk
        saveToDisk()
    }
    
    // MARK: - Persistence Methods
    
    private func loadFromDisk() {
        do {
            let data = try Data(contentsOf: storageURL)
            snapshot = try JSONDecoder().decode(ProgressSnapshot.self, from: data)
        } catch {
            // File doesn't exist or is corrupted, start with empty snapshot
            snapshot = ProgressSnapshot()
        }
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storageURL)
        } catch {
            // Log error but don't crash app
            print("Failed to save progress: \(error)")
        }
    }
}