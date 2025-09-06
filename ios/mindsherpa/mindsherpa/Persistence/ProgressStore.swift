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
        loadUserName()
    }
    
    // MARK: - User Profile Methods
    
    @Published public var userName: String = ""
    
    public func setUserName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmedName
        UserDefaults.standard.set(trimmedName, forKey: "user_name")
    }
    
    public func getUserName() -> String {
        return userName.isEmpty ? UserDefaults.standard.string(forKey: "user_name") ?? "" : userName
    }
    
    public func hasUserName() -> Bool {
        return !getUserName().isEmpty
    }
    
    private func loadUserName() {
        userName = UserDefaults.standard.string(forKey: "user_name") ?? ""
    }
    
    // MARK: - Read Methods
    
    public func videoProgress(videoId: String) -> VideoProgressRecord? {
        return snapshot.videos[videoId]
    }
    
    public func courseProgress(courseId: String) -> CourseProgressRecord? {
        return snapshot.courses[courseId]
    }
    
    // MARK: - Write Methods
    
    public func updateVideoProgress(videoId: String, courseId: String, currentTime: Double, duration: Double, isPlaying: Bool = true) {
        let now = Date()
        
        // Get existing or create new
        let existing = snapshot.videos[videoId]
        let previousLastPosition = existing?.lastPositionSec ?? 0
        let previousWatchedSec = existing?.watchedSec ?? 0
        
        // Calculate actual new watching time (only if playing AND moving forward within reasonable range)
        let timeDiff = currentTime - previousLastPosition
        let isReasonableProgress = isPlaying && timeDiff >= 0 && timeDiff <= 3 // Allow resuming at same position
        let newWatchingTime = isReasonableProgress ? timeDiff : 0
        
        // Use accumulated time but never let it decrease when scrubbing backward
        let accumulatedTime = previousWatchedSec + newWatchingTime
        let watchedSec = min(max(accumulatedTime, previousWatchedSec), duration) // Never decrease, cap at duration
        
        // Completion based on actual watch time percentage, not position
        let watchPercentage = duration > 0 ? watchedSec / duration : 0
        let completed = watchPercentage >= 0.85 || (duration - currentTime <= 30 && watchPercentage >= 0.70)
        
        // Debug logging (remove in production)
        print("📹 Progress Update - Video: \(videoId.prefix(8))")
        print("   Position: \(Int(previousLastPosition))s → \(Int(currentTime))s (diff: \(String(format: "%.1f", timeDiff))s)")
        print("   Playing: \(isPlaying) | Reasonable: \(isReasonableProgress) | New time: +\(String(format: "%.1f", newWatchingTime))s")
        print("   Watched: \(Int(previousWatchedSec))s → \(Int(watchedSec))s (\(Int(watchPercentage*100))%) | Completed: \(completed)")
        
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
    
    // MARK: - XP and Level System Methods
    
    public func getTotalXP() -> Int {
        var totalXP = 0
        
        // XP from completed videos (50 XP each)
        for (_, progress) in snapshot.videos {
            if progress.completed {
                totalXP += 50
            } else if progress.watchedSec > 60 {
                // Partial XP for videos watched >1 minute (10-40 XP based on actual watch percentage)
                // Need video duration for proper calculation - use watchedSec as approximation
                let watchPercentage = min(progress.watchedSec / max(progress.lastPositionSec, 1), 1.0)
                let partialXP = max(10, min(Int(watchPercentage * 40), 40))
                totalXP += partialXP
            }
        }
        
        // Bonus XP for streaks (10 XP per streak day)
        totalXP += getCurrentStreak() * 10
        
        return totalXP
    }
    
    public func getCurrentLevel() -> Int {
        let xp = getTotalXP()
        
        // Level progression: 100, 250, 500, 800, 1200, 1700, 2300, 3000...
        // Level 1: 0-99 XP, Level 2: 100-249 XP, Level 3: 250-499 XP, etc.
        if xp < 100 { return 1 }
        else if xp < 250 { return 2 }
        else if xp < 500 { return 3 }
        else if xp < 800 { return 4 }
        else if xp < 1200 { return 5 }
        else if xp < 1700 { return 6 }
        else if xp < 2300 { return 7 }
        else if xp < 3000 { return 8 }
        else { return 9 + (xp - 3000) / 1000 } // Level 9+ every 1000 XP
    }
    
    public func getXPForNextLevel() -> Int {
        let level = getCurrentLevel()
        
        switch level {
        case 1: return 100
        case 2: return 250
        case 3: return 500
        case 4: return 800
        case 5: return 1200
        case 6: return 1700
        case 7: return 2300
        case 8: return 3000
        default: return level * 1000 + 1000 // Level 9+
        }
    }
    
    public func getLevelTitle() -> String {
        let level = getCurrentLevel()
        
        switch level {
        case 1: return "EV Apprentice"
        case 2: return "Tech Trainee"  
        case 3: return "Junior Technician"
        case 4: return "EV Technician"
        case 5: return "Senior Tech"
        case 6: return "EV Specialist"
        case 7: return "Master Tech"
        case 8: return "EV Expert"
        default: return "EV Master"
        }
    }
    
    public func getXPProgressInCurrentLevel() -> (current: Int, needed: Int, percentage: Double) {
        let totalXP = getTotalXP()
        let level = getCurrentLevel()
        let nextLevelXP = getXPForNextLevel()
        
        let levelStartXP: Int
        switch level {
        case 1: levelStartXP = 0
        case 2: levelStartXP = 100
        case 3: levelStartXP = 250
        case 4: levelStartXP = 500
        case 5: levelStartXP = 800
        case 6: levelStartXP = 1200
        case 7: levelStartXP = 1700
        case 8: levelStartXP = 2300
        default: levelStartXP = (level - 1) * 1000 + 2000 // Level 9+
        }
        
        let currentLevelXP = totalXP - levelStartXP
        let neededXP = nextLevelXP - levelStartXP
        let percentage = Double(currentLevelXP) / Double(neededXP)
        
        return (current: currentLevelXP, needed: neededXP, percentage: min(percentage, 1.0))
    }
    
    // MARK: - Course Completion Methods
    
    public func isCourseCompleted(courseId: String) -> Bool {
        // Check for Course 5 completion with multiple possible course ID formats
        if courseId == "course_5" {
            // Look for Course 5 videos with various possible courseId formats
            let possibleCourse5Ids = ["5", "course_5", "course-5", "Course 5", "Advanced EV Systems"]
            
            var allCourse5Videos: [VideoProgressRecord] = []
            
            for possibleId in possibleCourse5Ids {
                let courseVideos = snapshot.videos.filter { videoProgress in
                    return videoProgress.value.courseId == possibleId ||
                           videoProgress.value.courseId.contains("5") ||
                           videoProgress.key.contains("5.1") ||
                           videoProgress.key.contains("5.2") ||
                           videoProgress.key.contains("5.3")
                }
                allCourse5Videos.append(contentsOf: courseVideos.map { $0.value })
            }
            
            // Remove duplicates
            let uniqueVideos = Array(Set(allCourse5Videos.map { $0.videoId }))
            
            // If we found Course 5 videos, check if any are completed
            if uniqueVideos.count > 0 {
                let completedCourse5Videos = allCourse5Videos.filter { $0.completed }
                // If at least 1 Course 5 video is completed, unlock advanced courses
                return completedCourse5Videos.count > 0
            }
            
            return false
        }
        
        // For other courses, use the original logic
        let courseVideos = snapshot.videos.filter { videoProgress in
            return videoProgress.value.courseId == courseId
        }
        
        if courseVideos.isEmpty {
            return false
        }
        
        let completedVideos = courseVideos.filter { $0.value.completed }
        return completedVideos.count == courseVideos.count
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