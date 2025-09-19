package com.skillvergence.mindsherpa.ui.teacher

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.skillvergence.mindsherpa.config.AppConfig
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import com.skillvergence.mindsherpa.data.api.ApiStudent
import com.skillvergence.mindsherpa.data.api.ApiCertificate
import com.skillvergence.mindsherpa.data.api.CodeUsage
import com.skillvergence.mindsherpa.data.api.StudentSummary
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Teacher ViewModel for Android
 * Corresponds to TeacherViewModel.swift in iOS
 */
class TeacherViewModel : ViewModel() {

    // Live Data for UI observation
    private val _students = MutableLiveData<List<ApiStudent>>()
    val students: LiveData<List<ApiStudent>> = _students

    private val _certificates = MutableLiveData<List<ApiCertificate>>()
    val certificates: LiveData<List<ApiCertificate>> = _certificates

    private val _codeUsage = MutableLiveData<CodeUsage>()
    val codeUsage: LiveData<CodeUsage> = _codeUsage

    private val _studentSummary = MutableLiveData<StudentSummary>()
    val studentSummary: LiveData<StudentSummary> = _studentSummary

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage

    // School information
    private val _schoolInfo = MutableLiveData<SchoolInfo>()
    val schoolInfo: LiveData<SchoolInfo> = _schoolInfo

    // Caching mechanism
    private var isDataLoaded = false
    private var lastRefreshTime: Long = 0
    private val refreshInterval = 30_000L // 30 seconds minimum between refreshes

    // Teacher information will be loaded from database via API
    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl(AppConfig.apiURL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    init {
        // School info will be loaded from API during teacher authentication
    }

    fun loadSchoolInfo(schoolId: String) {
        viewModelScope.launch {
            try {
                // This should be called during teacher authentication
                // to load school and teacher info from database
                val response = teacherApiService.getSchoolConfig(schoolId)
                if (response.isSuccessful) {
                    val schoolConfig = response.body()?.school
                    schoolConfig?.let { config ->
                        val schoolInfo = SchoolInfo(
                            id = config.id,
                            name = config.name,
                            district = config.district,
                            program = config.program,
                            instructor = Teacher(
                                id = config.instructor.id,
                                fullName = config.instructor.name,
                                email = config.instructor.email,
                                school = config.name,
                                department = config.instructor.department ?: "",
                                program = config.program
                            ),
                            totalStudents = 0, // Will be populated when students load
                            activeLicenses = config.bulkLicenses
                        )
                        _schoolInfo.value = schoolInfo
                        // Trigger initial data load now that school info is available
                        loadClassData()
                    }
                }
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load school info: ${e.message}"
            }
        }
    }

    fun loadClassData() {
        if (_schoolInfo.value?.id == null) {
            println("📊 Waiting for school info before loading class data")
            return
        }

        val currentTime = System.currentTimeMillis()
        val shouldRefresh = !isDataLoaded ||
                           (currentTime - lastRefreshTime) > refreshInterval

        if (!shouldRefresh) {
            println("📊 Using cached teacher dashboard data")
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            lastRefreshTime = currentTime

            try {
                println("📊 Refreshing teacher dashboard data...")

                // Load students
                loadStudents()

                // Load certificates
                loadCertificates()

                // Load code usage
                loadCodeUsage()

                isDataLoaded = true
                println("📊 Teacher dashboard data refreshed successfully")

            } catch (e: Exception) {
                _errorMessage.value = "Failed to load class data: ${e.message}"
                println("❌ Failed to refresh teacher dashboard: ${e.message}")
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun loadStudents() {
        try {
            val schoolId = _schoolInfo.value?.id ?: return
            val response = teacherApiService.getStudentRoster(schoolId)
            if (response.isSuccessful) {
                val roster = response.body()
                val students = roster?.students ?: emptyList()
                val summary = roster?.summary
                _students.value = students
                summary?.let { _studentSummary.value = it }
            } else {
                _errorMessage.value = "Failed to load students"
            }
        } catch (e: Exception) {
            _errorMessage.value = "Network error loading students: ${e.message}"
        }
    }

    private suspend fun loadCertificates() {
        try {
            val schoolId = _schoolInfo.value?.id ?: return
            val response = teacherApiService.getCertificates(schoolId)
            if (response.isSuccessful) {
                _certificates.value = response.body()?.certificates ?: emptyList()
            } else {
                _errorMessage.value = "Failed to load certificates"
            }
        } catch (e: Exception) {
            _errorMessage.value = "Network error loading certificates: ${e.message}"
        }
    }

    private suspend fun loadCodeUsage() {
        try {
            val schoolId = _schoolInfo.value?.id ?: return
            val response = teacherApiService.getCodeUsage(schoolId)
            if (response.isSuccessful) {
                _codeUsage.value = response.body()?.usage
            } else {
                _errorMessage.value = "Failed to load code usage"
            }
        } catch (e: Exception) {
            _errorMessage.value = "Network error loading code usage: ${e.message}"
        }
    }

    fun getStudentsByLevel(level: String): List<ApiStudent> {
        return _students.value?.filter { it.courseLevel == level } ?: emptyList()
    }

    fun getPendingCertificates(): List<ApiCertificate> {
        return _certificates.value?.filter { it.status == "pending" } ?: emptyList()
    }

    fun getActiveStudentsToday(): Int {
        return _students.value?.count { student ->
            // Determine activity status - improved logic (matches TeacherStudentsFragment)
            when {
                student.lastActive.contains("minute", ignoreCase = true) -> true
                student.lastActive.contains("hour", ignoreCase = true) -> {
                    // Extract hours and check if less than 24
                    val hourMatch = Regex("(\\d+)\\s*hour").find(student.lastActive)
                    val hours = hourMatch?.groupValues?.get(1)?.toIntOrNull() ?: 25
                    hours < 24
                }
                student.lastActive.contains("today", ignoreCase = true) -> true
                else -> false
            }
        } ?: 0
    }

    fun getAverageXP(): Int {
        val students = _students.value ?: return 0
        return if (students.isEmpty()) 0 else students.sumOf { it.totalXP } / students.size
    }

    fun getTotalCompletedCourses(): Int {
        return _students.value?.sumOf { it.completedCourses } ?: 0
    }

    fun getTopPerformers(count: Int = 5): List<ApiStudent> {
        return _students.value
            ?.sortedByDescending { it.totalXP }
            ?.take(count) ?: emptyList()
    }

    fun getStudentsNeedingAttention(): List<ApiStudent> {
        val sevenDaysAgo = LocalDateTime.now().minusDays(7)
        return _students.value?.filter { student ->
            try {
                val lastActive = LocalDateTime.parse(student.lastActive.substring(0, 19))
                lastActive.isBefore(sevenDaysAgo) || student.totalXP < 25
            } catch (e: Exception) {
                false
            }
        } ?: emptyList()
    }

    fun refreshData() {
        // Force refresh by resetting cache
        isDataLoaded = false
        loadClassData()
    }
}

// MARK: - Data Models

data class Teacher(
    val id: String,
    val fullName: String,
    val email: String,
    val school: String,
    val department: String,
    val program: String
)

data class SchoolInfo(
    val id: String,
    val name: String,
    val district: String,
    val program: String,
    val instructor: Teacher,
    val totalStudents: Int,
    val activeLicenses: Int
)

data class ClassStudent(
    val id: String,
    val name: String,
    val email: String,
    val courseLevel: String,
    val totalXP: Int,
    val currentLevel: Int,
    val completedCourses: Int,
    val lastActive: String,
    val streak: Int,
    val enrollmentDate: String
) {
    fun getEngagementStatus(): EngagementStatus {
        return when {
            totalXP >= 500 -> EngagementStatus.HIGH
            totalXP >= 100 -> EngagementStatus.MEDIUM
            totalXP >= 25 -> EngagementStatus.LOW
            else -> EngagementStatus.AT_RISK
        }
    }

    fun getProgressPercentage(): Int {
        return when (courseLevel) {
            "Transportation Tech I" -> minOf(100, (completedCourses * 50))
            "Transportation Tech II" -> minOf(100, (completedCourses * 33))
            "Transportation Tech III" -> minOf(100, (completedCourses * 25))
            else -> 0
        }
    }
}

enum class EngagementStatus {
    HIGH, MEDIUM, LOW, AT_RISK
}
