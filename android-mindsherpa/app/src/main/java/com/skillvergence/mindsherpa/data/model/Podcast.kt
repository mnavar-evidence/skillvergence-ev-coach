package com.skillvergence.mindsherpa.data.model

import com.google.gson.annotations.SerializedName

/**
 * Podcast model matching iOS structure
 */
data class Podcast(
    val id: String,
    val title: String,
    val description: String,
    @SerializedName("audio_url")
    val audioUrl: String,
    @SerializedName("duration")
    val duration: Int, // Duration in seconds
    @SerializedName("episode_number")
    val episodeNumber: Int?,
    @SerializedName("publication_date")
    val publicationDate: String?, // ISO date string
    @SerializedName("thumbnail_url")
    val thumbnailUrl: String?,
    @SerializedName("skill_level")
    val skillLevel: SkillLevel = SkillLevel.BEGINNER
) {
    val formattedDuration: String
        get() {
            val minutes = duration / 60
            val seconds = duration % 60
            return String.format("%d:%02d", minutes, seconds)
        }

    val episodeTitle: String
        get() = episodeNumber?.let { "Episode $it: $title" } ?: title
}

/**
 * API Response wrapper for podcasts
 */
data class PodcastsResponse(
    val podcasts: List<Podcast>,
    val total: Int,
    val page: Int?,
    val limit: Int?
)