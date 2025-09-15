package com.skillvergence.mindsherpa.ui.video

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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
        // Load real courses from API
        loadCourses()
    }

    fun loadCourses() {
        _isLoading.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                when (val result = courseRepository.getCourses()) {
                    is ApiResult.Success -> {
                        _courses.value = result.data
                        _isLoading.value = false
                    }
                    is ApiResult.Error -> {
                        _error.value = "Failed to load courses: ${result.exception.message}"
                        _isLoading.value = false
                    }
                }
            } catch (e: Exception) {
                _error.value = "Failed to load courses: ${e.message}"
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