package com.skillvergence.mindsherpa.data.model

import com.google.gson.annotations.SerializedName
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import java.lang.reflect.Type

/**
 * Course model matching Railway backend API structure
 * Maps to your Railway backend API response
 */
data class Course(
    val id: String,
    val title: String,
    val description: String,
    @SerializedName("level")
    val skillLevel: SkillLevel = SkillLevel.BEGINNER,
    @SerializedName("estimatedHours")
    val estimatedHours: Double? = null,
    @SerializedName("thumbnailUrl")
    val thumbnailUrl: String? = null,
    @SerializedName("sequenceOrder")
    val sequenceOrder: Int? = null,
    val videos: List<Video>? = null
) {
    // Computed properties for backwards compatibility
    val duration: Int
        get() = videos?.sumOf { it.duration } ?: 0

    val formattedDuration: String
        get() {
            val totalSeconds = duration
            val minutes = totalSeconds / 60
            val seconds = totalSeconds % 60
            return String.format("%d:%02d", minutes, seconds)
        }

    val videoUrl: String?
        get() = videos?.firstOrNull()?.videoUrl

    val muxPlaybackId: String?
        get() = videos?.firstOrNull()?.muxPlaybackId

    val isAdvanced: Boolean
        get() = skillLevel == SkillLevel.ADVANCED || skillLevel == SkillLevel.EXPERT

    val courseId: String?
        get() = id
}

/**
 * Video model matching API structure
 */
data class Video(
    val id: String,
    val title: String,
    val description: String,
    val duration: Int,
    @SerializedName("videoUrl")
    val videoUrl: String,
    @SerializedName("sequenceOrder")
    val sequenceOrder: Int,
    @SerializedName("courseId")
    val courseId: String,
    @SerializedName("youtubeVideoId")
    val youtubeVideoId: String? = null,
    @SerializedName("muxPlaybackId")
    val muxPlaybackId: String? = null
) {
    // Enhanced properties matching iOS implementation
    val thumbnailUrl: String
        get() = "https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/$id.jpg"

    val formattedDuration: String
        get() {
            val minutes = duration / 60
            val seconds = duration % 60
            return String.format("%d:%02d", minutes, seconds)
        }
}

/**
 * Skill level enum matching iOS structure
 * Handles both API format ("Level 1") and internal format ("beginner")
 */
enum class SkillLevel(val value: String, val displayName: String) {
    BEGINNER("beginner", "Beginner"),
    INTERMEDIATE("intermediate", "Intermediate"),
    ADVANCED("advanced", "Advanced"),
    EXPERT("expert", "Expert");

    companion object {
        fun fromApiString(apiValue: String?): SkillLevel {
            return when (apiValue?.lowercase()?.trim()) {
                "level 1", "beginner", "1" -> BEGINNER
                "level 2", "intermediate", "2" -> INTERMEDIATE
                "level 3", "advanced", "3" -> ADVANCED
                "level 4", "expert", "4" -> EXPERT
                else -> BEGINNER // Default fallback
            }
        }
    }
}

/**
 * Custom deserializer to handle API's "Level 1" format
 */
class SkillLevelDeserializer : JsonDeserializer<SkillLevel> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ): SkillLevel {
        val levelString = json?.asString
        return SkillLevel.fromApiString(levelString)
    }
}

/**
 * API Response wrapper for courses
 */
data class CoursesResponse(
    val courses: List<Course>,
    val total: Int,
    val page: Int?,
    val limit: Int?
)