package com.skillvergence.mindsherpa.data.api

import com.skillvergence.mindsherpa.data.model.CoursesResponse
import com.skillvergence.mindsherpa.data.model.PodcastsResponse
import com.skillvergence.mindsherpa.data.model.AIRequest
import com.skillvergence.mindsherpa.data.model.AIResponse
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Body
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
        @Query("limit") limit: Int? = null,
        @Query("course_id") courseId: String? = null
    ): Response<PodcastsResponse>

    // AI endpoint for coaching questions - matches iOS POST implementation
    @POST("ai/ask")
    suspend fun askAI(
        @Body request: AIRequest
    ): Response<AIResponse>

    // Student Device Management
    @POST("progress/register-device")
    suspend fun registerDevice(
        @Body request: DeviceRegistrationRequest
    ): Response<DeviceRegistrationResponse>

    @POST("progress/join-class")
    suspend fun joinClass(
        @Body request: ClassJoinRequest
    ): Response<ClassJoinResponse>

    // Progress tracking endpoints
    @POST("progress/video")
    suspend fun updateVideoProgress(
        @Body request: VideoProgressRequest
    ): Response<VideoProgressResponse>

    @POST("progress/podcast")
    suspend fun updatePodcastProgress(
        @Body request: PodcastProgressRequest
    ): Response<PodcastProgressResponse>

    @GET("progress/device/{deviceId}")
    suspend fun getDeviceProgress(
        @retrofit2.http.Path("deviceId") deviceId: String
    ): Response<DeviceProgressResponse>

    // Analytics endpoint
    @retrofit2.http.POST("analytics/events")
    suspend fun trackEvent(
        @retrofit2.http.Body event: AnalyticsEvent
    ): Response<Void>

    // Teacher API methods
    companion object {
        private var teacherService: TeacherApiService? = null

        fun getTeacherService(): TeacherApiService {
            return teacherService ?: NetworkModule.createTeacherApiService().also { teacherService = it }
        }

        suspend fun validateTeacherCode(code: String, schoolId: String = "fallbrook_high") =
            getTeacherService().validateTeacherCode(TeacherCodeRequest(code, schoolId))

        suspend fun getSchoolConfig(schoolId: String = "fallbrook_high") =
            getTeacherService().getSchoolConfig(schoolId)

        suspend fun getStudentRoster(schoolId: String = "fallbrook_high", level: String? = null) =
            getTeacherService().getStudentRoster(schoolId, level)

        suspend fun getCertificates(schoolId: String = "fallbrook_high", status: String = "all") =
            getTeacherService().getCertificates(schoolId, status)

        suspend fun getCodeUsage(schoolId: String = "fallbrook_high") =
            getTeacherService().getCodeUsage(schoolId)
    }
}


/**
 * Device Registration
 */
data class DeviceRegistrationRequest(
    val deviceId: String,
    val platform: String,
    val appVersion: String,
    val deviceName: String
)

data class DeviceRegistrationResponse(
    val success: Boolean,
    val deviceId: String,
    val message: String
)

/**
 * Class Join
 */
data class ClassJoinRequest(
    val deviceId: String,
    val classCode: String,
    val firstName: String,
    val lastName: String,
    val email: String? = null
)

data class ClassJoinResponse(
    val success: Boolean,
    val studentId: String,
    val teacherId: String,
    val schoolId: String,
    val message: String? = null,
    val classDetails: ClassDetails? = null
)

data class ClassDetails(
    val teacherName: String,
    val teacherEmail: String,
    val schoolName: String,
    val programName: String,
    val classCode: String
)

/**
 * Video Progress models
 */
data class VideoProgressRequest(
    val videoId: String,
    val deviceId: String,
    val watchedSeconds: Double,
    val totalDuration: Double,
    val isCompleted: Boolean,
    val courseId: String,
    val lastPosition: Double
)

data class VideoProgressResponse(
    val success: Boolean,
    val progress: VideoProgressData,
    val message: String
)

data class VideoProgressData(
    val videoId: String,
    val deviceId: String,
    val watchedSeconds: Int,
    val totalDuration: Int,
    val progressPercentage: Int,
    val isCompleted: Boolean,
    val lastWatchedAt: String,
    val courseId: String
)

/**
 * Podcast Progress models
 */
data class PodcastProgressRequest(
    val podcastId: String,
    val deviceId: String,
    val playbackPosition: Double,
    val totalDuration: Double,
    val isCompleted: Boolean,
    val courseId: String
)

data class PodcastProgressResponse(
    val success: Boolean,
    val progress: PodcastProgressData,
    val message: String
)

data class PodcastProgressData(
    val podcastId: String,
    val deviceId: String,
    val playbackPosition: Int,
    val totalDuration: Int,
    val progressPercentage: Int,
    val isCompleted: Boolean,
    val lastPlayedAt: String,
    val courseId: String
)

/**
 * Device Progress
 */
data class DeviceProgressResponse(
    val success: Boolean,
    val progress: DeviceProgressData
)

data class DeviceProgressData(
    val deviceId: String,
    val videoProgress: Map<String, Any>,
    val podcastProgress: Map<String, Any>,
    val completedVideos: List<String>,
    val completedPodcasts: List<String>,
    val totalWatchTime: Int,
    val coursesStarted: List<String>,
    val lastSync: String
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