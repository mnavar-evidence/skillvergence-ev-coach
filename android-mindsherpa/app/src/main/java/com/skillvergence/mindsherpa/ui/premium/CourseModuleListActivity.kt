package com.skillvergence.mindsherpa.ui.premium

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.*
import com.skillvergence.mindsherpa.ui.video.VideoDetailActivity
import com.skillvergence.mindsherpa.utils.MuxVideoMetadata
import kotlinx.coroutines.launch

/**
 * Generic Course Module List Activity - Shows individual modules for any course
 * Handles all courses (1.0, 2.0, 3.0, 4.0, 5.0) with their respective module counts
 */
class CourseModuleListActivity : AppCompatActivity() {

    private lateinit var backButton: ImageButton
    private lateinit var courseTitle: TextView
    private lateinit var courseDescription: TextView
    private lateinit var moduleCountBadge: TextView
    private lateinit var modulesRecyclerView: RecyclerView

    private var courseId: String = ""

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
            return Intent(context, CourseModuleListActivity::class.java).apply {
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
        courseId = intent.getStringExtra(EXTRA_COURSE_ID) ?: ""
        val title = intent.getStringExtra(EXTRA_COURSE_TITLE) ?: ""
        val description = intent.getStringExtra(EXTRA_COURSE_DESCRIPTION) ?: ""

        courseTitle.text = title
        courseDescription.text = description
    }

    private fun setupRecyclerView() {
        when (courseId) {
            "adv_1" -> setupCourse1Modules()
            "adv_2" -> setupCourse2Modules()
            "adv_3" -> setupCourse3Modules()
            "adv_4" -> setupCourse4Modules()
            "adv_5" -> setupCourse5Modules()
            else -> {
                // Fallback - empty list
                moduleCountBadge.text = "0 modules"
            }
        }

        modulesRecyclerView.layoutManager = LinearLayoutManager(this)
    }

    private fun setupCourse1Modules() {
        val modules = Course1ModuleData.course1Modules

        // Debug logging
        println("🔍 Course 1.0 Debug Info:")
        println("   Raw modules count: ${modules.size}")
        modules.forEachIndexed { index, module ->
            println("   Module $index: ${module.id} - ${module.title}")
        }

        moduleCountBadge.text = "${modules.size} modules"

        val convertedModules = modules.map { CourseModule.fromCourse1Module(it) }.toMutableList()
        println("   Converted modules count: ${convertedModules.size}")

        val adapter = CourseModuleAdapter(
            modules = convertedModules,
            onModuleClick = { module -> openModuleVideo(module) }
        )
        modulesRecyclerView.adapter = adapter

        // Fetch real durations from Mux in background
        fetchRealDurations(convertedModules, adapter)
    }

    private fun fetchRealDurations(modules: List<CourseModule>, adapter: CourseModuleAdapter) {
        lifecycleScope.launch {
            println("🎬 Fetching real video durations from Mux...")

            modules.forEachIndexed { index, module ->
                try {
                    val realDurationSeconds = MuxVideoMetadata.getVideoDuration(
                        context = this@CourseModuleListActivity,
                        muxPlaybackId = module.muxPlaybackId
                    )

                    if (realDurationSeconds != null) {
                        println("✅ ${module.id}: Real duration = ${MuxVideoMetadata.formatDuration(realDurationSeconds)}")

                        // Update the module with real duration
                        val updatedModule = module.copy(
                            estimatedMinutes = (realDurationSeconds + 30) / 60 // Round to nearest minute
                        )

                        // Update the adapter data and refresh the specific item
                        (adapter as? CourseModuleAdapter)?.updateModuleDuration(index, updatedModule)
                    } else {
                        println("❌ ${module.id}: Could not fetch duration")
                    }
                } catch (e: Exception) {
                    println("❌ ${module.id}: Error fetching duration - ${e.message}")
                }
            }
        }
    }

    private fun setupCourse2Modules() {
        val modules = Course2ModuleData.course2Modules
        moduleCountBadge.text = "${modules.size} modules"

        val convertedModules = modules.map { CourseModule.fromCourse2Module(it) }.toMutableList()
        val adapter = CourseModuleAdapter(
            modules = convertedModules,
            onModuleClick = { module -> openModuleVideo(module) }
        )
        modulesRecyclerView.adapter = adapter

        // Fetch real durations from Mux in background
        fetchRealDurations(convertedModules, adapter)
    }

    private fun setupCourse3Modules() {
        val modules = Course3ModuleData.course3Modules
        moduleCountBadge.text = "${modules.size} modules"

        val convertedModules = modules.map { CourseModule.fromCourse3Module(it) }.toMutableList()
        val adapter = CourseModuleAdapter(
            modules = convertedModules,
            onModuleClick = { module -> openModuleVideo(module) }
        )
        modulesRecyclerView.adapter = adapter

        // Fetch real durations from Mux in background
        fetchRealDurations(convertedModules, adapter)
    }

    private fun setupCourse4Modules() {
        val modules = Course4ModuleData.course4Modules
        moduleCountBadge.text = "${modules.size} modules"

        val convertedModules = modules.map { CourseModule.fromCourse4Module(it) }.toMutableList()
        val adapter = CourseModuleAdapter(
            modules = convertedModules,
            onModuleClick = { module -> openModuleVideo(module) }
        )
        modulesRecyclerView.adapter = adapter

        // Fetch real durations from Mux in background
        fetchRealDurations(convertedModules, adapter)
    }

    private fun setupCourse5Modules() {
        val modules = Course5ModuleData.course5Modules
        moduleCountBadge.text = "${modules.size} modules"

        val convertedModules = modules.map { CourseModule.fromCourse5Module(it) }.toMutableList()
        val adapter = CourseModuleAdapter(
            modules = convertedModules,
            onModuleClick = { module -> openModuleVideo(module) }
        )
        modulesRecyclerView.adapter = adapter

        // Fetch real durations from Mux in background
        fetchRealDurations(convertedModules, adapter)
    }

    private fun setupClickListeners() {
        backButton.setOnClickListener {
            finish()
        }
    }

    private fun openModuleVideo(module: CourseModule) {
        val intent = VideoDetailActivity.createIntent(
            context = this,
            videoId = module.id,
            videoTitle = module.title,
            videoDescription = module.description,
            videoDuration = (module.estimatedMinutes ?: 0) * 60, // Convert minutes to seconds, default to 0 if null
            courseId = courseId,
            muxPlaybackId = module.muxPlaybackId
        )

        startActivity(intent)
    }
}

/**
 * Generic module data class for the adapter
 */
data class CourseModule(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int?, // Made nullable - null means duration not fetched yet
    val xpReward: Int
) {
    val formattedDuration: String
        get() = if (estimatedMinutes != null) {
            "$estimatedMinutes min"
        } else {
            "..." // Show loading indicator instead of placeholder
        }

    companion object {
        fun fromCourse1Module(module: Course1Module) = CourseModule(
            id = module.id,
            title = module.title,
            description = module.description,
            muxPlaybackId = module.muxPlaybackId,
            estimatedMinutes = null, // Start with null, will be updated with real duration
            xpReward = module.xpReward
        )

        fun fromCourse2Module(module: Course2Module) = CourseModule(
            id = module.id,
            title = module.title,
            description = module.description,
            muxPlaybackId = module.muxPlaybackId,
            estimatedMinutes = null, // Start with null, will be updated with real duration
            xpReward = module.xpReward
        )

        fun fromCourse3Module(module: Course3Module) = CourseModule(
            id = module.id,
            title = module.title,
            description = module.description,
            muxPlaybackId = module.muxPlaybackId,
            estimatedMinutes = null, // Start with null, will be updated with real duration
            xpReward = module.xpReward
        )

        fun fromCourse4Module(module: Course4Module) = CourseModule(
            id = module.id,
            title = module.title,
            description = module.description,
            muxPlaybackId = module.muxPlaybackId,
            estimatedMinutes = null, // Start with null, will be updated with real duration
            xpReward = module.xpReward
        )

        fun fromCourse5Module(module: Course5Module) = CourseModule(
            id = module.id,
            title = module.title,
            description = module.description,
            muxPlaybackId = module.muxPlaybackId,
            estimatedMinutes = null, // Start with null, will be updated with real duration
            xpReward = module.xpReward
        )
    }
}