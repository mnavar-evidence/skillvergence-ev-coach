package com.skillvergence.mindsherpa.ui.premium

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.skillvergence.mindsherpa.R

/**
 * Course Prerequisite Activity - Shows when course is purchased but prerequisite not met
 * Matches iOS CoursePrerequisiteView
 */
class CoursePrerequisiteActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // TODO: Implement prerequisite view
        // For now, just show a simple message
        setContentView(R.layout.activity_course_paywall) // Reuse layout temporarily

        // TODO: Update UI to show "Course Purchased! But you need to complete prerequisite first"
        title = "Prerequisite Required"
    }
}