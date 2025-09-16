package com.skillvergence.mindsherpa.ui.video

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.skillvergence.mindsherpa.config.AppConfig
import com.skillvergence.mindsherpa.data.api.ApiResult
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.model.AIRequest
import com.skillvergence.mindsherpa.data.model.AIResponse
import com.skillvergence.mindsherpa.data.api.ApiException
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
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

    // AI-related properties - matching iOS EVCoachViewModel
    private val _aiResponse = MutableLiveData<String>()
    val aiResponse: LiveData<String> = _aiResponse

    private val _isAILoading = MutableLiveData<Boolean>()
    val isAILoading: LiveData<Boolean> = _isAILoading

    private val _aiError = MutableLiveData<String?>()
    val aiError: LiveData<String?> = _aiError

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

    // AI functionality - matching iOS EVCoachViewModel
    fun askAI(question: String) {
        println("🤖 [VideoViewModel] askAI called with question: '$question'")
        val trimmedQuestion = question.trim()
        if (trimmedQuestion.isEmpty()) {
            println("🤖 [VideoViewModel] Question is empty after trimming")
            _aiError.value = "Please enter a question"
            return
        }

        println("🤖 [VideoViewModel] Setting loading state to true")
        _isAILoading.value = true
        _aiError.value = null

        val context = createContext()
        println("🤖 [VideoViewModel] Created context: ${context.take(100)}...")

        viewModelScope.launch {
            try {
                val request = AIRequest(question = trimmedQuestion, context = context)
                when (val result = courseRepository.askAI(request)) {
                    is ApiResult.Success -> {
                        _aiResponse.value = result.data.answer
                        _aiError.value = null
                        _isAILoading.value = false
                        println("🤖 [VideoViewModel] AI Response received: ${result.data.answer}")
                    }
                    is ApiResult.Error -> {
                        val errorMsg = when (result.exception) {
                            is ApiException.NetworkError -> "Network connection error"
                            is ApiException.ServerError -> "Server error occurred"
                            is ApiException.TimeoutError -> "Request timed out"
                            is ApiException.HttpError -> "Server error: ${result.exception.errorMessage}"
                            is ApiException.UnknownError -> "An unexpected error occurred"
                            else -> "An error occurred: ${result.exception.message}"
                        }
                        _aiError.value = errorMsg
                        _isAILoading.value = false
                        println("❌ [VideoViewModel] AI Error: $errorMsg")
                    }
                }
            } catch (e: Exception) {
                _aiError.value = "An unexpected error occurred"
                _isAILoading.value = false
                println("❌ [VideoViewModel] AI Exception: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    private fun createContext(): String {
        // Create context from current course content - similar to iOS implementation
        val currentCourses = _courses.value ?: emptyList()
        val contextBuilder = StringBuilder()

        contextBuilder.append("Available courses: ")
        currentCourses.forEach { course ->
            contextBuilder.append("${course.title} (${course.videos?.size ?: 0} videos), ")
        }

        // Add skill level and domain context
        contextBuilder.append("\nDomain: Electric Vehicle Engineering and Safety")
        contextBuilder.append("\nUser is learning about EV charging, electrical safety, and technical skills.")

        return contextBuilder.toString()
    }

    // Quick questions - matching iOS implementation
    fun getQuickQuestions(): List<String> {
        return listOf(
            "Compare alternator vs DC-DC",
            "How to test charging systems",
            "Safety when working with EVs",
            "Explain regenerative braking",
            "What is thermal runaway?"
        )
    }
}