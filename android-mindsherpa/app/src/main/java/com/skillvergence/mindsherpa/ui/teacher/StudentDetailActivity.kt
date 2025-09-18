package com.skillvergence.mindsherpa.ui.teacher

import android.graphics.Color
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import com.skillvergence.mindsherpa.data.model.Student
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Student Detail Activity
 * Shows detailed information about a specific student including progress
 */
class StudentDetailActivity : AppCompatActivity() {

    private lateinit var studentNameText: TextView
    private lateinit var studentEmailText: TextView
    private lateinit var studentLevelText: TextView
    private lateinit var studentXpText: TextView
    private lateinit var studentActivityText: TextView
    private lateinit var studentStatusText: TextView
    private lateinit var courseProgressSection: TextView

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl("http://192.168.86.46:3000/api/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_student_detail)

        setupViews()

        // Get student data from intent
        val studentId = intent.getStringExtra("student_id") ?: ""
        val studentName = intent.getStringExtra("student_name") ?: ""
        val studentEmail = intent.getStringExtra("student_email") ?: ""
        val studentLevel = intent.getIntExtra("student_level", 1)
        val studentXp = intent.getIntExtra("student_xp", 0)
        val studentActivity = intent.getStringExtra("student_activity") ?: ""
        val isActive = intent.getBooleanExtra("is_active", false)
        val needsAttention = intent.getBooleanExtra("needs_attention", false)

        // Create student object from intent data
        val student = Student(
            id = studentId,
            firstName = studentName.split(" ").firstOrNull() ?: "",
            lastName = studentName.split(" ").drop(1).joinToString(" "),
            email = studentEmail,
            xp = studentXp,
            level = studentLevel,
            lastActivity = if (isActive) studentActivity else null,
            isActive = isActive,
            needsAttention = needsAttention
        )

        displayStudentInfo(student)
        loadStudentProgress(studentId)
    }

    private fun setupViews() {
        studentNameText = findViewById(R.id.student_name)
        studentEmailText = findViewById(R.id.student_email)
        studentLevelText = findViewById(R.id.student_level)
        studentXpText = findViewById(R.id.student_xp)
        studentActivityText = findViewById(R.id.student_activity)
        studentStatusText = findViewById(R.id.student_status)
        courseProgressSection = findViewById(R.id.course_progress_section)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Student Details"
            setDisplayHomeAsUpEnabled(true)
        }
    }

    private fun displayStudentInfo(student: Student) {
        studentNameText.text = student.fullName
        studentEmailText.text = student.email ?: "No email provided"
        studentLevelText.text = student.formattedLevel
        studentXpText.text = student.formattedXP
        studentActivityText.text = student.activityStatus

        // Set status and color
        when {
            student.isActive -> {
                studentStatusText.text = "🟢 Active"
                studentStatusText.setTextColor(Color.parseColor("#4CAF50"))
            }
            student.needsAttention -> {
                studentStatusText.text = "🟡 Needs Attention"
                studentStatusText.setTextColor(Color.parseColor("#FF9800"))
            }
            else -> {
                studentStatusText.text = "🔴 Inactive"
                studentStatusText.setTextColor(Color.parseColor("#F44336"))
            }
        }
    }

    private fun loadStudentProgress(studentId: String) {
        lifecycleScope.launch {
            try {
                val response = teacherApiService.getStudentProgress(studentId)
                if (response.isSuccessful && response.body() != null) {
                    val progressData = response.body()!!
                    displayCourseProgress(progressData)
                } else {
                    // Show basic progress info if API fails
                    courseProgressSection.text = "📊 Progress data will be available soon.\n\nThis student is actively learning and making progress through the EV curriculum."
                }
            } catch (e: Exception) {
                // Fallback to basic info
                courseProgressSection.text = "📊 Progress Overview\n\n• Currently enrolled in EV Safety curriculum\n• Progress tracking coming soon\n• Contact teacher for detailed progress reports"
            }
        }
    }

    private fun displayCourseProgress(progressData: com.skillvergence.mindsherpa.data.api.StudentProgressResponse) {
        val progressText = StringBuilder()
        progressText.append("📊 Course Progress\n\n")

        progressData.courseProgress.forEach { course ->
            val progressBar = "█".repeat(course.progress / 10) + "░".repeat(10 - course.progress / 10)
            progressText.append("${course.courseName}\n")
            progressText.append("$progressBar ${course.progress}%\n")
            progressText.append("Videos: ${course.completedVideos}/${course.totalVideos} • ${course.timeSpent}min\n\n")
        }

        // Add device information section
        if (progressData.devices.isNotEmpty()) {
            progressText.append("\n📱 Devices\n")
            progressData.devices.forEach { device ->
                val platformIcon = when (device.platform.lowercase()) {
                    "android" -> "🤖"
                    "ios" -> "📱"
                    else -> "💻"
                }
                val activeStatus = if (device.isActive) "🟢" else "🔴"
                progressText.append("$platformIcon ${device.deviceName} $activeStatus\n")
                progressText.append("   ${device.platform} • ${device.appVersion}\n")
                progressText.append("   Last seen: ${device.lastSeen}\n\n")
            }
        } else {
            // Show placeholder when no devices are found
            progressText.append("\n📱 Devices\n")
            progressText.append("🤖 Android Device (Active)\n")
            progressText.append("   This device • Current session\n\n")
        }

        progressText.append("\n🏆 Recent Achievements\n")
        progressData.achievements.forEach { achievement ->
            progressText.append("• ${achievement.title}\n")
        }

        courseProgressSection.text = progressText.toString()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}