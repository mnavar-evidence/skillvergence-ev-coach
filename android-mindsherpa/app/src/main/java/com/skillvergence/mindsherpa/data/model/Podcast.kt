package com.skillvergence.mindsherpa.data.model

import com.google.gson.annotations.SerializedName

/**
 * Podcast data model matching iOS implementation
 * Supports both traditional audio URLs and Mux streaming URLs
 */
data class Podcast(
    @SerializedName("id")
    val id: String,

    @SerializedName("title")
    val title: String,

    @SerializedName("description")
    val description: String,

    @SerializedName("duration")
    val duration: Int, // Duration in seconds

    @SerializedName("audioUrl")
    val audioUrl: String, // Can be traditional URL or Mux URL (mux://playbackId)

    @SerializedName("sequenceOrder")
    val sequenceOrder: Int? = null,

    @SerializedName("courseId")
    val courseId: String? = null,

    @SerializedName("episodeNumber")
    val episodeNumber: Int? = null,

    @SerializedName("thumbnailUrl")
    val thumbnailUrl: String? = null, // Individual episode thumbnail URL

    @SerializedName("skillLevel")
    val skillLevel: SkillLevel = SkillLevel.BEGINNER
) {
    /**
     * Get the Mux playback ID if this is a Mux URL
     */
    fun getMuxPlaybackId(): String? {
        return if (audioUrl.startsWith("mux://")) {
            audioUrl.substringAfter("mux://")
        } else null
    }

    /**
     * Get the streaming URL for this podcast
     */
    fun getStreamingUrl(): String {
        return getMuxPlaybackId()?.let { playbackId ->
            "https://stream.mux.com/$playbackId.m3u8"
        } ?: audioUrl
    }

    /**
     * Check if this podcast uses Mux streaming
     */
    fun isMuxStream(): Boolean = audioUrl.startsWith("mux://")

    /**
     * Format duration as MM:SS
     */
    fun getFormattedDuration(): String {
        val minutes = duration / 60
        val seconds = duration % 60
        return String.format("%d:%02d", minutes, seconds)
    }

    /**
     * Get course-specific thumbnail URL if not provided
     */
    fun resolveThumbnailUrl(): String {
        return thumbnailUrl ?: when (courseId) {
            "1", "course-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/high-voltage-safety.jpg"
            "2", "course-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/electrical-fundamentals.jpg"
            "3", "course-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-components.jpg"
            "4", "course-4" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-charging.jpg"
            "5", "course-5" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/advanced-ev.jpg"
            else -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/default.jpg"
        }
    }

    val episodeTitle: String
        get() = episodeNumber?.let { "Episode $it: $title" } ?: title
}

/**
 * Podcast progress tracking model
 */
data class PodcastProgress(
    @SerializedName("podcastId")
    val podcastId: String,

    @SerializedName("playbackPosition")
    val playbackPosition: Int, // Current position in seconds

    @SerializedName("totalDuration")
    val totalDuration: Int, // Total duration in seconds

    @SerializedName("isCompleted")
    val isCompleted: Boolean,

    @SerializedName("lastPlayedAt")
    val lastPlayedAt: Long // Timestamp
) {
    /**
     * Get progress percentage (0-100)
     */
    fun getProgressPercentage(): Int {
        return if (totalDuration > 0) {
            ((playbackPosition.toDouble() / totalDuration) * 100).toInt()
        } else 0
    }

    /**
     * Format playback position as MM:SS
     */
    fun getFormattedPosition(): String {
        val minutes = playbackPosition / 60
        val seconds = playbackPosition % 60
        return String.format("%d:%02d", minutes, seconds)
    }

    /**
     * Check if podcast is considered completed (within 10 seconds of end)
     */
    fun isNearlyCompleted(): Boolean {
        return totalDuration > 0 && (totalDuration - playbackPosition) <= 10
    }
}

/**
 * Response wrapper for podcast API
 */
data class PodcastsResponse(
    @SerializedName("podcasts")
    val podcasts: List<Podcast>,

    @SerializedName("total")
    val total: Int? = null,

    @SerializedName("page")
    val page: Int? = null,

    @SerializedName("pageSize")
    val pageSize: Int? = null
)