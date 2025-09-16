package com.skillvergence.mindsherpa.data.persistence

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.skillvergence.mindsherpa.data.model.*
import java.util.*
import kotlin.math.max
import kotlin.math.min

/**
 * ProgressStore - Matches iOS ProgressStore.swift
 * Handles video progress, XP tracking, streaks, and gamification
 */
class ProgressStore private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: ProgressStore? = null

        fun getInstance(context: Context): ProgressStore {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ProgressStore(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private val sharedPrefs: SharedPreferences =
        context.getSharedPreferences("progress_store", Context.MODE_PRIVATE)
    private val gson = Gson()

    // In-memory storage for performance
    private val videoProgressMap = mutableMapOf<String, VideoProgressRecord>()
    private val courseProgressMap = mutableMapOf<String, CourseProgressRecord>()
    private val dailyActivityMap = mutableMapOf<String, DailyActivityRecord>()

    // LiveData for observers
    private val _totalXP = MutableLiveData<Int>()
    val totalXP: LiveData<Int> = _totalXP

    private val _currentLevel = MutableLiveData<Int>()
    val currentLevel: LiveData<Int> = _currentLevel

    private val _currentStreak = MutableLiveData<Int>()
    val currentStreak: LiveData<Int> = _currentStreak

    init {
        loadFromDisk()
        updateLiveData()
    }

    // MARK: - User Profile Methods

    fun setUserName(name: String) {
        val trimmedName = name.trim()
        sharedPrefs.edit().putString("user_name", trimmedName).apply()
    }

    fun getUserName(): String {
        return sharedPrefs.getString("user_name", "") ?: ""
    }

    fun hasUserName(): Boolean {
        return getUserName().isNotEmpty()
    }

    // MARK: - Video Progress Methods

    fun getVideoProgress(videoId: String): VideoProgressRecord? {
        return videoProgressMap[videoId]
    }

    fun updateVideoProgress(
        videoId: String,
        courseId: String,
        currentTime: Double,
        duration: Double,
        isPlaying: Boolean = true
    ) {
        val now = Date()

        // Get existing or create new
        val existing = videoProgressMap[videoId]
        val previousLastPosition = existing?.lastPositionSec ?: 0.0
        val previousWatchedSec = existing?.watchedSec ?: 0.0

        // Calculate actual new watching time (only if playing AND moving forward within reasonable range)
        val timeDiff = currentTime - previousLastPosition
        val isReasonableProgress = isPlaying && timeDiff >= 0 && timeDiff <= 3 // Allow resuming at same position
        val newWatchingTime = if (isReasonableProgress) timeDiff else 0.0

        // Use accumulated time but never let it decrease when scrubbing backward
        val accumulatedTime = previousWatchedSec + newWatchingTime
        val watchedSec = min(max(accumulatedTime, previousWatchedSec), duration) // Never decrease, cap at duration

        // Completion based on actual watch time percentage, not position
        val watchPercentage = if (duration > 0) watchedSec / duration else 0.0
        val completed = watchPercentage >= 0.85 || (duration - currentTime <= 30 && watchPercentage >= 0.70)

        val record = VideoProgressRecord(
            videoId = videoId,
            courseId = courseId,
            lastPositionSec = currentTime,
            watchedSec = watchedSec,
            completed = completed,
            completedAt = if (completed) now else existing?.completedAt,
            updatedAt = now
        )

        // Store in memory
        videoProgressMap[videoId] = record

        // Update daily activity tracking if there's new progress
        if (newWatchingTime > 0) {
            val todayKey = formatDateKey(now)
            val existingActivity = dailyActivityMap[todayKey]
            val newTotalSeconds = (existingActivity?.watchedSecDay ?: 0.0) + newWatchingTime

            val dailyRecord = DailyActivityRecord(
                day = getStartOfDay(now),
                watchedSecDay = newTotalSeconds
            )

            dailyActivityMap[todayKey] = dailyRecord
        }

        // Save to disk
        saveToDisk()
        updateLiveData()
    }

    // MARK: - Daily Activity Methods

    fun getTodayActivity(): Double {
        val today = formatDateKey(Date())
        val seconds = dailyActivityMap[today]?.watchedSecDay ?: 0.0
        return seconds / 60.0 // Convert to minutes
    }

    fun getCurrentStreak(): Int {
        val today = Date()
        var currentDate = today
        var streak = 0

        // Check back up to 30 days
        for (i in 0 until 30) {
            val dateKey = formatDateKey(currentDate)
            val activity = dailyActivityMap[dateKey]

            if (activity != null && activity.watchedSecDay > 0) {
                streak += 1
            } else if (streak > 0) {
                // Break streak if we find a day with no activity (but only if we already started counting)
                break
            } else if (isSameDay(currentDate, today)) {
                // If today has no activity, we still continue checking yesterday
                // This handles the case where today just started
            } else {
                // If yesterday (or earlier) has no activity and we haven't started a streak, break
                break
            }
            currentDate = addDays(currentDate, -1)
        }

        return streak
    }

    // MARK: - XP and Level System Methods

    fun getTotalXP(): Int {
        var totalXP = 0

        // XP from completed videos (50 XP each)
        for ((_, progress) in videoProgressMap) {
            if (progress.completed) {
                totalXP += 50
            } else if (progress.watchedSec > 60) {
                // Partial XP for videos watched >1 minute (10-40 XP based on actual watch percentage)
                // Need video duration for proper calculation - use watchedSec as approximation
                val watchPercentage = min(progress.watchedSec / max(progress.lastPositionSec, 1.0), 1.0)
                val partialXP = max(10, min((watchPercentage * 40).toInt(), 40))
                totalXP += partialXP
            }
        }

        // Bonus XP for streaks (10 XP per streak day)
        totalXP += getCurrentStreak() * 10

        return totalXP
    }

    fun getCurrentLevel(): Int {
        val xp = getTotalXP()

        // Level progression: 100, 250, 500, 800, 1200, 1700, 2300, 3000...
        // Level 1: 0-99 XP, Level 2: 100-249 XP, Level 3: 250-499 XP, etc.
        return when {
            xp < 100 -> 1
            xp < 250 -> 2
            xp < 500 -> 3
            xp < 800 -> 4
            xp < 1200 -> 5
            xp < 1700 -> 6
            xp < 2300 -> 7
            xp < 3000 -> 8
            else -> 9 + (xp - 3000) / 1000 // Level 9+ every 1000 XP
        }
    }

    fun getXPForNextLevel(): Int {
        val level = getCurrentLevel()

        return when (level) {
            1 -> 100
            2 -> 250
            3 -> 500
            4 -> 800
            5 -> 1200
            6 -> 1700
            7 -> 2300
            8 -> 3000
            else -> level * 1000 + 1000 // Level 9+
        }
    }

    fun getLevelTitle(): String {
        val level = getCurrentLevel()

        return when (level) {
            1 -> "EV Apprentice"
            2 -> "Tech Trainee"
            3 -> "Junior Technician"
            4 -> "EV Technician"
            5 -> "Senior Tech"
            6 -> "EV Specialist"
            7 -> "Master Tech"
            8 -> "EV Expert"
            else -> "EV Master"
        }
    }

    fun getXPProgressInCurrentLevel(): XPProgress {
        val totalXP = getTotalXP()
        val level = getCurrentLevel()
        val nextLevelXP = getXPForNextLevel()

        val levelStartXP = when (level) {
            1 -> 0
            2 -> 100
            3 -> 250
            4 -> 500
            5 -> 800
            6 -> 1200
            7 -> 1700
            8 -> 2300
            else -> (level - 1) * 1000 + 2000 // Level 9+
        }

        val currentLevelXP = totalXP - levelStartXP
        val neededXP = nextLevelXP - levelStartXP
        val percentage = currentLevelXP.toDouble() / neededXP.toDouble()

        return XPProgress(
            current = currentLevelXP,
            needed = neededXP,
            percentage = min(percentage, 1.0)
        )
    }

    // MARK: - XP Level System (Gamification)

    fun getCurrentXPLevel(): XPLevel {
        val totalXP = getTotalXP()
        return XPLevel.levelForXP(totalXP)
    }

    fun getXPProgressToNextLevel(): XPProgress {
        val totalXP = getTotalXP()
        val currentLevel = XPLevel.levelForXP(totalXP)

        // If already at Diamond level, no next level
        if (currentLevel == XPLevel.DIAMOND) {
            return XPProgress(current = totalXP, needed = totalXP, percentage = 1.0)
        }

        val currentLevelMinXP = currentLevel.minXP
        val nextLevel = XPLevel.values()[currentLevel.ordinal + 1]
        val nextLevelMinXP = nextLevel.minXP

        val currentProgressXP = totalXP - currentLevelMinXP
        val neededForNext = nextLevelMinXP - currentLevelMinXP
        val percentage = currentProgressXP.toDouble() / neededForNext.toDouble()

        return XPProgress(
            current = currentProgressXP,
            needed = neededForNext,
            percentage = min(percentage, 1.0)
        )
    }

    // MARK: - Professional Certification Methods

    fun getCurrentCertificationLevel(): CertificationLevel {
        val completedCourses = getCompletedCoursesCount()
        return CertificationLevel.levelForCompletedCourses(completedCourses)
    }

    fun getCompletedCoursesCount(): Int {
        // Count courses with all videos completed using strict professional criteria
        val courseIds = listOf("1", "2", "3", "4", "5") // Basic course IDs
        var completedCount = 0

        for (courseId in courseIds) {
            if (isProfessionalCourseCompleted(courseId)) {
                completedCount += 1
            }
        }

        return completedCount
    }

    // Professional certification comes from completing ADVANCED courses, not basic courses
    private fun isProfessionalCourseCompleted(courseId: String): Boolean {
        // Check if the corresponding advanced course is completed
        // This should check advanced course completion via SubscriptionManager or similar
        // For now, return false since advanced course completion tracking needs to be implemented
        return false
    }

    // Get advanced course completion status for professional certification
    fun getCourseCompletionDetails(): List<CourseCompletionDetail> {
        val advancedCourseIds = listOf("adv_1", "adv_2", "adv_3", "adv_4", "adv_5")
        val courseNames = listOf("1", "2", "3", "4", "5") // For display mapping
        val moduleCounts = listOf(7, 4, 2, 2, 3) // Actual module counts for each advanced course

        return advancedCourseIds.zip(courseNames).zip(moduleCounts) { (advId, basicId), moduleCount ->
            // TODO: Check if advanced course is completed
            // This requires integration with advanced course completion tracking
            val isCompleted = false // Placeholder until advanced course tracking is implemented

            CourseCompletionDetail(
                courseId = basicId,
                completed = isCompleted,
                videosCompleted = 0,
                totalVideos = moduleCount
            )
        }
    }

    // MARK: - Course Completion Methods

    fun isCourseCompleted(courseId: String): Boolean {
        // Handle courseId format mismatches comprehensively
        val possibleCourseIds = mutableListOf(courseId)

        // Handle "course_X" format (advanced courses checking for basic prerequisite)
        if (courseId.startsWith("course_")) {
            val courseNumber = courseId.replace("course_", "")
            possibleCourseIds.add(courseNumber)

            // CRITICAL: Also check for hyphen format "course-X" (basic videos use this format!)
            possibleCourseIds.add("course-$courseNumber")

            // Also check for course titles and other variations
            when (courseNumber) {
                "1" -> possibleCourseIds.addAll(listOf(
                    "High Voltage Safety Foundation",
                    "EV Safety Pyramid",
                    "Electrical Safety",
                    "High Voltage Vehicle Safety"
                ))
                "2" -> possibleCourseIds.addAll(listOf(
                    "Electrical Fundamentals",
                    "High Voltage Hazards"
                ))
                "3" -> possibleCourseIds.addAll(listOf(
                    "Advanced Electrical Diagnostics",
                    "Navigating Electrical Shock Protection"
                ))
                "4" -> possibleCourseIds.addAll(listOf(
                    "EV Charging Systems",
                    "High Voltage PPE"
                ))
                "5" -> possibleCourseIds.addAll(listOf(
                    "Advanced EV Systems",
                    "Inside an Electric Car"
                ))
            }
        }
        // Handle numeric courseId (basic courses)
        else if (courseId.length == 1 && courseId.all { it.isDigit() }) {
            possibleCourseIds.add("course_$courseId")
        }

        // Special handling for Course 5 with multiple possible formats
        if (courseId == "course_5" || courseId == "5") {
            val course5Ids = listOf("5", "course_5", "course-5", "Course 5", "Advanced EV Systems")

            val allCourse5Videos = mutableListOf<VideoProgressRecord>()

            for (possibleId in course5Ids) {
                val courseVideos = videoProgressMap.filter { (videoId, videoProgress) ->
                    videoProgress.courseId == possibleId ||
                    videoProgress.courseId.contains("5") ||
                    videoId.contains("5.1") ||
                    videoId.contains("5.2") ||
                    videoId.contains("5.3")
                }.values
                allCourse5Videos.addAll(courseVideos)
            }

            // Remove duplicates
            val uniqueVideos = allCourse5Videos.distinctBy { it.videoId }

            // If we found Course 5 videos, check if any are completed
            if (uniqueVideos.isNotEmpty()) {
                val completedCourse5Videos = uniqueVideos.filter { it.completed }
                // If at least 1 Course 5 video is completed, unlock advanced courses
                return completedCourse5Videos.isNotEmpty()
            }

            return false
        }

        // Check all possible courseId formats
        val allCourseVideos = mutableListOf<VideoProgressRecord>()

        for (possibleId in possibleCourseIds) {
            val courseVideos = videoProgressMap.filter { (videoId, videoProgress) ->
                // CRITICAL: When checking for basic course completion, exclude advanced videos
                val matchesCourseId = videoProgress.courseId == possibleId
                val isNotAdvancedVideo = !videoId.startsWith("adv_")

                matchesCourseId && isNotAdvancedVideo
            }.values
            allCourseVideos.addAll(courseVideos)
        }

        // Fallback: If no videos found and checking course_X format, try video ID pattern matching
        // BUT exclude advanced course videos (those starting with "adv_")
        if (allCourseVideos.isEmpty() && courseId.startsWith("course_")) {
            val courseNumber = courseId.replace("course_", "")

            // Look for basic videos with pattern like "1-1", "1-2", etc
            // CRITICAL: Exclude ANY video that starts with "adv_" to prevent advanced videos from being included
            val basicVideos = videoProgressMap.filter { (videoId, _) ->
                // Must match pattern "X-Y" where X is the course number
                val hasCorrectPattern = videoId.startsWith("$courseNumber-")
                // Must NOT start with "adv_"
                val isNotAdvanced = !videoId.startsWith("adv_")
                // Must be a simple format like "1-1", "1-2" (basic videos are typically short)
                val isBasicFormat = videoId.length <= 5 && videoId.contains("-")

                hasCorrectPattern && isNotAdvanced && isBasicFormat
            }.values
            allCourseVideos.addAll(basicVideos)
        }

        if (allCourseVideos.isEmpty()) {
            return false
        }

        val completedVideos = allCourseVideos.filter { it.completed }
        return completedVideos.size == allCourseVideos.size
    }

    // MARK: - Persistence Methods

    private fun loadFromDisk() {
        // Load video progress
        val videoProgressJson = sharedPrefs.getString("video_progress", "{}")
        val videoProgressType = object : TypeToken<Map<String, VideoProgressRecord>>() {}.type
        val loadedVideoProgress: Map<String, VideoProgressRecord> = gson.fromJson(videoProgressJson, videoProgressType) ?: emptyMap()
        videoProgressMap.putAll(loadedVideoProgress)

        // Load daily activity
        val activityJson = sharedPrefs.getString("daily_activity", "{}")
        val activityType = object : TypeToken<Map<String, DailyActivityRecord>>() {}.type
        val loadedActivity: Map<String, DailyActivityRecord> = gson.fromJson(activityJson, activityType) ?: emptyMap()
        dailyActivityMap.putAll(loadedActivity)
    }

    private fun saveToDisk() {
        val editor = sharedPrefs.edit()

        // Save video progress
        val videoProgressJson = gson.toJson(videoProgressMap)
        editor.putString("video_progress", videoProgressJson)

        // Save daily activity
        val activityJson = gson.toJson(dailyActivityMap)
        editor.putString("daily_activity", activityJson)

        editor.apply()
    }

    private fun updateLiveData() {
        _totalXP.value = getTotalXP()
        _currentLevel.value = getCurrentLevel()
        _currentStreak.value = getCurrentStreak()
    }

    // MARK: - Utility Methods

    private fun formatDateKey(date: Date): String {
        val calendar = Calendar.getInstance()
        calendar.time = date
        return "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
    }

    private fun getStartOfDay(date: Date): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }

    private fun isSameDay(date1: Date, date2: Date): Boolean {
        val cal1 = Calendar.getInstance()
        val cal2 = Calendar.getInstance()
        cal1.time = date1
        cal2.time = date2
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
               cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }

    private fun addDays(date: Date, days: Int): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.add(Calendar.DAY_OF_YEAR, days)
        return calendar.time
    }
}

// MARK: - Data Classes

data class VideoProgressRecord(
    val videoId: String,
    val courseId: String,
    val lastPositionSec: Double,
    val watchedSec: Double,
    val completed: Boolean,
    val completedAt: Date?,
    val updatedAt: Date
)

data class CourseProgressRecord(
    val courseId: String,
    val videosCompleted: Int,
    val totalVideos: Int,
    val completed: Boolean,
    val completedAt: Date?
)

data class DailyActivityRecord(
    val day: Date,
    val watchedSecDay: Double
)