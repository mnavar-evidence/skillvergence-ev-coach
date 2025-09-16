package com.skillvergence.mindsherpa.ui.premium

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.skillvergence.mindsherpa.R

/**
 * Course 5 Module List Activity - Shows individual modules for Course 5
 * Matches iOS Course5ModuleListView
 */
class Course5ModuleListActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // TODO: Implement module list view
        // For now, just show a simple message
        setContentView(R.layout.activity_course_paywall) // Reuse layout temporarily

        title = "Course Modules"
    }
}