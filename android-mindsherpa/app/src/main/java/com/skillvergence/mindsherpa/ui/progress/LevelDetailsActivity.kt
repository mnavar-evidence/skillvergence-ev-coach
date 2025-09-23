package com.skillvergence.mindsherpa.ui.progress

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.XPLevel
import com.skillvergence.mindsherpa.data.model.CertificationLevel
import com.skillvergence.mindsherpa.data.persistence.ProgressStore

/**
 * Level Details Activity - Matches iOS LevelDetailsView
 * Shows comprehensive progress information including XP, levels, and certifications
 */
class LevelDetailsActivity : AppCompatActivity() {

    private lateinit var progressStore: ProgressStore

    // Views
    private lateinit var toolbar: MaterialToolbar
    private lateinit var levelIcon: ImageView
    private lateinit var levelTitle: TextView
    private lateinit var totalXP: TextView
    private lateinit var xpProgressBar: ProgressBar
    private lateinit var currentProgress: TextView
    private lateinit var nextLevel: TextView
    private lateinit var xpNeededMessage: TextView
    private lateinit var certificationIcon: ImageView
    private lateinit var certificationLevel: TextView
    private lateinit var coursesCompleted: TextView
    private lateinit var coursesNeeded: TextView
    private lateinit var shareFab: FloatingActionButton

    // RecyclerViews
    private lateinit var levelProgressionRecycler: RecyclerView
    private lateinit var certificationProgressionRecycler: RecyclerView
    private lateinit var courseCompletionRecycler: RecyclerView
    private lateinit var advancedCourseRecycler: RecyclerView

    companion object {
        fun createIntent(context: Context): Intent {
            return Intent(context, LevelDetailsActivity::class.java)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_level_details)

        progressStore = ProgressStore.getInstance(this)

        initializeViews()
        setupToolbar()
        setupRecyclerViews()
        updateUI()
        setupListeners()
    }

    private fun initializeViews() {
        toolbar = findViewById(R.id.toolbar)
        levelIcon = findViewById(R.id.level_icon)
        levelTitle = findViewById(R.id.level_title)
        totalXP = findViewById(R.id.total_xp)
        xpProgressBar = findViewById(R.id.xp_progress_bar)
        currentProgress = findViewById(R.id.current_progress)
        nextLevel = findViewById(R.id.next_level)
        xpNeededMessage = findViewById(R.id.xp_needed_message)
        certificationIcon = findViewById(R.id.certification_icon)
        certificationLevel = findViewById(R.id.certification_level)
        coursesCompleted = findViewById(R.id.courses_completed)
        coursesNeeded = findViewById(R.id.courses_needed)
        shareFab = findViewById(R.id.share_fab)

        levelProgressionRecycler = findViewById(R.id.level_progression_recycler)
        certificationProgressionRecycler = findViewById(R.id.certification_progression_recycler)
        courseCompletionRecycler = findViewById(R.id.course_completion_recycler)
        advancedCourseRecycler = findViewById(R.id.advanced_course_recycler)
    }

    private fun setupToolbar() {
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setDisplayShowHomeEnabled(true)

        toolbar.setNavigationOnClickListener {
            finish()
        }
    }

    private fun setupRecyclerViews() {
        // Level Progression
        levelProgressionRecycler.layoutManager = LinearLayoutManager(this)
        val levelProgressionAdapter = LevelProgressionAdapter(
            getCurrentXPLevel(),
            progressStore.getTotalXP()
        )
        levelProgressionRecycler.adapter = levelProgressionAdapter

        // Certification Progression
        certificationProgressionRecycler.layoutManager = LinearLayoutManager(this)
        val certificationProgressionAdapter = CertificationProgressionAdapter(
            getCurrentCertificationLevel(),
            progressStore.getCompletedCoursesCount()
        )
        certificationProgressionRecycler.adapter = certificationProgressionAdapter

        // Course Completion
        courseCompletionRecycler.layoutManager = LinearLayoutManager(this)
        val courseCompletionAdapter = CourseCompletionAdapter(
            progressStore.getCourseCompletionDetails()
        )
        courseCompletionRecycler.adapter = courseCompletionAdapter

        // Advanced Course Overview
        advancedCourseRecycler.layoutManager = LinearLayoutManager(this)
        val advancedCourseAdapter = AdvancedCourseOverviewAdapter(getAdvancedCourseOverview())
        advancedCourseRecycler.adapter = advancedCourseAdapter
    }

    private fun updateUI() {
        val currentXPLevel = getCurrentXPLevel()
        val totalXPValue = progressStore.getTotalXP()
        val progress = progressStore.getXPProgressToNextLevel()
        val currentCertLevel = getCurrentCertificationLevel()
        val completedCourses = progressStore.getCompletedCoursesCount()

        // Update current status
        levelTitle.text = currentXPLevel.displayName
        totalXP.text = "$totalXPValue XP"

        // Set level icon based on current level
        val iconRes = when (currentXPLevel) {
            XPLevel.BRONZE -> R.drawable.ic_star_24dp
            XPLevel.SILVER -> R.drawable.ic_star_24dp
            XPLevel.GOLD -> R.drawable.ic_star_24dp
            XPLevel.PLATINUM -> R.drawable.ic_star_24dp
            XPLevel.DIAMOND -> R.drawable.ic_star_24dp
        }
        levelIcon.setImageResource(iconRes)

        // Update progress bar
        val progressPercentage = (progress.percentage * 100).toInt()
        xpProgressBar.progress = progressPercentage
        currentProgress.text = "${progress.current}/${progress.needed} XP"

        // Update next level text
        if (currentXPLevel != XPLevel.DIAMOND) {
            val nextLevelIndex = currentXPLevel.ordinal + 1
            if (nextLevelIndex < XPLevel.values().size) {
                val nextXPLevel = XPLevel.values()[nextLevelIndex]
                nextLevel.text = "→ ${nextXPLevel.displayName}"
            }
        } else {
            nextLevel.text = "Max Level!"
        }

        // Update XP needed message
        val userName = progressStore.getUserName()
        val xpNeeded = progressStore.getXPForNextLevel() - totalXPValue
        val message = if (userName.isEmpty()) {
            "Need $xpNeeded more XP to level up!"
        } else {
            "$userName, you need $xpNeeded more XP to level up!"
        }
        xpNeededMessage.text = message

        // Update certification status
        certificationLevel.text = currentCertLevel.displayName
        coursesCompleted.text = "$completedCourses/5 courses completed"

        // Set certification icon
        val certIconRes = when (currentCertLevel) {
            CertificationLevel.NONE -> R.drawable.ic_person_24dp
            CertificationLevel.FOUNDATION -> R.drawable.ic_star_24dp
            CertificationLevel.ASSOCIATE -> R.drawable.ic_star_24dp
            CertificationLevel.PROFESSIONAL -> R.drawable.ic_star_24dp
            CertificationLevel.CERTIFIED -> R.drawable.ic_star_24dp
        }
        certificationIcon.setImageResource(certIconRes)

        // Update courses needed text
        if (currentCertLevel != CertificationLevel.CERTIFIED) {
            val nextCertLevel = getNextCertificationLevel(currentCertLevel)
            val coursesNeededCount = nextCertLevel.coursesRequired - completedCourses
            coursesNeeded.text = "$coursesNeededCount more course${if (coursesNeededCount == 1) "" else "s"} for ${nextCertLevel.shortName}"
        } else {
            coursesNeeded.text = "Fully Certified!"
        }
    }

    private fun setupListeners() {
        shareFab.setOnClickListener {
            shareProgress()
        }
    }

    private fun shareProgress() {
        val level = progressStore.getCurrentLevel()
        val xp = progressStore.getTotalXP()
        val levelName = progressStore.getLevelTitle()

        val shareText = "🚀 Level Up! Just reached Level $level - $levelName!\n\n⭐ $xp total XP earned\n📈 Advancing my EV expertise on WattWorks\n\n#EVTraining #LevelUp #ElectricVehicles"

        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, shareText)
            type = "text/plain"
        }

        startActivity(Intent.createChooser(shareIntent, "Share Progress"))
    }

    private fun getCurrentXPLevel(): XPLevel {
        return progressStore.getCurrentXPLevel()
    }

    private fun getCurrentCertificationLevel(): CertificationLevel {
        return progressStore.getCurrentCertificationLevel()
    }

    private fun getNextCertificationLevel(current: CertificationLevel): CertificationLevel {
        val allLevels = CertificationLevel.values()
        val currentIndex = allLevels.indexOf(current)
        return if (currentIndex < allLevels.size - 1) {
            allLevels[currentIndex + 1]
        } else {
            CertificationLevel.CERTIFIED // Already at max
        }
    }

    private fun getAdvancedCourseOverview(): List<AdvancedCourseOverviewItem> {
        return listOf(
            AdvancedCourseOverviewItem(1, "1.0 High Voltage Safety", 7, "1:18:03"),
            AdvancedCourseOverviewItem(2, "2.0 Electrical Level 1", 4, "3:53:40"),
            AdvancedCourseOverviewItem(3, "3.0 Electrical Level 2", 2, "2:30:32"),
            AdvancedCourseOverviewItem(4, "4.0 EV Supply Equipment", 2, "1:12:19"),
            AdvancedCourseOverviewItem(5, "5.0 EV Architecture", 3, "2:32:42")
        )
    }
}

// Data classes for adapters
data class LevelProgressionItem(
    val level: XPLevel,
    val xpRange: String,
    val isCurrentOrPast: Boolean,
    val isCurrent: Boolean
)

data class CertificationProgressionItem(
    val level: CertificationLevel,
    val requirements: String,
    val isCurrentOrPast: Boolean,
    val isCurrent: Boolean,
    val completedCourses: Int
)

data class AdvancedCourseOverviewItem(
    val courseNumber: Int,
    val title: String,
    val modules: Int,
    val duration: String
)