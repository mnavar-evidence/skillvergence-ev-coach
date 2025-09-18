package com.skillvergence.mindsherpa.data.repository

import com.skillvergence.mindsherpa.data.api.ApiResult
import com.skillvergence.mindsherpa.data.api.NetworkModule
import com.skillvergence.mindsherpa.data.api.safeApiCall
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.model.CoursesResponse
import com.skillvergence.mindsherpa.data.model.Podcast
import com.skillvergence.mindsherpa.data.model.PodcastsResponse
import com.skillvergence.mindsherpa.data.model.AIRequest
import com.skillvergence.mindsherpa.data.model.AIResponse

/**
 * Course Repository
 * Matches iOS EVCoachViewModel functionality
 */
class CourseRepository {

    private val apiService = NetworkModule.apiService

    suspend fun getCourses(
        page: Int? = null,
        limit: Int? = null,
        skillLevel: String? = null
    ): ApiResult<List<Course>> {
        println("🔧 [CourseRepository] getCourses called with page=$page, limit=$limit, skillLevel=$skillLevel")

        return when (val result = safeApiCall {
            apiService.getCourses(page, limit, skillLevel)
        }) {
            is ApiResult.Success -> {
                val courses = result.data.courses
                println("🔧 [CourseRepository] API Success - Received ${courses.size} courses")
                courses.forEach { course ->
                    println("🔧 [CourseRepository] Course: ${course.id} - ${course.title} - Videos: ${course.videos?.size ?: 0}")
                    if (course.id == "course-1") {
                        println("🔧 [CourseRepository] *** HIGH VOLTAGE SAFETY FOUNDATION VIDEO IDs ***")
                        course.videos?.forEach { video ->
                            println("🔧 [CourseRepository]   Video ID: '${video.id}' - ${video.title}")
                            println("🔧 [CourseRepository]   Expected thumbnail: https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/${video.id}.jpg")
                        }
                    }
                }
                ApiResult.Success(courses)
            }
            is ApiResult.Error -> {
                println("❌ [CourseRepository] API Error: ${result.exception}")
                result
            }
        }
    }

    suspend fun getPodcasts(
        page: Int? = null,
        limit: Int? = null
    ): ApiResult<List<Podcast>> {
        return when (val result = safeApiCall {
            apiService.getPodcasts(page, limit)
        }) {
            is ApiResult.Success -> ApiResult.Success(result.data.podcasts)
            is ApiResult.Error -> result
        }
    }

    suspend fun askAI(request: AIRequest): ApiResult<AIResponse> {
        println("🤖 [CourseRepository] Asking AI: ${request.question}")
        return when (val result = safeApiCall {
            apiService.askAI(request)
        }) {
            is ApiResult.Success -> {
                println("🤖 [CourseRepository] AI Response received: ${result.data.answer}")
                ApiResult.Success(result.data)
            }
            is ApiResult.Error -> {
                println("❌ [CourseRepository] AI Error: ${result.exception}")
                result
            }
        }
    }

    suspend fun updateVideoProgress(
        videoId: String,
        watchedSeconds: Int,
        totalDuration: Int,
        courseId: String? = null
    ): ApiResult<Unit> {
        val request = com.skillvergence.mindsherpa.data.api.VideoProgressRequest(
            videoId = videoId,
            deviceId = "android-${android.os.Build.ID}",
            watchedSeconds = watchedSeconds.toDouble(),
            totalDuration = totalDuration.toDouble(),
            isCompleted = watchedSeconds >= totalDuration * 0.9,
            courseId = courseId ?: "",
            lastPosition = watchedSeconds.toDouble()
        )

        return when (val result = safeApiCall {
            apiService.updateVideoProgress(request)
        }) {
            is ApiResult.Success -> ApiResult.Success(Unit)
            is ApiResult.Error -> result
        }
    }


}