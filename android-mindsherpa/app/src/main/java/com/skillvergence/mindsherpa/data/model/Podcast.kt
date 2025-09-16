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
     * Get episode-specific thumbnail URL if not provided
     * Matches iOS implementation with individual episode thumbnails
     * Prioritizes known working URLs over potentially broken hardcoded ones
     */
    fun resolveThumbnailUrl(): String {
        // First check our known working mappings (prioritized over hardcoded URLs)
        val workingUrl = when (id) {
            // Course 1: High Voltage Safety Foundation
            "podcast-1-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/hv-safety-fundamentals.jpg"
            "podcast-1-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-ppe-guide.jpg"
            "podcast-1-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-loto-procedures.jpg"
            "podcast-1-4" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-emergency-response.jpg"

            // Course 2: Electrical Fundamentals
            "podcast-2-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/spark-plugs-episode.jpg"
            "podcast-2-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/dc-vs-ac-power.jpg"
            "podcast-2-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ohms-law-ev.jpg"
            "podcast-2-4" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-motors-episode.jpg"

            // Course 3: EV System Components
            "podcast-3-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-powertrain-arch.jpg"
            "podcast-3-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/inverters-power-electronics.jpg"
            "podcast-3-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/regenerative-braking.jpg"

            // Course 4: EV Charging Systems
            "podcast-4-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-batteries-episode.jpg"
            "podcast-4-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/charging-standards.jpg"
            "podcast-4-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/battery-management-systems.jpg"
            "podcast-4-4" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/thermal-management.jpg"

            // Course 5: Advanced EV Systems
            "podcast-5-1" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/vehicle-to-grid.jpg"
            "podcast-5-2" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/autonomous-ev-integration.jpg"
            "podcast-5-3" -> "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/future-ev-transport.jpg"

            // Unknown episodes - return null to check hardcoded URLs
            else -> null
        }

        // Return working URL if we have one, otherwise fall back to hardcoded URL or course-level
        return workingUrl ?: thumbnailUrl ?: when (courseId) {
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