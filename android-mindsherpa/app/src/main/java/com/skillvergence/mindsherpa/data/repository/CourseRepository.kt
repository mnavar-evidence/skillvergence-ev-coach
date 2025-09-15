package com.skillvergence.mindsherpa.data.repository

import com.skillvergence.mindsherpa.data.api.ApiResult
import com.skillvergence.mindsherpa.data.api.NetworkModule
import com.skillvergence.mindsherpa.data.api.safeApiCall
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.model.CoursesResponse
import com.skillvergence.mindsherpa.data.model.Podcast
import com.skillvergence.mindsherpa.data.model.PodcastsResponse

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
        return when (val result = safeApiCall {
            apiService.getCourses(page, limit, skillLevel)
        }) {
            is ApiResult.Success -> ApiResult.Success(result.data.courses)
            is ApiResult.Error -> result
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

    suspend fun askAI(question: String, context: String? = null): ApiResult<String> {
        return when (val result = safeApiCall {
            apiService.askAI(question, context)
        }) {
            is ApiResult.Success -> ApiResult.Success(result.data.answer)
            is ApiResult.Error -> result
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
            watchedSeconds = watchedSeconds,
            totalDuration = totalDuration,
            courseId = courseId
        )

        return when (val result = safeApiCall {
            apiService.updateVideoProgress(request)
        }) {
            is ApiResult.Success -> ApiResult.Success(Unit)
            is ApiResult.Error -> result
        }
    }

    suspend fun getVideoProgress(videoId: String): ApiResult<com.skillvergence.mindsherpa.data.api.VideoProgress?> {
        return safeApiCall {
            apiService.getVideoProgress(videoId)
        }
    }

}