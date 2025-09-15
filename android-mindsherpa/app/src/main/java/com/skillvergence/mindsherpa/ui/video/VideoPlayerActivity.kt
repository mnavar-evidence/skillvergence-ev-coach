package com.skillvergence.mindsherpa.ui.video

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.cardview.widget.CardView
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.google.android.material.appbar.MaterialToolbar
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.ApiResult
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.model.SkillLevel
import com.skillvergence.mindsherpa.data.model.Video
import com.skillvergence.mindsherpa.data.repository.CourseRepository
import com.skillvergence.mindsherpa.ui.adapter.VideoAdapter
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Course Detail Activity (formerly VideoPlayerActivity)
 * Matches iOS Course Detail Screen exactly
 */
class VideoPlayerActivity : AppCompatActivity() {

    private lateinit var toolbar: MaterialToolbar
    private lateinit var courseIcon: ImageView
    private lateinit var courseTitle: TextView
    private lateinit var courseCategory: TextView
    private lateinit var completionPercentage: TextView
    private lateinit var courseProgressBar: ProgressBar
    private lateinit var continueWatchingCard: CardView
    private lateinit var currentVideoTitle: TextView
    private lateinit var currentVideoProgress: TextView
    private lateinit var courseDescription: TextView
    private lateinit var courseDuration: TextView
    private lateinit var courseLevel: TextView
    private lateinit var videosRecyclerView: RecyclerView
    private lateinit var videoAdapter: VideoAdapter
    private lateinit var courseRepository: CourseRepository
    private var currentCourse: Course? = null

    companion object {
        private const val EXTRA_COURSE_ID = "course_id"
        private const val EXTRA_COURSE_TITLE = "course_title"
        private const val EXTRA_COURSE_DESCRIPTION = "course_description"
        private const val EXTRA_COURSE_VIDEOS = "course_videos"

        private fun logToFile(context: Context, message: String) {
            try {
                val logFile = File(context.externalCacheDir, "mindsherpa_debug.log")
                val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                FileWriter(logFile, true).use { writer ->
                    writer.write("[$timestamp] $message\n")
                }
                println(message) // Also print to console
            } catch (e: Exception) {
                println("Failed to write log: $message")
            }
        }

        fun createIntent(
            context: Context,
            course: Course
        ): Intent {
            return Intent(context, VideoPlayerActivity::class.java).apply {
                putExtra(EXTRA_COURSE_ID, course.id)
                putExtra(EXTRA_COURSE_TITLE, course.title)
                putExtra(EXTRA_COURSE_DESCRIPTION, course.description)
                putExtra("COURSE_SKILL_LEVEL", course.skillLevel.name)
                putExtra("COURSE_DURATION", course.duration)
                putExtra("COURSE_VIDEO_COUNT", course.videos?.size ?: 0)

                // Pass the actual videos data from Railway API
                val videoIds = course.videos?.map { it.id }?.toTypedArray()
                val videoTitles = course.videos?.map { it.title }?.toTypedArray()
                val videoDurations = course.videos?.map { it.duration }?.toIntArray()
                val videoUrls = course.videos?.map { it.videoUrl }?.toTypedArray()

                logToFile(context, "🎬 Passing video data for ${course.title}:")
                logToFile(context, "🎬 Video count: ${course.videos?.size ?: 0}")
                course.videos?.forEachIndexed { index, video ->
                    logToFile(context, "🎬 Video $index: ${video.id} - ${video.title} (${video.duration}s)")
                }

                putExtra("VIDEO_IDS", videoIds)
                putExtra("VIDEO_TITLES", videoTitles)
                putExtra("VIDEO_DURATIONS", videoDurations)
                putExtra("VIDEO_URLS", videoUrls)
            }
        }
    }

    private fun logToFile(message: String) {
        try {
            val logFile = File(externalCacheDir, "mindsherpa_debug.log")
            val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
            FileWriter(logFile, true).use { writer ->
                writer.write("[$timestamp] $message\n")
            }
            println(message) // Also print to console
        } catch (e: Exception) {
            println("Failed to write log: $message")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_player)

        // Initialize views and repository
        initializeViews()
        courseRepository = CourseRepository()

        // Get course data from intent
        val courseId = intent.getStringExtra(EXTRA_COURSE_ID) ?: ""
        val courseTitle = intent.getStringExtra(EXTRA_COURSE_TITLE) ?: ""
        val courseDescription = intent.getStringExtra(EXTRA_COURSE_DESCRIPTION) ?: ""
        val skillLevelName = intent.getStringExtra("COURSE_SKILL_LEVEL") ?: "BEGINNER"
        val courseDurationSeconds = intent.getIntExtra("COURSE_DURATION", 0)
        val videoCount = intent.getIntExtra("COURSE_VIDEO_COUNT", 0)

        // Get video data from intent
        val videoIds = intent.getStringArrayExtra("VIDEO_IDS") ?: emptyArray()
        val videoTitles = intent.getStringArrayExtra("VIDEO_TITLES") ?: emptyArray()
        val videoDurations = intent.getIntArrayExtra("VIDEO_DURATIONS") ?: intArrayOf()
        val videoUrls = intent.getStringArrayExtra("VIDEO_URLS") ?: emptyArray()

        logToFile("📱 Course Detail - Course: $courseTitle")
        logToFile("📱 Course Detail - Duration: ${courseDurationSeconds}s, Videos: $videoCount")
        logToFile("📱 Array Sizes - IDs: ${videoIds.size}, Titles: ${videoTitles.size}, Durations: ${videoDurations.size}, URLs: ${videoUrls.size}")

        // Debug: Print all video data received
        val maxSize = maxOf(videoTitles.size, videoIds.size, videoDurations.size, videoUrls.size)
        logToFile("📱 Max array size: $maxSize")

        for (i in 0 until maxSize) {
            val id = if (i < videoIds.size) videoIds[i] else "missing"
            val title = if (i < videoTitles.size) videoTitles[i] else "missing"
            val duration = if (i < videoDurations.size) videoDurations[i] else 0
            val url = if (i < videoUrls.size) videoUrls[i] else "missing"
            logToFile("📱 Video $i: $id - $title (${duration}s) - $url")
        }

        // Set up basic course info from intent data
        setupCourseDataFromIntent(courseTitle, courseDescription, skillLevelName, courseDurationSeconds, videoCount)

        // Set up video list with real API data
        setupVideoListFromIntent(courseId, videoIds, videoTitles, videoDurations, videoUrls)

        // Set up click listeners
        setupClickListeners()
    }

    private fun initializeViews() {
        toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        courseIcon = findViewById(R.id.course_icon)
        courseTitle = findViewById(R.id.course_title)
        courseCategory = findViewById(R.id.course_category)
        completionPercentage = findViewById(R.id.completion_percentage)
        courseProgressBar = findViewById(R.id.course_progress_bar)
        continueWatchingCard = findViewById(R.id.continue_watching_card)
        currentVideoTitle = findViewById(R.id.current_video_title)
        currentVideoProgress = findViewById(R.id.current_video_progress)
        courseDescription = findViewById(R.id.course_description)
        courseDuration = findViewById(R.id.course_duration)
        courseLevel = findViewById(R.id.course_level)
        videosRecyclerView = findViewById(R.id.videos_recycler_view)
    }

    private fun setupCourseDataFromIntent(
        title: String,
        description: String,
        skillLevelName: String,
        durationSeconds: Int,
        videoCount: Int
    ) {
        // Course basic info
        courseTitle.text = title
        courseDescription.text = description

        // Course icon based on content
        setCourseIcon(title)

        // Course category
        courseCategory.text = getCourseCategory(title)

        // Course stats from real data
        val durationMinutes = durationSeconds / 60
        courseDuration.text = "${durationMinutes}m"

        // Skill level from real data
        val skillLevel = try {
            SkillLevel.valueOf(skillLevelName)
        } catch (e: Exception) {
            SkillLevel.BEGINNER
        }
        courseLevel.text = skillLevel.displayName

        // TODO: Progress data would come from user progress API
        // For now showing placeholder - in real app this would be fetched from user progress
        completionPercentage.text = "0%"
        courseProgressBar.progress = 0

        // Current video placeholder
        currentVideoTitle.text = "Start your learning journey"
        currentVideoProgress.text = "Begin with the first video"

        logToFile("📱 Course Data - Duration: ${durationMinutes}m, Level: ${skillLevel.displayName}, Videos: $videoCount")
    }

    private fun setupVideoListFromIntent(
        courseId: String,
        videoIds: Array<String>,
        videoTitles: Array<String>,
        videoDurations: IntArray,
        videoUrls: Array<String>
    ) {
        // Create Video objects from the real API data
        val videos = mutableListOf<Video>()

        // Use the maximum available data, handle mismatched array sizes gracefully
        val maxVideos = maxOf(videoTitles.size, videoIds.size, videoDurations.size, videoUrls.size)
        logToFile("📱 Processing $maxVideos videos (max of all arrays)")

        for (i in 0 until maxVideos) {
            // Only create video if we have at least title and either duration or URL
            val hasTitle = i < videoTitles.size
            val hasDuration = i < videoDurations.size
            val hasUrl = i < videoUrls.size

            if (hasTitle && (hasDuration || hasUrl)) {
                // Use original API ID if available, otherwise fallback to synthetic ID
                val id = if (i < videoIds.size) videoIds[i] else "${courseId}-${i + 1}"
                val title = videoTitles[i]
                val duration = if (hasDuration) videoDurations[i] else 0
                val url = if (hasUrl) videoUrls[i] else ""

                logToFile("📱 Creating video $i: $id - $title")

                videos.add(
                    Video(
                        id = id,
                        title = title,
                        description = "Video from Railway API",
                        duration = duration,
                        videoUrl = url,
                        sequenceOrder = i + 1,
                        courseId = courseId
                    )
                )
            } else {
                logToFile("📱 Skipping video $i: missing required data (title: $hasTitle, duration: $hasDuration, url: $hasUrl)")
            }
        }

        println("📱 Created ${videos.size} video objects from API data")
        videos.forEach { video ->
            println("📱 Video: ${video.id} - ${video.title} (${video.duration}s)")
            println("📱 Thumbnail URL: ${video.thumbnailUrl}")
        }

        // Setup video list with real data
        setupVideoList(videos)

        // Update continue watching with first video if available
        if (videos.isNotEmpty()) {
            currentVideoTitle.text = videos.first().title
            currentVideoProgress.text = "Ready to start"
        }
    }

    private fun setupVideoList(videos: List<Video>) {
        videoAdapter = VideoAdapter { video ->
            onVideoSelected(video)
        }

        videosRecyclerView.layoutManager = LinearLayoutManager(this)
        videosRecyclerView.adapter = videoAdapter
        videoAdapter.updateVideos(videos)

        println("📱 Setup video list with ${videos.size} videos")
        videos.forEachIndexed { index, video ->
            println("📱 Video $index: ${video.title}")
        }

        if (videos.isEmpty()) {
            println("⚠️ No video data available - check API response structure")
        } else {
            println("✅ Successfully loaded ${videos.size} videos into RecyclerView")
        }
    }

    private fun setupClickListeners() {
        toolbar.setNavigationOnClickListener {
            finish()
        }

        continueWatchingCard.setOnClickListener {
            // Play current video
            println("▶️ Continue watching current video")
            // TODO: Launch actual video player
        }
    }

    private fun onVideoSelected(video: Video) {
        println("▶️ Selected video: ${video.title}")
        logToFile("▶️ Launching video detail for: ${video.id} - ${video.title}")

        // Launch VideoDetailActivity with Mux player
        val intent = VideoDetailActivity.createIntent(
            context = this,
            videoId = video.id,
            videoTitle = video.title,
            videoDescription = video.description,
            videoDuration = video.duration,
            courseId = video.courseId,
            muxPlaybackId = video.muxPlaybackId
        )
        startActivity(intent)
    }

    // Helper functions for mock data and UI
    private fun setCourseIcon(title: String) {
        val iconRes = when {
            title.contains("High Voltage Safety", ignoreCase = true) -> R.drawable.ic_high_voltage_safety_24dp
            title.contains("Electrical Fundamentals", ignoreCase = true) -> R.drawable.ic_electrical_fundamentals_24dp
            title.contains("EV System Components", ignoreCase = true) -> R.drawable.ic_ev_system_components_24dp
            title.contains("EV Charging", ignoreCase = true) -> R.drawable.ic_ev_charging_systems_24dp
            title.contains("Advanced EV", ignoreCase = true) -> R.drawable.ic_advanced_ev_systems_24dp
            else -> R.drawable.ic_high_voltage_safety_24dp // Default fallback
        }
        courseIcon.setImageResource(iconRes)
        logToFile("📱 Course icon set for: $title")
    }

    private fun getCourseCategory(title: String): String {
        return when {
            title.contains("High Voltage Safety", ignoreCase = true) -> "Electrical Safety"
            title.contains("Electrical Fundamentals", ignoreCase = true) -> "Electrical Fundamentals"
            title.contains("EV System Components", ignoreCase = true) -> "EV Technician"
            title.contains("EV Charging", ignoreCase = true) -> "Battery Technology"
            title.contains("Advanced EV", ignoreCase = true) -> "Advanced EV Systems"
            else -> "General"
        }
    }

}