package com.skillvergence.mindsherpa.ui.teacher

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import com.skillvergence.mindsherpa.data.model.Student
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Teacher Students Fragment
 * Shows student roster with search and filtering
 */
class TeacherStudentsFragment : Fragment() {

    private lateinit var searchEditText: EditText
    private lateinit var tabAll: CardView
    private lateinit var tabActive: CardView
    private lateinit var tabNeedsAttention: CardView
    private lateinit var tabTopPerformers: CardView
    private lateinit var tabAllCount: TextView
    private lateinit var tabActiveCount: TextView
    private lateinit var tabNeedsAttentionCount: TextView
    private lateinit var tabTopPerformersCount: TextView
    private lateinit var totalStudentsStat: TextView
    private lateinit var avgXpStat: TextView
    private lateinit var activeTodayStat: TextView
    private lateinit var studentsRecyclerView: RecyclerView

    private var allStudents = listOf<Student>()
    private var currentFilter = FilterType.ALL
    private var searchQuery = ""

    private lateinit var studentAdapter: StudentAdapter

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl("http://192.168.86.46:3000/api/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    enum class FilterType {
        ALL, ACTIVE, NEEDS_ATTENTION, TOP_PERFORMERS
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_teacher_students, container, false)

        setupViews(view)
        setupRecyclerView()
        setupSearch()
        setupFilterTabs()
        loadStudentData()

        return view
    }

    private fun setupViews(view: View) {
        searchEditText = view.findViewById(R.id.search_students)
        tabAll = view.findViewById(R.id.tab_all)
        tabActive = view.findViewById(R.id.tab_active)
        tabNeedsAttention = view.findViewById(R.id.tab_needs_attention)
        tabTopPerformers = view.findViewById(R.id.tab_top_performers)
        tabAllCount = view.findViewById(R.id.tab_all_count)
        tabActiveCount = view.findViewById(R.id.tab_active_count)
        tabNeedsAttentionCount = view.findViewById(R.id.tab_needs_attention_count)
        tabTopPerformersCount = view.findViewById(R.id.tab_top_performers_count)
        totalStudentsStat = view.findViewById(R.id.total_students_stat)
        avgXpStat = view.findViewById(R.id.avg_xp_stat)
        activeTodayStat = view.findViewById(R.id.active_today_stat)
        studentsRecyclerView = view.findViewById(R.id.students_recycler_view)
    }

    private fun setupRecyclerView() {
        studentAdapter = StudentAdapter { student ->
            // Handle student click - navigate to student detail
            navigateToStudentDetail(student)
        }

        studentsRecyclerView.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = studentAdapter
        }
    }

    private fun setupSearch() {
        searchEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                searchQuery = s?.toString()?.trim() ?: ""
                applyFiltersAndSearch()
            }
        })
    }

    private fun setupFilterTabs() {
        tabAll.setOnClickListener {
            setActiveTab(FilterType.ALL)
        }

        tabActive.setOnClickListener {
            setActiveTab(FilterType.ACTIVE)
        }

        tabNeedsAttention.setOnClickListener {
            setActiveTab(FilterType.NEEDS_ATTENTION)
        }

        tabTopPerformers.setOnClickListener {
            setActiveTab(FilterType.TOP_PERFORMERS)
        }
    }

    private fun setActiveTab(filterType: FilterType) {
        currentFilter = filterType

        // Reset all tabs
        resetTabStyle(tabAll, tabAllCount)
        resetTabStyle(tabActive, tabActiveCount)
        resetTabStyle(tabNeedsAttention, tabNeedsAttentionCount)
        resetTabStyle(tabTopPerformers, tabTopPerformersCount)

        // Set active tab
        when (filterType) {
            FilterType.ALL -> setActiveTabStyle(tabAll, tabAllCount)
            FilterType.ACTIVE -> setActiveTabStyle(tabActive, tabActiveCount)
            FilterType.NEEDS_ATTENTION -> setActiveTabStyle(tabNeedsAttention, tabNeedsAttentionCount)
            FilterType.TOP_PERFORMERS -> setActiveTabStyle(tabTopPerformers, tabTopPerformersCount)
        }

        applyFiltersAndSearch()
    }

    private fun resetTabStyle(tab: CardView, countText: TextView) {
        // Inactive tab: light background, black text
        tab.setCardBackgroundColor(Color.parseColor("#E3E3E3"))

        // Set both the label and count text to black for inactive tabs
        val textViews = getTabTextViews(tab)
        textViews.forEach { textView ->
            textView.setTextColor(Color.BLACK)
        }
    }

    private fun setActiveTabStyle(tab: CardView, countText: TextView) {
        // Active tab: purple background, white text
        tab.setCardBackgroundColor(Color.parseColor("#6200EE"))

        // Set both the label and count text to white for active tabs
        val textViews = getTabTextViews(tab)
        textViews.forEach { textView ->
            textView.setTextColor(Color.WHITE)
        }
    }

    private fun getTabTextViews(tab: CardView): List<TextView> {
        val textViews = mutableListOf<TextView>()
        val linearLayout = tab.getChildAt(0) as? ViewGroup
        linearLayout?.let { layout ->
            for (i in 0 until layout.childCount) {
                val child = layout.getChildAt(i)
                if (child is TextView) {
                    textViews.add(child)
                }
            }
        }
        return textViews
    }

    private fun applyFiltersAndSearch() {
        var filteredStudents = allStudents.filter { student ->
            // Apply search filter
            val matchesSearch = if (searchQuery.isEmpty()) {
                true
            } else {
                student.fullName.contains(searchQuery, ignoreCase = true) ||
                student.email?.contains(searchQuery, ignoreCase = true) == true
            }

            // Apply tab filter
            val matchesFilter = when (currentFilter) {
                FilterType.ALL -> true
                FilterType.ACTIVE -> student.isActive
                FilterType.NEEDS_ATTENTION -> student.needsAttention
                FilterType.TOP_PERFORMERS -> true // All students, will be filtered by top 10 later
            }

            matchesSearch && matchesFilter
        }

        // Special handling for Top Performers - show top 10 by XP
        if (currentFilter == FilterType.TOP_PERFORMERS) {
            filteredStudents = filteredStudents
                .sortedByDescending { it.xp }
                .take(10)
        } else {
            // Default sorting by name for other filters
            filteredStudents = filteredStudents.sortedBy { it.fullName }
        }

        studentAdapter.submitList(filteredStudents)
    }

    private fun loadStudentData() {
        lifecycleScope.launch {
            try {
                // TODO: Get actual school ID from AccessControlManager
                val schoolId = "fallbrook-hs"
                println("Loading student data for school: $schoolId")
                println("API Base URL: http://192.168.86.46:3000/api/")

                val response = teacherApiService.getStudentRoster(schoolId)
                println("Response code: ${response.code()}")
                println("Response successful: ${response.isSuccessful}")

                if (response.isSuccessful && response.body() != null) {
                    val studentRoster = response.body()!!
                    println("Received ${studentRoster.students.size} students")
                    updateUI(studentRoster.students, studentRoster.summary)
                } else {
                    println("API call failed - response code: ${response.code()}")
                    println("Error body: ${response.errorBody()?.string()}")
                    // Show empty state or error - no mock data
                    showEmptyState()
                }
            } catch (e: Exception) {
                println("Exception occurred: ${e.message}")
                e.printStackTrace()
                // Network error - show empty state
                showEmptyState()
            }
        }
    }

    private fun updateUI(students: List<com.skillvergence.mindsherpa.data.api.ApiStudent>, summary: com.skillvergence.mindsherpa.data.api.StudentSummary) {
        // Convert API students to local Student model
        allStudents = students.map { apiStudent ->
            // Parse full name into first/last
            val nameParts = apiStudent.name.split(" ", limit = 2)
            val firstName = nameParts.getOrNull(0) ?: ""
            val lastName = nameParts.getOrNull(1) ?: ""

            // Determine activity status - improved logic
            val isActive = when {
                apiStudent.lastActive.contains("minute", ignoreCase = true) -> true
                apiStudent.lastActive.contains("hour", ignoreCase = true) -> {
                    // Extract hours and check if less than 24
                    val hourMatch = Regex("(\\d+)\\s*hour").find(apiStudent.lastActive)
                    val hours = hourMatch?.groupValues?.get(1)?.toIntOrNull() ?: 25
                    hours < 24
                }
                apiStudent.lastActive.contains("today", ignoreCase = true) -> true
                else -> false
            }

            // Needs attention: inactive for more than 7 days OR very low XP
            val needsAttention = when {
                !isActive && (apiStudent.lastActive.contains("day", ignoreCase = true) ||
                               apiStudent.lastActive.contains("week", ignoreCase = true) ||
                               apiStudent.lastActive.contains("month", ignoreCase = true)) -> true
                apiStudent.totalXP < 100 -> true // Very low XP threshold
                else -> false
            }

            Student(
                id = apiStudent.id,
                firstName = firstName,
                lastName = lastName,
                email = apiStudent.email,
                xp = apiStudent.totalXP,
                level = apiStudent.currentLevel,
                lastActivity = if (isActive) apiStudent.lastActive else null,
                isActive = isActive,
                needsAttention = needsAttention
            )
        }

        // Update stats
        totalStudentsStat.text = summary.totalStudents.toString()
        avgXpStat.text = summary.avgXP.toString()
        activeTodayStat.text = summary.activeToday.toString()

        // Update tab counts
        val activeCount = allStudents.count { it.isActive }
        val needsAttentionCount = allStudents.count { it.needsAttention }
        val topPerformersCount = minOf(10, allStudents.size)

        tabAllCount.text = "(${allStudents.size})"
        tabActiveCount.text = "($activeCount)"
        tabNeedsAttentionCount.text = "($needsAttentionCount)"
        tabTopPerformersCount.text = "($topPerformersCount)"

        // Apply filters
        applyFiltersAndSearch()
    }

    private fun showEmptyState() {
        allStudents = emptyList()

        // Reset stats to 0
        totalStudentsStat.text = "0"
        avgXpStat.text = "0"
        activeTodayStat.text = "0"

        // Reset tab counts
        tabAllCount.text = "(0)"
        tabActiveCount.text = "(0)"
        tabNeedsAttentionCount.text = "(0)"
        tabTopPerformersCount.text = "(0)"

        // Clear list
        studentAdapter.submitList(emptyList())
    }

    private fun navigateToStudentDetail(student: Student) {
        val intent = Intent(requireContext(), StudentDetailActivity::class.java)
        intent.putExtra("student_id", student.id)
        intent.putExtra("student_name", student.fullName)
        intent.putExtra("student_email", student.email)
        intent.putExtra("student_level", student.level)
        intent.putExtra("student_xp", student.xp)
        intent.putExtra("student_activity", student.lastActivity)
        intent.putExtra("is_active", student.isActive)
        intent.putExtra("needs_attention", student.needsAttention)
        startActivity(intent)
    }

    companion object {
        fun newInstance() = TeacherStudentsFragment()
    }
}