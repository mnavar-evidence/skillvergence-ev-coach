package com.skillvergence.mindsherpa.data.api

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.google.gson.Gson
import com.skillvergence.mindsherpa.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.*

/**
 * StudentProgressAPI - Handles device registration, class joining, and progress sync
 */
class StudentProgressAPI private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: StudentProgressAPI? = null

        fun getInstance(context: Context): StudentProgressAPI {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: StudentProgressAPI(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private val sharedPrefs: SharedPreferences =
        context.getSharedPreferences("student_progress_api", Context.MODE_PRIVATE)
    private val gson = Gson()
    private val apiService = NetworkModule.createApiService()

    // LiveData
    private val _isDeviceRegistered = MutableLiveData<Boolean>()
    val isDeviceRegistered: LiveData<Boolean> = _isDeviceRegistered

    private val _studentInfo = MutableLiveData<StudentInfo?>()
    val studentInfo: LiveData<StudentInfo?> = _studentInfo

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _lastError = MutableLiveData<String?>()
    val lastError: LiveData<String?> = _lastError

    init {
        loadStudentInfo()
    }

    /**
     * Student Information Model
     */
    data class StudentInfo(
        val studentId: String,
        val teacherId: String,
        val schoolId: String,
        val firstName: String?,
        val lastName: String?,
        val email: String?,
        val classCode: String?,
        val classDetails: com.skillvergence.mindsherpa.data.api.ClassDetails? = null
    )

    /**
     * Get device ID (from DeviceManager or generate)
     */
    private fun getDeviceId(): String {
        var deviceId = sharedPrefs.getString("device_id", null)
        if (deviceId == null) {
            deviceId = "android-${UUID.randomUUID()}"
            sharedPrefs.edit().putString("device_id", deviceId).apply()
        }
        return deviceId
    }

    /**
     * Register device with backend
     */
    suspend fun registerDevice(): Boolean = withContext(Dispatchers.IO) {
        try {
            _isLoading.postValue(true)
            _lastError.postValue(null)

            val request = DeviceRegistrationRequest(
                deviceId = getDeviceId(),
                platform = "android",
                appVersion = BuildConfig.VERSION_NAME,
                deviceName = "${Build.MANUFACTURER} ${Build.MODEL}"
            )

            val response = apiService.registerDevice(request)
            if (response.isSuccessful && response.body()?.success == true) {
                _isDeviceRegistered.postValue(true)
                println("✅ Device registered successfully")
                true
            } else {
                _lastError.postValue("Failed to register device")
                println("❌ Device registration failed")
                false
            }
        } catch (e: Exception) {
            _lastError.postValue("Network error: ${e.message}")
            println("❌ Device registration error: $e")
            false
        } finally {
            _isLoading.postValue(false)
        }
    }

    /**
     * Join class with class code
     */
    suspend fun joinClass(
        classCode: String,
        firstName: String,
        lastName: String,
        email: String? = null
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            _isLoading.postValue(true)
            _lastError.postValue(null)

            val request = ClassJoinRequest(
                deviceId = getDeviceId(),
                classCode = classCode.uppercase(),
                firstName = firstName,
                lastName = lastName,
                email = email
            )

            val response = apiService.joinClass(request)
            if (response.isSuccessful && response.body()?.success == true) {
                val joinResponse = response.body()!!

                val studentInfo = StudentInfo(
                    studentId = joinResponse.studentId,
                    teacherId = joinResponse.teacherId,
                    schoolId = joinResponse.schoolId,
                    firstName = firstName,
                    lastName = lastName,
                    email = email,
                    classCode = classCode.uppercase(),
                    classDetails = joinResponse.classDetails
                )

                _studentInfo.postValue(studentInfo)
                saveStudentInfo(studentInfo)

                // Update class access in ProgressStore
                com.skillvergence.mindsherpa.data.persistence.ProgressStore.getInstance(context).updateClassAccess()

                println("✅ Successfully joined class: $classCode")
                true
            } else {
                val errorBody = response.errorBody()?.string()
                val errorMessage = if (response.code() == 404) {
                    "This Class does not exist"
                } else {
                    errorBody ?: "Failed to join class"
                }
                _lastError.postValue(errorMessage)
                println("❌ Class join failed: $errorMessage")
                false
            }
        } catch (e: Exception) {
            _lastError.postValue("Network error: ${e.message}")
            println("❌ Class join error: $e")
            false
        } finally {
            _isLoading.postValue(false)
        }
    }

    /**
     * Sync video progress to backend
     */
    suspend fun syncVideoProgress(
        videoId: String,
        courseId: String,
        watchedSeconds: Double,
        totalDuration: Double,
        isCompleted: Boolean,
        lastPosition: Double
    ) = withContext(Dispatchers.IO) {
        // Only sync if we have student info (device is linked to a student)
        if (_studentInfo.value == null) {
            println("📤 Skipping progress sync - no student linked")
            return@withContext
        }

        try {
            val request = VideoProgressRequest(
                videoId = videoId,
                deviceId = getDeviceId(),
                watchedSeconds = watchedSeconds,
                totalDuration = totalDuration,
                isCompleted = isCompleted,
                courseId = courseId,
                lastPosition = lastPosition
            )

            val response = apiService.updateVideoProgress(request)
            if (response.isSuccessful) {
                println("📤 Video progress synced: $videoId")
            } else {
                println("❌ Failed to sync video progress")
            }
        } catch (e: Exception) {
            println("❌ Progress sync error: $e")
        }
    }

    /**
     * Sync podcast progress to backend
     */
    suspend fun syncPodcastProgress(
        podcastId: String,
        courseId: String,
        playbackPosition: Double,
        totalDuration: Double,
        isCompleted: Boolean
    ) = withContext(Dispatchers.IO) {
        // Only sync if we have student info
        if (_studentInfo.value == null) {
            println("📤 Skipping podcast sync - no student linked")
            return@withContext
        }

        try {
            val request = PodcastProgressRequest(
                podcastId = podcastId,
                deviceId = getDeviceId(),
                playbackPosition = playbackPosition,
                totalDuration = totalDuration,
                isCompleted = isCompleted,
                courseId = courseId
            )

            val response = apiService.updatePodcastProgress(request)
            if (response.isSuccessful) {
                println("📤 Podcast progress synced: $podcastId")
            } else {
                println("❌ Failed to sync podcast progress")
            }
        } catch (e: Exception) {
            println("❌ Podcast sync error: $e")
        }
    }

    /**
     * Student Info Persistence
     */
    private fun saveStudentInfo(studentInfo: StudentInfo) {
        val json = gson.toJson(studentInfo)
        sharedPrefs.edit().putString("student_info", json).apply()
    }

    private fun loadStudentInfo() {
        val json = sharedPrefs.getString("student_info", null)
        if (json != null) {
            try {
                val studentInfo = gson.fromJson(json, StudentInfo::class.java)
                _studentInfo.postValue(studentInfo)
            } catch (e: Exception) {
                println("❌ Failed to load student info: $e")
            }
        }
    }

    /**
     * Helper Methods
     */
    fun isStudentLinked(): Boolean {
        return _studentInfo.value != null
    }

    fun getStudentDisplayName(): String {
        val info = _studentInfo.value ?: return ""
        return if (info.firstName != null && info.lastName != null) {
            "${info.firstName} ${info.lastName}"
        } else {
            info.studentId
        }
    }

    fun clearStudentInfo() {
        _studentInfo.postValue(null)
        sharedPrefs.edit().remove("student_info").apply()
    }
}