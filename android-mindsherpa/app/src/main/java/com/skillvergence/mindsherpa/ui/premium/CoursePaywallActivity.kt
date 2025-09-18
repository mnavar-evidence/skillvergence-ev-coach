package com.skillvergence.mindsherpa.ui.premium

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.SubscriptionManager
import com.skillvergence.mindsherpa.data.model.AdvancedCertificateType
import com.skillvergence.mindsherpa.data.model.AdvancedCourse
import com.skillvergence.mindsherpa.data.model.AdvancedCourseData
import com.skillvergence.mindsherpa.data.model.AdvancedSkillLevel
import com.skillvergence.mindsherpa.ui.video.VideoDetailActivity

/**
 * Course Paywall Activity - Matches iOS CoursePaywallView
 * Shows purchase screen with 6-digit unlock codes
 */
class CoursePaywallActivity : AppCompatActivity() {

    private lateinit var courseTitle: TextView
    private lateinit var courseDescription: TextView
    private lateinit var courseDetails: LinearLayout
    private lateinit var codeInput: EditText
    private lateinit var unlockButton: Button
    private lateinit var errorMessage: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var backButton: ImageButton

    private var courseId: String = ""
    private var isValidating = false

    // Course unlock codes (matching iOS implementation)
    private val courseUnlockCodes = mapOf(
        "adv_1" to listOf("100001", "654321"), // Course 1.0 High Voltage Vehicle Safety
        "adv_2" to listOf("200002", "654322"), // Course 2.0 Electrical Level 1
        "adv_3" to listOf("300003", "654323"), // Course 3.0 Electrical Level 2
        "adv_4" to listOf("400004", "654324"), // Course 4.0 Electric Vehicle Supply Equipment
        "adv_5" to listOf("500005", "654325")  // Course 5.0 Introduction to Electric Vehicles
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_course_paywall)

        initializeViews()
        extractIntentData()
        setupUI()
        setupClickListeners()
    }

    private fun initializeViews() {
        courseTitle = findViewById(R.id.course_title)
        courseDescription = findViewById(R.id.course_description)
        courseDetails = findViewById(R.id.course_details)
        codeInput = findViewById(R.id.code_input)
        unlockButton = findViewById(R.id.unlock_button)
        errorMessage = findViewById(R.id.error_message)
        progressBar = findViewById(R.id.progress_bar)
        backButton = findViewById(R.id.back_button)
    }

    private fun extractIntentData() {
        courseId = intent.getStringExtra("course_id") ?: ""
        val title = intent.getStringExtra("course_title") ?: ""
        val description = intent.getStringExtra("course_description") ?: ""
        val estimatedHours = intent.getDoubleExtra("estimated_hours", 0.0)
        val xpReward = intent.getIntExtra("xp_reward", 0)
        val certificateTypeName = intent.getStringExtra("certificate_type") ?: ""
        val skillLevelName = intent.getStringExtra("skill_level") ?: ""

        courseTitle.text = title
        courseDescription.text = description

        // Build course details
        addCourseDetail("⏱️", "${estimatedHours.format(1)} hours of content")
        addCourseDetail("⭐", "$xpReward XP reward")
        addCourseDetail("🏆", getSkillLevelDisplayName(skillLevelName))
    }

    private fun setupUI() {
        // Setup code input with formatting and validation
        codeInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                // Clear error when user types
                if (errorMessage.visibility == View.VISIBLE) {
                    hideError()
                }

                // Update button state
                updateUnlockButtonState()
            }

            override fun afterTextChanged(s: Editable?) {
                // Limit to 6 digits
                val text = s.toString().filter { it.isDigit() }
                if (text.length > 6) {
                    codeInput.setText(text.take(6))
                    codeInput.setSelection(6)
                } else if (text != s.toString()) {
                    codeInput.setText(text)
                    codeInput.setSelection(text.length)
                }
            }
        })

        updateUnlockButtonState()
    }

    private fun setupClickListeners() {
        backButton.setOnClickListener {
            onBackPressedDispatcher.onBackPressed()
        }

        unlockButton.setOnClickListener {
            validateCourseCode()
        }
    }

    private fun addCourseDetail(icon: String, text: String) {
        val detailView = layoutInflater.inflate(R.layout.item_course_detail, courseDetails, false)
        val iconView = detailView.findViewById<TextView>(R.id.detail_icon)
        val textView = detailView.findViewById<TextView>(R.id.detail_text)

        iconView.text = icon
        textView.text = text

        courseDetails.addView(detailView)
    }

    private fun updateUnlockButtonState() {
        val codeLength = codeInput.text.toString().length
        val isValidLength = codeLength == 6

        unlockButton.isEnabled = isValidLength && !isValidating
        unlockButton.alpha = if (isValidLength && !isValidating) 1.0f else 0.5f
    }

    private fun validateCourseCode() {
        val code = codeInput.text.toString()
        if (code.length != 6) return

        isValidating = true
        showLoading()
        updateUnlockButtonState()

        // Simulate network delay (like iOS)
        unlockButton.postDelayed({
            val expectedCodes = courseUnlockCodes[courseId]
            if (expectedCodes?.contains(code) == true) {
                // Valid code - unlock course
                onCourseUnlocked()
            } else {
                // Invalid code
                showError("Invalid purchase code for this course. Please check your code and try again.")
            }

            isValidating = false
            hideLoading()
            updateUnlockButtonState()
        }, 1000)
    }

    private fun onCourseUnlocked() {
        // Save course as purchased in subscription manager
        SubscriptionManager.unlockCourse(courseId)

        // Show success message
        Toast.makeText(this, "Course unlocked successfully! 🎉", Toast.LENGTH_LONG).show()

        // Find the course data and navigate to video player
        val course = AdvancedCourseData.sampleAdvancedCourses.find { it.id == courseId }
        if (course != null) {
            openVideoPlayer(course)
        } else {
            // Fallback: just finish if course not found
            finish()
        }
    }

    private fun openVideoPlayer(course: AdvancedCourse) {
        // All courses now show module lists after unlock
        val intent = CourseModuleListActivity.createIntent(
            context = this,
            courseId = course.id,
            courseTitle = course.title,
            courseDescription = course.description
        )
        startActivity(intent)
        finish()
    }

    private fun showLoading() {
        progressBar.visibility = View.VISIBLE
        unlockButton.text = "Validating..."
    }

    private fun hideLoading() {
        progressBar.visibility = View.GONE
        unlockButton.text = "Unlock Course"
    }

    private fun showError(message: String) {
        errorMessage.text = message
        errorMessage.visibility = View.VISIBLE
    }

    private fun hideError() {
        errorMessage.visibility = View.GONE
    }

    private fun getSkillLevelDisplayName(skillLevel: String): String {
        return try {
            AdvancedSkillLevel.valueOf(skillLevel).displayName
        } catch (e: Exception) {
            skillLevel.replaceFirstChar { it.uppercaseChar() }
        }
    }
}

// Extension function for Double formatting
private fun Double.format(digits: Int) = "%.${digits}f".format(this)
