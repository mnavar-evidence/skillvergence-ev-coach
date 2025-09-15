package com.skillvergence.mindsherpa.ui.podcast

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.skillvergence.mindsherpa.data.model.Podcast
import com.skillvergence.mindsherpa.data.model.PodcastData
import kotlinx.coroutines.launch

/**
 * ViewModel for podcast data management
 * Handles loading and organizing podcast episodes by course
 */
class PodcastViewModel : ViewModel() {

    private val _loadingState = MutableLiveData<Boolean>()
    val loadingState: LiveData<Boolean> = _loadingState

    private val _podcastsByCourse = MutableLiveData<Map<String, List<Podcast>>>()
    val podcastsByCourse: LiveData<Map<String, List<Podcast>>> = _podcastsByCourse

    private val _allPodcasts = MutableLiveData<List<Podcast>>()
    val allPodcasts: LiveData<List<Podcast>> = _allPodcasts

    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage

    private val _selectedPodcast = MutableLiveData<Podcast?>()
    val selectedPodcast: LiveData<Podcast?> = _selectedPodcast

    init {
        loadPodcasts()
    }

    /**
     * Load all podcasts and organize by course
     */
    fun loadPodcasts() {
        viewModelScope.launch {
            _loadingState.value = true
            _errorMessage.value = null

            try {
                // Use local data for now (matches iOS fallback behavior)
                val podcasts = PodcastData.getAllPodcasts()
                _allPodcasts.value = podcasts
                organizePodcastsByCourse(podcasts)
                logToConsole("🎵 Loaded ${podcasts.size} podcasts successfully")
            } catch (e: Exception) {
                _errorMessage.value = "Unexpected error: ${e.message}"
                logToConsole("❌ Exception in loadPodcasts: ${e.message}")
            } finally {
                _loadingState.value = false
            }
        }
    }

    /**
     * Load podcasts for a specific course
     */
    fun loadPodcastsForCourse(courseId: String) {
        viewModelScope.launch {
            _loadingState.value = true

            try {
                val coursePodcasts = PodcastData.getPodcastsByCourse(courseId)

                // Update the course-specific data
                val currentData = _podcastsByCourse.value?.toMutableMap() ?: mutableMapOf()
                currentData[courseId] = coursePodcasts
                _podcastsByCourse.value = currentData

                logToConsole("🎵 Loaded ${coursePodcasts.size} podcasts for course: $courseId")
            } catch (e: Exception) {
                _errorMessage.value = "Unexpected error: ${e.message}"
                logToConsole("❌ Exception in loadPodcastsForCourse: ${e.message}")
            } finally {
                _loadingState.value = false
            }
        }
    }

    /**
     * Select a podcast for playback
     */
    fun selectPodcast(podcast: Podcast) {
        _selectedPodcast.value = podcast
        logToConsole("🎵 Selected podcast: ${podcast.title}")
    }

    /**
     * Clear selected podcast
     */
    fun clearSelectedPodcast() {
        _selectedPodcast.value = null
    }

    /**
     * Get podcasts for a specific course
     */
    fun getPodcastsForCourse(courseId: String): List<Podcast> {
        return _podcastsByCourse.value?.get(courseId) ?: emptyList()
    }

    /**
     * Get course title by course ID
     */
    fun getCourseTitle(courseId: String): String {
        return PodcastData.getCourseTitle(courseId)
    }

    /**
     * Get total podcast count
     */
    fun getTotalPodcastCount(): Int {
        return _allPodcasts.value?.size ?: 0
    }

    /**
     * Get podcast count for a specific course
     */
    fun getPodcastCountForCourse(courseId: String): Int {
        return getPodcastsForCourse(courseId).size
    }

    /**
     * Get total duration for all podcasts
     */
    fun getTotalDuration(): Int {
        return _allPodcasts.value?.sumOf { it.duration } ?: 0
    }

    /**
     * Get formatted total duration
     */
    fun getFormattedTotalDuration(): String {
        val totalSeconds = getTotalDuration()
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        return String.format("%d:%02d", hours, minutes)
    }

    /**
     * Check if podcasts are available
     */
    fun hasPodcasts(): Boolean {
        return (_allPodcasts.value?.size ?: 0) > 0
    }

    /**
     * Check if a specific course has podcasts
     */
    fun courseHasPodcasts(courseId: String): Boolean {
        return getPodcastCountForCourse(courseId) > 0
    }

    /**
     * Refresh podcast data
     */
    fun refresh() {
        loadPodcasts()
    }

    /**
     * Clear error message
     */
    fun clearError() {
        _errorMessage.value = null
    }

    /**
     * Organize podcasts by course
     */
    private fun organizePodcastsByCourse(podcasts: List<Podcast>) {
        val groupedPodcasts = podcasts
            .filter { it.courseId != null }
            .groupBy { it.courseId!! }
            .mapValues { (_, coursePodcasts) ->
                coursePodcasts.sortedBy { it.sequenceOrder }
            }

        _podcastsByCourse.value = groupedPodcasts
        logToConsole("🎵 Organized podcasts into ${groupedPodcasts.size} courses")
    }

    /**
     * Console logging helper
     */
    private fun logToConsole(message: String) {
        println("[PodcastViewModel] $message")
    }
}