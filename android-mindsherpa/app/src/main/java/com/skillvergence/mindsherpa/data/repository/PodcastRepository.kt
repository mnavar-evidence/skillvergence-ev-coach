package com.skillvergence.mindsherpa.data.repository

import com.skillvergence.mindsherpa.data.model.Podcast
import com.skillvergence.mindsherpa.data.model.PodcastData
import com.skillvergence.mindsherpa.data.model.PodcastProgress as LocalPodcastProgress
import com.skillvergence.mindsherpa.data.api.PodcastProgress as ApiPodcastProgress
import com.skillvergence.mindsherpa.data.api.PodcastProgressRequest
import com.skillvergence.mindsherpa.data.model.PodcastsResponse
import com.skillvergence.mindsherpa.data.api.ApiService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for podcast data management
 * Handles both API data and local fallback data from iOS implementation
 */
@Singleton
class PodcastRepository @Inject constructor(
    private val apiService: ApiService
) {

    /**
     * Get all podcasts with fallback to local data
     */
    suspend fun getAllPodcasts(): Result<List<Podcast>> = withContext(Dispatchers.IO) {
        try {
            // First try to get from API
            val response = apiService.getPodcasts()
            if (response.isSuccessful) {
                val podcastsResponse = response.body()
                if (podcastsResponse != null && podcastsResponse.podcasts.isNotEmpty()) {
                    return@withContext Result.success(podcastsResponse.podcasts)
                }
            }

            // Fallback to local data (matches iOS implementation)
            logToConsole("🎵 Using local podcast data (fallback)")
            Result.success(PodcastData.getAllPodcasts())

        } catch (e: Exception) {
            logToConsole("❌ Error fetching podcasts from API: ${e.message}")
            // Return local data as fallback
            Result.success(PodcastData.getAllPodcasts())
        }
    }

    /**
     * Get podcasts for a specific course
     */
    suspend fun getPodcastsByCourse(courseId: String): Result<List<Podcast>> = withContext(Dispatchers.IO) {
        try {
            val allPodcasts = getAllPodcasts()
            allPodcasts.fold(
                onSuccess = { podcasts ->
                    val coursePodcasts = podcasts.filter { podcast ->
                        val normalizedCourseId = normalizeCourseId(courseId)
                        podcast.courseId == normalizedCourseId
                    }.sortedBy { it.sequenceOrder }

                    logToConsole("🎵 Found ${coursePodcasts.size} podcasts for course: $courseId")
                    Result.success(coursePodcasts)
                },
                onFailure = { error ->
                    logToConsole("❌ Error getting podcasts for course $courseId: ${error.message}")
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            logToConsole("❌ Exception in getPodcastsByCourse: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Get a specific podcast by ID
     */
    suspend fun getPodcastById(podcastId: String): Result<Podcast?> = withContext(Dispatchers.IO) {
        try {
            val allPodcasts = getAllPodcasts()
            allPodcasts.fold(
                onSuccess = { podcasts ->
                    val podcast = podcasts.find { it.id == podcastId }
                    if (podcast != null) {
                        logToConsole("🎵 Found podcast: ${podcast.title}")
                    } else {
                        logToConsole("⚠️ Podcast not found: $podcastId")
                    }
                    Result.success(podcast)
                },
                onFailure = { error ->
                    logToConsole("❌ Error getting podcast $podcastId: ${error.message}")
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            logToConsole("❌ Exception in getPodcastById: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Get podcasts grouped by course
     */
    suspend fun getPodcastsGroupedByCourse(): Result<Map<String, List<Podcast>>> = withContext(Dispatchers.IO) {
        try {
            val allPodcasts = getAllPodcasts()
            allPodcasts.fold(
                onSuccess = { podcasts ->
                    val grouped = podcasts
                        .filter { it.courseId != null }
                        .groupBy { it.courseId!! }
                        .mapValues { (_, coursePodcasts) ->
                            coursePodcasts.sortedBy { it.sequenceOrder }
                        }

                    logToConsole("🎵 Grouped podcasts by course: ${grouped.keys}")
                    Result.success(grouped)
                },
                onFailure = { error ->
                    logToConsole("❌ Error grouping podcasts: ${error.message}")
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            logToConsole("❌ Exception in getPodcastsGroupedByCourse: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Save podcast progress
     */
    suspend fun savePodcastProgress(progress: LocalPodcastProgress): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // TODO: Implement API call to save progress
            // For now, just log the progress
            logToConsole("💾 Saving progress for ${progress.podcastId}: ${progress.playbackPosition}/${progress.totalDuration}s")

            // In the future, this would make an API call:
            // val response = apiService.savePodcastProgress(progress)
            // return if (response.isSuccessful) Result.success(Unit) else Result.failure(...)

            Result.success(Unit)
        } catch (e: Exception) {
            logToConsole("❌ Error saving podcast progress: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Get podcast progress
     */
    suspend fun getPodcastProgress(podcastId: String): Result<LocalPodcastProgress?> = withContext(Dispatchers.IO) {
        try {
            // TODO: Implement API call to get progress
            // For now, return null (no saved progress)
            logToConsole("📊 Getting progress for podcast: $podcastId")

            // In the future, this would make an API call:
            // val response = apiService.getPodcastProgress(podcastId)
            // return if (response.isSuccessful) Result.success(response.body()) else Result.failure(...)

            Result.success(null)
        } catch (e: Exception) {
            logToConsole("❌ Error getting podcast progress: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Get total podcast statistics
     */
    suspend fun getPodcastStatistics(): Result<PodcastStatistics> = withContext(Dispatchers.IO) {
        try {
            val allPodcasts = getAllPodcasts()
            allPodcasts.fold(
                onSuccess = { podcasts ->
                    val stats = PodcastStatistics(
                        totalPodcasts = podcasts.size,
                        totalDuration = podcasts.sumOf { it.duration },
                        courseCount = podcasts.mapNotNull { it.courseId }.distinct().size,
                        podcastsByCourse = podcasts
                            .filter { it.courseId != null }
                            .groupBy { it.courseId!! }
                            .mapValues { (_, coursePodcasts) -> coursePodcasts.size }
                    )
                    Result.success(stats)
                },
                onFailure = { error ->
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Normalize course ID to handle both "course-1" and "1" formats
     */
    private fun normalizeCourseId(courseId: String): String {
        return when {
            courseId.startsWith("course-") -> courseId.substringAfter("course-")
            else -> courseId
        }
    }

    /**
     * Console logging helper
     */
    private fun logToConsole(message: String) {
        println("[PodcastRepository] $message")
    }
}

/**
 * Podcast statistics data class
 */
data class PodcastStatistics(
    val totalPodcasts: Int,
    val totalDuration: Int, // in seconds
    val courseCount: Int,
    val podcastsByCourse: Map<String, Int>
) {
    /**
     * Get formatted total duration as HH:MM
     */
    fun getFormattedTotalDuration(): String {
        val hours = totalDuration / 3600
        val minutes = (totalDuration % 3600) / 60
        return String.format("%d:%02d", hours, minutes)
    }

    /**
     * Get average podcast duration
     */
    fun getAverageDuration(): Int {
        return if (totalPodcasts > 0) totalDuration / totalPodcasts else 0
    }

    /**
     * Get formatted average duration as MM:SS
     */
    fun getFormattedAverageDuration(): String {
        val avg = getAverageDuration()
        val minutes = avg / 60
        val seconds = avg % 60
        return String.format("%d:%02d", minutes, seconds)
    }
}