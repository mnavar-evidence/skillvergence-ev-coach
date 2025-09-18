package com.skillvergence.mindsherpa.ui.video

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import com.skillvergence.mindsherpa.ui.adapter.CourseAdapter
import com.skillvergence.mindsherpa.ui.progress.LevelDetailsActivity
import com.skillvergence.mindsherpa.ui.teacher.TeacherCodeEntryActivity

/**
 * Video Fragment - Matches iOS VideoView
 * Displays video courses from Railway backend
 */
class VideoFragment : Fragment() {

    private lateinit var videoViewModel: VideoViewModel
    private lateinit var recyclerView: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var courseAdapter: CourseAdapter
    private lateinit var progressStore: ProgressStore
    private lateinit var accessControlManager: AccessControlManager

    // Gaming UI elements
    private lateinit var levelIndicator: LinearLayout
    private lateinit var levelIcon: ImageView
    private lateinit var levelText: TextView

    // Coach Nova tap gesture for hidden teacher access
    private var coachNovaTapCount = 0
    private val tapResetHandler = Handler(Looper.getMainLooper())
    private val tapResetRunnable = Runnable { coachNovaTapCount = 0 }


    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the proper layout
        val rootView = inflater.inflate(R.layout.fragment_video, container, false)

        // Initialize ViewModel and ProgressStore
        videoViewModel = ViewModelProvider(this)[VideoViewModel::class.java]
        progressStore = ProgressStore.getInstance(requireContext())
        accessControlManager = AccessControlManager.getInstance(requireContext())

        // Setup UI
        setupGamingUI(rootView)
        setupRecyclerView(rootView)
        setupCoachNovaGesture(rootView)

        // Observe data
        observeViewModel()

        // Load initial data
        videoViewModel.loadCourses()

        return rootView
    }

    private fun setupGamingUI(rootView: View) {
        levelIndicator = rootView.findViewById(R.id.level_indicator)
        levelIcon = rootView.findViewById(R.id.level_icon)
        levelText = rootView.findViewById(R.id.level_text)

        // Set click listener to open level details
        levelIndicator.setOnClickListener {
            val intent = LevelDetailsActivity.createIntent(requireContext())
            startActivity(intent)
        }

        // Update level display
        updateLevelDisplay()
    }

    private fun updateLevelDisplay() {
        val currentLevel = progressStore.getCurrentLevel()
        val levelTitle = progressStore.getLevelTitle()
        val totalXP = progressStore.getTotalXP()

        levelText.text = "Level $currentLevel • $totalXP XP"

        // Set level icon color based on XP level
        val xpLevel = progressStore.getCurrentXPLevel()
        val iconColor = when (xpLevel) {
            com.skillvergence.mindsherpa.data.model.XPLevel.BRONZE -> R.color.brown
            com.skillvergence.mindsherpa.data.model.XPLevel.SILVER -> R.color.gray
            com.skillvergence.mindsherpa.data.model.XPLevel.GOLD -> R.color.gold
            com.skillvergence.mindsherpa.data.model.XPLevel.PLATINUM -> R.color.purple
            com.skillvergence.mindsherpa.data.model.XPLevel.DIAMOND -> R.color.blue_500
        }
        levelIcon.setColorFilter(androidx.core.content.ContextCompat.getColor(requireContext(), iconColor))
    }

    private fun setupRecyclerView(rootView: View) {
        recyclerView = rootView.findViewById(R.id.courses_recycler_view)
        swipeRefresh = rootView.findViewById(R.id.swipe_refresh)

        courseAdapter = CourseAdapter(
            onCourseClick = { course ->
                // Handle course selection - will implement video player
                onCourseSelected(course)
            },
            onAIQuestionSubmit = { question ->
                println("🎬 [VideoFragment] AI question submitted: '$question'")
                videoViewModel.askAI(question)
            },
            onQuickQuestionClick = { question ->
                println("🎬 [VideoFragment] Quick question clicked: '$question'")
                videoViewModel.askAI(question)
            }
        )

        recyclerView.layoutManager = LinearLayoutManager(requireContext())
        recyclerView.adapter = courseAdapter

        swipeRefresh.setOnRefreshListener {
            videoViewModel.refreshCourses()
        }
    }

    private fun observeViewModel() {
        videoViewModel.courses.observe(viewLifecycleOwner) { courses ->
            courseAdapter.updateCourses(courses)
            swipeRefresh.isRefreshing = false
        }

        videoViewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            swipeRefresh.isRefreshing = isLoading
        }

        videoViewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                // Show error message
                swipeRefresh.isRefreshing = false
                // TODO: Show proper error UI
            }
        }

        // AI observers
        videoViewModel.aiResponse.observe(viewLifecycleOwner) { response ->
            println("🎬 [VideoFragment] AI response received: '$response'")
            if (response.isNotEmpty()) {
                courseAdapter.updateAIResponse(response)

                // Award 10 XP for each AI interaction with Coach Nova
                progressStore.recordAIInteraction("Coach Nova interaction")
            }
        }

        videoViewModel.isAILoading.observe(viewLifecycleOwner) { isLoading ->
            println("🎬 [VideoFragment] AI loading state: $isLoading")
            courseAdapter.showAILoading(isLoading)
        }

        videoViewModel.aiError.observe(viewLifecycleOwner) { error ->
            error?.let {
                println("🎬 [VideoFragment] AI error: '$it'")
                courseAdapter.showAIError(it)
            }
        }

        // Gaming system observers
        progressStore.totalXP.observe(viewLifecycleOwner) {
            updateLevelDisplay()
        }

        progressStore.currentLevel.observe(viewLifecycleOwner) {
            updateLevelDisplay()
        }

        progressStore.currentStreak.observe(viewLifecycleOwner) {
            updateLevelDisplay()
        }
    }

    private fun onCourseSelected(course: Course) {
        // Navigate to video player
        val intent = VideoPlayerActivity.createIntent(requireContext(), course)
        startActivity(intent)
        println("✅ Launching video player for: ${course.title}")
    }

    private fun setupCoachNovaGesture(rootView: View) {
        // Find all Coach Nova icons in the RecyclerView (handled via adapter)
        // The gesture will be set up when the CourseAdapter creates the AI footer

        // Set up gesture handling for Coach Nova icon in CourseAdapter
        courseAdapter.setCoachNovaClickListener { handleCoachNovaTap() }
    }

    private fun handleCoachNovaTap() {
        coachNovaTapCount++

        // Reset tap count after 2 seconds if no more taps
        tapResetHandler.removeCallbacks(tapResetRunnable)
        tapResetHandler.postDelayed(tapResetRunnable, 2000)

        if (coachNovaTapCount >= 5) {
            // Reset tap count
            coachNovaTapCount = 0
            tapResetHandler.removeCallbacks(tapResetRunnable)

            // Launch teacher code entry
            val intent = Intent(requireContext(), TeacherCodeEntryActivity::class.java)
            startActivity(intent)
        }
    }
}

// Adapter moved to separate file - com.skillvergence.mindsherpa.ui.adapter.CourseAdapter