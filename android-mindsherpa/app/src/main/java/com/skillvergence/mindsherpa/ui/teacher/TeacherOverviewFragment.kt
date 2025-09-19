package com.skillvergence.mindsherpa.ui.teacher

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.lifecycleScope
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.config.AppConfig
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Teacher Overview Fragment
 * Shows dashboard overview with key stats and metrics
 */
class TeacherOverviewFragment : Fragment() {

    private val teacherViewModel: TeacherViewModel by activityViewModels()
    private lateinit var accessControlManager: AccessControlManager

    private lateinit var teacherNameText: TextView
    private lateinit var organizationNameText: TextView
    private lateinit var programNameText: TextView
    private lateinit var teacherEmailText: TextView
    private lateinit var classCodeSection: LinearLayout
    private lateinit var classCodeDisplay: TextView

    // Dashboard stats views
    private lateinit var totalStudentsCount: TextView
    private lateinit var activeTodayCount: TextView
    private lateinit var certificatesPendingCount: TextView
    private lateinit var courseCompletionPercentage: TextView

    // Caching for class code and dashboard stats
    private var lastStatsRefresh: Long = 0
    private val statsRefreshInterval = 30_000L // 30 seconds
    private var isDataLoaded = false
    private var hasLoadedInitialData = false

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl(AppConfig.apiURL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_teacher_overview, container, false)

        // Initialize AccessControlManager
        accessControlManager = AccessControlManager.getInstance(requireContext())

        setupViews(view)
        setupObservers()

        // Load teacher data from AccessControlManager (available immediately after validation)
        loadTeacherDataFromAccessControl()

        // Load dynamic data with smart refresh logic
        loadDynamicDataIfNeeded()

        return view
    }

    private fun setupViews(view: View) {
        teacherNameText = view.findViewById(R.id.teacher_name)
        organizationNameText = view.findViewById(R.id.organization_name)
        programNameText = view.findViewById(R.id.program_name)
        teacherEmailText = view.findViewById(R.id.teacher_email)
        classCodeSection = view.findViewById(R.id.class_code_section)
        classCodeDisplay = view.findViewById(R.id.current_class_code_display)

        // Dashboard stats views
        totalStudentsCount = view.findViewById(R.id.total_students_count)
        activeTodayCount = view.findViewById(R.id.active_today_count)
        certificatesPendingCount = view.findViewById(R.id.certificates_pending_count)
        courseCompletionPercentage = view.findViewById(R.id.course_completion_percentage)
    }

    private fun setupObservers() {
        // Observe teacher data from AccessControlManager (this has the validated teacher info)
        accessControlManager.teacherData.observe(viewLifecycleOwner) { teacherData ->
            teacherData?.let { updateTeacherProfileFromAccessControl(it) }
        }

        // Observe students changes for dashboard stats
        teacherViewModel.students.observe(viewLifecycleOwner) { students ->
            updateStudentStats(students)
        }

        teacherViewModel.schoolInfo.observe(viewLifecycleOwner) { info ->
            if (info != null && !hasLoadedInitialData) {
                hasLoadedInitialData = true
                loadDynamicDataIfNeeded()
            }
        }

        // Observe student summary for accurate stats
        teacherViewModel.studentSummary.observe(viewLifecycleOwner) { summary ->
            summary?.let { updateStatsFromSummary(it) }
        }

        // Observe certificates changes for dashboard stats
        teacherViewModel.certificates.observe(viewLifecycleOwner) { certificates ->
            updateCertificatesStats(certificates)
        }

    }

    private fun loadTeacherDataFromAccessControl() {
        // Load teacher data immediately if available (set during validation)
        accessControlManager.teacherData.value?.let { teacherData ->
            updateTeacherProfileFromAccessControl(teacherData)
        }
    }

    private fun updateTeacherProfileFromAccessControl(teacherData: com.skillvergence.mindsherpa.data.model.TeacherData) {
        // Update teacher profile from AccessControlManager (this data comes from API validation)
        teacherNameText.text = teacherData.name
        organizationNameText.text = teacherData.school
        programNameText.text = teacherData.program
        teacherEmailText.text = teacherData.email

        // Also update class code display immediately
        showClassCode(teacherData.classCode)

        // Load organization info in ViewModel using the schoolId from teacher data
        teacherViewModel.loadSchoolInfo(teacherData.schoolId)
    }

    private fun loadDynamicDataIfNeeded() {
        if (teacherViewModel.schoolInfo.value == null) {
            return
        }

        val currentTime = System.currentTimeMillis()
        val shouldRefresh = !isDataLoaded ||
                           (currentTime - lastStatsRefresh) > statsRefreshInterval

        if (shouldRefresh) {
            lastStatsRefresh = currentTime
            isDataLoaded = true

            // Load class code and dashboard stats (only if needed)
            loadClassCode()

            // Always refresh ViewModel data on first load
            teacherViewModel.refreshData()
        }
    }

    private fun loadClassCode() {
        // Class code comes from teacher data in AccessControlManager
        accessControlManager.teacherData.value?.let { teacherData ->
            showClassCode(teacherData.classCode)
        }
    }

    private fun loadClassCodeFromLocal() {
        val sharedPrefs = requireContext().getSharedPreferences("teacher_prefs", Context.MODE_PRIVATE)
        val localClassCode = sharedPrefs.getString("class_code", null)
        if (localClassCode != null) {
            showClassCode(localClassCode)
        } else {
            hideClassCode()
        }
    }

    private fun showClassCode(classCode: String) {
        classCodeDisplay.text = classCode
        classCodeSection.visibility = View.VISIBLE
    }

    private fun hideClassCode() {
        classCodeSection.visibility = View.GONE
    }

    private fun updateStudentStats(students: List<com.skillvergence.mindsherpa.data.api.ApiStudent>) {
        if (students.isEmpty()) {
            showDefaultStats()
            return
        }

        // Calculate stats from ViewModel data
        totalStudentsCount.text = students.size.toString()
        // Don't override activeTodayCount here - it comes from summary
        // Don't override courseCompletionPercentage here - it comes from summary avgCompletionRate
    }

    private fun updateCertificatesStats(certificates: List<com.skillvergence.mindsherpa.data.api.ApiCertificate>) {
        val pendingCount = certificates.count { it.status == "pending" }
        certificatesPendingCount.text = pendingCount.toString()
    }

    private fun updateStatsFromSummary(summary: com.skillvergence.mindsherpa.data.api.StudentSummary) {
        // Use API summary data for consistent active count across all tabs
        activeTodayCount.text = summary.activeToday.toString()

        // Use backend-calculated avgCompletionRate (our fix!)
        courseCompletionPercentage.text = "${summary.avgCompletionRate}%"
    }

    private fun showDefaultStats() {
        totalStudentsCount.text = "0"
        activeTodayCount.text = "0"
        courseCompletionPercentage.text = "0%"
        certificatesPendingCount.text = "0"
    }

    companion object {
        fun newInstance() = TeacherOverviewFragment()
    }
}
