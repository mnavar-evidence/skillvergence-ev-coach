package com.skillvergence.mindsherpa.data.model

/**
 * Level System - Matches iOS LevelSystem.swift
 * Implements XP/Gamification and Professional Certification systems
 */

// MARK: - XP/Gamification System (Engagement & Fun)

enum class XPLevel(val value: String) {
    BRONZE("bronze"),           // 0-999 XP
    SILVER("silver"),           // 1000-2499 XP
    GOLD("gold"),               // 2500-4999 XP
    PLATINUM("platinum"),       // 5000-9999 XP
    DIAMOND("diamond");         // 10000+ XP

    val displayName: String
        get() = when (this) {
            BRONZE -> "Bronze Learner"
            SILVER -> "Silver Learner"
            GOLD -> "Gold Learner"
            PLATINUM -> "Platinum Learner"
            DIAMOND -> "Diamond Learner"
        }

    val minXP: Int
        get() = when (this) {
            BRONZE -> 0
            SILVER -> 1000
            GOLD -> 2500
            PLATINUM -> 5000
            DIAMOND -> 10000
        }

    val maxXP: Int?
        get() = when (this) {
            BRONZE -> 999
            SILVER -> 2499
            GOLD -> 4999
            PLATINUM -> 9999
            DIAMOND -> null // No upper limit
        }

    val icon: String
        get() = when (this) {
            BRONZE -> "ic_medal_bronze_24dp"
            SILVER -> "ic_medal_silver_24dp"
            GOLD -> "ic_medal_gold_24dp"
            PLATINUM -> "ic_star_24dp"
            DIAMOND -> "ic_diamond_24dp"
        }

    val colorRes: String
        get() = when (this) {
            BRONZE -> "brown"
            SILVER -> "gray"
            GOLD -> "gold"
            PLATINUM -> "purple"
            DIAMOND -> "blue"
        }

    companion object {
        fun levelForXP(xp: Int): XPLevel {
            return when {
                xp >= 10000 -> DIAMOND
                xp >= 5000 -> PLATINUM
                xp >= 2500 -> GOLD
                xp >= 1000 -> SILVER
                else -> BRONZE
            }
        }
    }
}

// MARK: - Professional Certification System (Career & Competency)

enum class CertificationLevel(val value: String) {
    NONE("none"),
    FOUNDATION("foundation"),               // 1 course completed
    ASSOCIATE("associate"),                 // 2-3 courses completed
    PROFESSIONAL("professional"),           // 4 courses completed
    CERTIFIED("certified");                 // All 5 courses completed

    val displayName: String
        get() = when (this) {
            NONE -> "Student"
            FOUNDATION -> "EV Foundation Certified"
            ASSOCIATE -> "EV Associate Technician"
            PROFESSIONAL -> "EV Professional Technician"
            CERTIFIED -> "EV Certified Master"
        }

    val shortName: String
        get() = when (this) {
            NONE -> "Student"
            FOUNDATION -> "Foundation"
            ASSOCIATE -> "Associate"
            PROFESSIONAL -> "Professional"
            CERTIFIED -> "Certified Master"
        }

    val coursesRequired: Int
        get() = when (this) {
            NONE -> 0
            FOUNDATION -> 1
            ASSOCIATE -> 2
            PROFESSIONAL -> 4
            CERTIFIED -> 5
        }

    val icon: String
        get() = when (this) {
            NONE -> "ic_person_24dp"
            FOUNDATION -> "ic_check_seal_24dp"
            ASSOCIATE -> "ic_check_seal_fill_24dp"
            PROFESSIONAL -> "ic_rosette_24dp"
            CERTIFIED -> "ic_crown_24dp"
        }

    val colorRes: String
        get() = when (this) {
            NONE -> "gray"
            FOUNDATION -> "green"
            ASSOCIATE -> "blue"
            PROFESSIONAL -> "orange"
            CERTIFIED -> "gold"
        }

    companion object {
        fun levelForCompletedCourses(completedCount: Int): CertificationLevel {
            return when {
                completedCount >= 5 -> CERTIFIED
                completedCount >= 4 -> PROFESSIONAL
                completedCount >= 2 -> ASSOCIATE
                completedCount >= 1 -> FOUNDATION
                else -> NONE
            }
        }
    }
}

// MARK: - Progress Data Classes

data class XPProgress(
    val current: Int,
    val needed: Int,
    val percentage: Double
)

data class CourseCompletionDetail(
    val courseId: String,
    val completed: Boolean,
    val videosCompleted: Int,
    val totalVideos: Int
)