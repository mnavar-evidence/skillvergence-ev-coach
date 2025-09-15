package com.skillvergence.mindsherpa.ui.video

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.skillvergence.mindsherpa.config.AppConfig
import com.skillvergence.mindsherpa.data.api.ApiResult
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.repository.CourseRepository
import kotlinx.coroutines.launch

/**
 * Video ViewModel - Matches iOS EVCoachViewModel functionality
 * Handles course data and video-related operations
 */
class VideoViewModel : ViewModel() {

    private val courseRepository = CourseRepository()

    private val _courses = MutableLiveData<List<Course>>()
    val courses: LiveData<List<Course>> = _courses

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    init {
        // Initialize app config and debug
        AppConfig.init()
        // Load real courses from API
        loadCourses()
    }

    fun loadCourses() {
        println("🔧 [VideoViewModel] loadCourses() called")
        _isLoading.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                println("🔧 [VideoViewModel] Starting coroutine to fetch courses...")
                when (val result = courseRepository.getCourses()) {
                    is ApiResult.Success -> {
                        val courses = result.data
                        println("🔧 [VideoViewModel] ✅ SUCCESS - Received ${courses.size} courses from repository")

                        courses.forEach { course ->
                            println("🔧 [VideoViewModel] Course: ${course.id} - ${course.title} - Videos: ${course.videos?.size ?: 0}")
                            if (course.id == "course-1") {
                                println("🔧 [VideoViewModel] *** SETTING HIGH VOLTAGE SAFETY FOUNDATION ***")
                                course.videos?.forEach { video ->
                                    println("🔧 [VideoViewModel]   Setting video: ${video.id} - ${video.title}")
                                }
                            }
                        }

                        _courses.value = courses
                        println("🔧 [VideoViewModel] ✅ LiveData updated with ${courses.size} courses")
                        _isLoading.value = false
                    }
                    is ApiResult.Error -> {
                        val errorMsg = "Failed to load courses: ${result.exception.message}"
                        println("❌ [VideoViewModel] API Error: $errorMsg")
                        _error.value = errorMsg
                        _isLoading.value = false
                    }
                }
            } catch (e: Exception) {
                val errorMsg = "Failed to load courses: ${e.message}"
                println("❌ [VideoViewModel] Exception: $errorMsg")
                e.printStackTrace()
                _error.value = errorMsg
                _isLoading.value = false
            }
        }
    }

    fun refreshCourses() {
        loadCourses()
    }

    fun updateVideoProgress(videoId: String, watchedSeconds: Int, totalDuration: Int) {
        viewModelScope.launch {
            try {
                courseRepository.updateVideoProgress(videoId, watchedSeconds, totalDuration)
            } catch (e: Exception) {
                // Handle progress update error silently
                println("Failed to update video progress: ${e.message}")
            }
        }
    }
}