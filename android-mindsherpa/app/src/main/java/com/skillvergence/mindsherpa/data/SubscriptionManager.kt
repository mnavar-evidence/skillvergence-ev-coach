package com.skillvergence.mindsherpa.data

import android.content.Context
import android.content.SharedPreferences

/**
 * Subscription Manager - Tracks unlocked premium courses
 * Stores purchase status locally using SharedPreferences
 */
object SubscriptionManager {

    private const val PREFS_NAME = "subscription_prefs"
    private const val KEY_UNLOCKED_COURSES = "unlocked_courses"

    private var prefs: SharedPreferences? = null

    fun initialize(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Mark a course as purchased/unlocked
     */
    fun unlockCourse(courseId: String) {
        val unlockedCourses = getUnlockedCourses().toMutableSet()
        unlockedCourses.add(courseId)

        prefs?.edit()?.apply {
            putStringSet(KEY_UNLOCKED_COURSES, unlockedCourses)
            apply()
        }
    }

    /**
     * Check if a course is purchased/unlocked
     */
    fun isCourseUnlocked(courseId: String): Boolean {
        return getUnlockedCourses().contains(courseId)
    }

    /**
     * Get all unlocked course IDs
     */
    fun getUnlockedCourses(): Set<String> {
        return prefs?.getStringSet(KEY_UNLOCKED_COURSES, emptySet()) ?: emptySet()
    }

    /**
     * Clear all purchased courses (for testing)
     */
    fun clearAllPurchases() {
        prefs?.edit()?.apply {
            remove(KEY_UNLOCKED_COURSES)
            apply()
        }
    }
}