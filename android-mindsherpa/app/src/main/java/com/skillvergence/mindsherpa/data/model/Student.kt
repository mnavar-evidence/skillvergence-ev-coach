package com.skillvergence.mindsherpa.data.model

/**
 * Student data model for teacher dashboard
 */
data class Student(
    val id: String,
    val firstName: String,
    val lastName: String,
    val email: String?,
    val xp: Int,
    val level: Int,
    val lastActivity: String?, // e.g., "2 hours ago" or null for "No activity"
    val isActive: Boolean,
    val needsAttention: Boolean
) {
    val fullName: String
        get() = "$firstName $lastName"

    val initial: String
        get() = firstName.firstOrNull()?.toString()?.uppercase() ?: "?"

    val formattedXP: String
        get() = "${xp.toString().replace(Regex("(\\d)(?=(\\d{3})+$)"), "$1,")} XP"

    val formattedLevel: String
        get() = "Level $level"

    val activityStatus: String
        get() = lastActivity ?: "No activity"
}