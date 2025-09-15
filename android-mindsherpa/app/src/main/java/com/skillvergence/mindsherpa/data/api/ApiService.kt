package com.skillvergence.mindsherpa.data.api

import com.skillvergence.mindsherpa.data.model.CoursesResponse
import com.skillvergence.mindsherpa.data.model.PodcastsResponse
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * Railway API Service interface
 * Matches your iOS app's backend integration
 */
interface ApiService {

    @GET("courses")
    suspend fun getCourses(
        @Query("page") page: Int? = null,
        @Query("limit") limit: Int? = null,
        @Query("skill_level") skillLevel: String? = null
    ): Response<CoursesResponse>

    @GET("podcasts")
    suspend fun getPodcasts(
        @Query("page") page: Int? = null,
        @Query("limit") limit: Int? = null
    ): Response<PodcastsResponse>

    // AI endpoint for coaching questions
    @GET("ai/ask")
    suspend fun askAI(
        @Query("question") question: String,
        @Query("context") context: String? = null
    ): Response<AIResponse>

    // Progress tracking endpoints
    @GET("video/progress/{videoId}")
    suspend fun getVideoProgress(
        @retrofit2.http.Path("videoId") videoId: String
    ): Response<VideoProgress>

    @retrofit2.http.POST("video/progress")
    suspend fun updateVideoProgress(
        @retrofit2.http.Body request: VideoProgressRequest
    ): Response<Void>

    // Analytics endpoint
    @retrofit2.http.POST("analytics/events")
    suspend fun trackEvent(
        @retrofit2.http.Body event: AnalyticsEvent
    ): Response<Void>
}

/**
 * AI Response model
 */
data class AIResponse(
    val answer: String,
    val confidence: Double? = null,
    val sources: List<String>? = null
)

/**
 * Video Progress models
 */
data class VideoProgress(
    val videoId: String,
    val watchedSeconds: Int,
    val totalDuration: Int,
    val completed: Boolean,
    val lastWatchedAt: String? = null
)

data class VideoProgressRequest(
    val videoId: String,
    val watchedSeconds: Int,
    val totalDuration: Int,
    val courseId: String? = null
)

/**
 * Analytics Event model
 */
data class AnalyticsEvent(
    val eventType: String,
    val properties: Map<String, Any>,
    val timestamp: String,
    val userId: String? = null,
    val sessionId: String? = null
)