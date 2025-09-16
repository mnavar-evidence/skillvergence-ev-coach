package com.skillvergence.mindsherpa.ui.premium

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Course1Module
import com.skillvergence.mindsherpa.data.model.Course1ModuleData
import com.skillvergence.mindsherpa.ui.video.VideoDetailActivity

/**
 * Course 1.0 Module List Activity - Shows 7 individual modules
 * Matches iOS Course1ModuleListView
 */
class Course1ModuleListActivity : AppCompatActivity() {

    private lateinit var backButton: ImageButton
    private lateinit var courseTitle: TextView
    private lateinit var courseDescription: TextView
    private lateinit var moduleCountBadge: TextView
    private lateinit var modulesRecyclerView: RecyclerView
    private lateinit var adapter: Course1ModuleAdapter

    private val course1Modules = Course1ModuleData.course1Modules

    companion object {
        private const val EXTRA_COURSE_ID = "course_id"
        private const val EXTRA_COURSE_TITLE = "course_title"
        private const val EXTRA_COURSE_DESCRIPTION = "course_description"

        fun createIntent(
            context: Context,
            courseId: String,
            courseTitle: String,
            courseDescription: String
        ): Intent {
            return Intent(context, Course1ModuleListActivity::class.java).apply {
                putExtra(EXTRA_COURSE_ID, courseId)
                putExtra(EXTRA_COURSE_TITLE, courseTitle)
                putExtra(EXTRA_COURSE_DESCRIPTION, courseDescription)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_course_module_list)

        initializeViews()
        extractIntentData()
        setupRecyclerView()
        setupClickListeners()
    }

    private fun initializeViews() {
        backButton = findViewById(R.id.back_button)
        courseTitle = findViewById(R.id.course_title)
        courseDescription = findViewById(R.id.course_description)
        moduleCountBadge = findViewById(R.id.module_count_badge)
        modulesRecyclerView = findViewById(R.id.modules_recycler_view)
    }

    private fun extractIntentData() {
        val title = intent.getStringExtra(EXTRA_COURSE_TITLE) ?: "Course 1.0 High Voltage Vehicle Safety"
        val description = intent.getStringExtra(EXTRA_COURSE_DESCRIPTION) ?: ""

        courseTitle.text = title
        courseDescription.text = description
        moduleCountBadge.text = "${course1Modules.size} modules"
    }

    private fun setupRecyclerView() {
        adapter = Course1ModuleAdapter(course1Modules) { module ->
            openModuleVideo(module)
        }

        modulesRecyclerView.layoutManager = LinearLayoutManager(this)
        modulesRecyclerView.adapter = adapter
    }

    private fun setupClickListeners() {
        backButton.setOnClickListener {
            finish()
        }
    }

    private fun openModuleVideo(module: Course1Module) {
        val intent = VideoDetailActivity.createIntent(
            context = this,
            videoId = module.id,
            videoTitle = module.title,
            videoDescription = module.description,
            videoDuration = module.estimatedMinutes * 60, // Convert minutes to seconds
            courseId = "adv_1", // Course 1.0 ID
            muxPlaybackId = module.muxPlaybackId
        )

        startActivity(intent)
    }
}