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
    @Published private var snapshot = ProgressSnapshot()
    
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
        let previousWatchedSec = existing?.watchedSec ?? 0
        let watchedSec = max(previousWatchedSec, currentTime)
        let completed = duration - currentTime <= 30 || currentTime >= duration * 0.95 // completed if within 30 seconds of end or 95% watched
        
        // Calculate new watching time for daily activity tracking
        let newWatchingTime = max(0, watchedSec - previousWatchedSec)
        
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
        
        // Update daily activity tracking if there's new progress
        var updatedActivity = snapshot.activity
        if newWatchingTime > 0 {
            let todayKey = formatDateKey(now)
            let existingActivity = updatedActivity[todayKey]
            let newTotalSeconds = (existingActivity?.watchedSecDay ?? 0) + newWatchingTime
            
            let dailyRecord = DailyActivityRecord(
                day: Calendar.current.startOfDay(for: now),
                watchedSecDay: newTotalSeconds
            )
            
            updatedActivity[todayKey] = dailyRecord
        }
        
        snapshot = ProgressSnapshot(videos: updatedVideos, courses: snapshot.courses, activity: updatedActivity)
        
        // Save to disk
        saveToDisk()
    }
    
    // MARK: - Daily Activity Methods
    
    public func getTodayActivity() -> Double {
        let today = formatDateKey(Date())
        let seconds = snapshot.activity[today]?.watchedSecDay ?? 0
        return seconds / 60.0 // Convert to minutes
    }
    
    public func getCurrentStreak() -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        var currentDate = today
        var streak = 0
        
        // Check back up to 30 days
        for _ in 0..<30 {
            let dateKey = formatDateKey(currentDate)
            if let activity = snapshot.activity[dateKey], activity.watchedSecDay > 0 {
                streak += 1
            } else if streak > 0 {
                // Break streak if we find a day with no activity (but only if we already started counting)
                break
            } else if Calendar.current.isDate(currentDate, inSameDayAs: today) {
                // If today has no activity, we still continue checking yesterday
                // This handles the case where today just started
            } else {
                // If yesterday (or earlier) has no activity and we haven't started a streak, break
                break
            }
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
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