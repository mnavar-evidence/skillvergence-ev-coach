package com.skillvergence.mindsherpa.data.model

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.skillvergence.mindsherpa.data.api.ApiService
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import retrofit2.Response

/**
 * Access Control Manager for Android
 * Handles teacher authentication, user tiers, and code validation
 * Equivalent to iOS AccessControlManager.swift
 */
class AccessControlManager private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: AccessControlManager? = null

        fun getInstance(context: Context): AccessControlManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AccessControlManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private val preferences: SharedPreferences = context.getSharedPreferences("access_control", Context.MODE_PRIVATE)
    private val progressStore = ProgressStore.getInstance(context)

    // Live Data for UI observation
    private val _isTeacherModeEnabled = MutableLiveData(false)
    val isTeacherModeEnabled: LiveData<Boolean> = _isTeacherModeEnabled

    private val _currentUserTier = MutableLiveData(UserTier.FREE)
    val currentUserTier: LiveData<UserTier> = _currentUserTier

    private val _showTeacherCodeEntry = MutableLiveData(false)
    val showTeacherCodeEntry: LiveData<Boolean> = _showTeacherCodeEntry

    private val _earnedFriendCodes = MutableLiveData<List<String>>(emptyList())
    val earnedFriendCodes: LiveData<List<String>> = _earnedFriendCodes

    private val _usedCodes = MutableLiveData<Set<String>>(emptySet())
    val usedCodes: LiveData<Set<String>> = _usedCodes

    private val _teacherData = MutableLiveData<TeacherData?>(null)
    val teacherData: LiveData<TeacherData?> = _teacherData

    private var schoolConfig: SchoolConfiguration? = null

    init {
        loadAccessData()
    }

    // MARK: - Teacher Mode Access

    fun attemptTeacherModeAccess() {
        _showTeacherCodeEntry.value = true
    }

    suspend fun validateTeacherCode(code: String): Boolean {
        val normalizedCode = code.uppercase().trim()

        try {
            // Try backend API first
            // Backend determines school from teacher code - no schoolId needed
            val response = ApiService.validateTeacherCode(normalizedCode, "")
            if (response.isSuccessful && response.body()?.success == true) {
                // Store teacher data from API response
                response.body()?.teacher?.let { teacher ->
                    _teacherData.value = TeacherData(
                        id = teacher.id,
                        name = teacher.name,
                        email = teacher.email,
                        school = teacher.school,
                        schoolId = teacher.schoolId,
                        department = teacher.department,
                        program = teacher.program,
                        classCode = teacher.classCode
                    )
                }

                _isTeacherModeEnabled.value = true
                _showTeacherCodeEntry.value = false
                println("🎓 Teacher mode activated with backend code: $normalizedCode")
                return true
            }
        } catch (e: Exception) {
            println("❌ Teacher code validation error: ${e.message}")
        }

        // Fallback to hardcoded validation if API fails or returns false
        return if (normalizedCode == "T12345") {
            _isTeacherModeEnabled.value = true
            _showTeacherCodeEntry.value = false
            println("🎓 Teacher mode activated with fallback code: $normalizedCode")
            true
        } else {
            println("❌ Invalid teacher code: $normalizedCode")
            false
        }
    }

    fun exitTeacherMode() {
        _isTeacherModeEnabled.value = false
        println("🎓 Teacher mode deactivated")
    }

    // MARK: - Code Validation

    suspend fun validateAndRedeemCode(code: String): CodeRedemptionResult {
        val normalizedCode = code.uppercase().trim()

        // Check if code was already used
        val currentUsedCodes = _usedCodes.value ?: emptySet()
        if (currentUsedCodes.contains(normalizedCode)) {
            return CodeRedemptionResult.ALREADY_USED
        }

        // Validate code format and type
        val codeType = CodeType.fromString(normalizedCode)
            ?: return CodeRedemptionResult.INVALID

        // Validate code exists in our system
        if (!isValidCode(normalizedCode, codeType)) {
            return CodeRedemptionResult.INVALID
        }

        // Apply the code benefits
        return when (codeType) {
            CodeType.CLASS_ACCESS -> {
                // Class Access codes give basic access to continue beyond 50 XP
                _currentUserTier.value = UserTier.BASIC_PAID
                addUsedCode(normalizedCode)
                saveAccessData()
                CodeRedemptionResult.SUCCESS_BASIC
            }
            CodeType.PREMIUM -> {
                _currentUserTier.value = UserTier.PREMIUM
                addUsedCode(normalizedCode)
                saveAccessData()
                CodeRedemptionResult.SUCCESS_PREMIUM
            }
            CodeType.FRIEND -> {
                // Friend codes give basic access (Class Access equivalent)
                _currentUserTier.value = UserTier.BASIC_PAID
                addUsedCode(normalizedCode)
                saveAccessData()
                CodeRedemptionResult.SUCCESS_FRIEND
            }
            CodeType.INDIVIDUAL -> {
                // Individual purchase codes give basic access (Class Access equivalent)
                _currentUserTier.value = UserTier.BASIC_PAID
                addUsedCode(normalizedCode)
                saveAccessData()
                CodeRedemptionResult.SUCCESS_INDIVIDUAL
            }
        }
    }

    private fun isValidCode(code: String, type: CodeType): Boolean {
        // In real app, this would validate against backend
        return code.length == 6 &&
                code.startsWith(type.prefix) &&
                code.drop(1).all { it.isDigit() }
    }

    // MARK: - XP Threshold Check

    fun shouldShowPaywall(): Boolean {
        val currentXP = progressStore.getTotalXP()
        val threshold = schoolConfig?.xpThreshold ?: 50 // Default threshold
        return currentXP >= threshold &&
                !hasAnyBasicAccess()
    }

    fun hasBasicAccess(): Boolean {
        return _currentUserTier.value != UserTier.FREE
    }

    fun hasAnyBasicAccess(): Boolean {
        return progressStore.hasClassAccess() || _currentUserTier.value != UserTier.FREE
    }

    fun hasPremiumAccess(): Boolean {
        return _currentUserTier.value == UserTier.PREMIUM
    }

    // MARK: - Friend Code Generation

    fun checkAndGenerateFriendCodes() {
        CoroutineScope(Dispatchers.IO).launch {
            val currentLevel = progressStore.getCurrentLevel()
            val newCodesCount = friendCodesForLevel(currentLevel)
            val currentCodes = _earnedFriendCodes.value ?: emptyList()

            if (newCodesCount > currentCodes.size) {
                val additionalCodes = newCodesCount - currentCodes.size
                val newCodes = (0 until additionalCodes).map { generateFriendCode() }
                val updatedCodes = currentCodes + newCodes

                withContext(Dispatchers.Main) {
                    _earnedFriendCodes.value = updatedCodes
                }

                saveAccessData()
                println("🎉 Generated $additionalCodes new friend codes for reaching level $currentLevel")
            }
        }
    }

    private fun friendCodesForLevel(level: Int): Int {
        return when (level) {
            1 -> 1  // Bronze
            2 -> 2  // Silver
            3 -> 4  // Gold
            4 -> 8  // Platinum
            in 5..Int.MAX_VALUE -> 16  // Diamond+
            else -> 0
        }
    }

    private fun generateFriendCode(): String {
        val number = (10000..99999).random()
        return "F$number"
    }

    // MARK: - Data Persistence

    private fun addUsedCode(code: String) {
        val currentCodes = _usedCodes.value?.toMutableSet() ?: mutableSetOf()
        currentCodes.add(code)
        _usedCodes.value = currentCodes
    }

    private fun saveAccessData() {
        preferences.edit().apply {
            putString("user_tier", _currentUserTier.value?.name)
            putStringSet("used_codes", _usedCodes.value)
            putStringSet("earned_friend_codes", _earnedFriendCodes.value?.toSet())
            apply()
        }
    }

    private fun loadAccessData() {
        val tierString = preferences.getString("user_tier", UserTier.FREE.name)
        _currentUserTier.value = UserTier.valueOf(tierString ?: UserTier.FREE.name)

        val usedCodesSet = preferences.getStringSet("used_codes", emptySet()) ?: emptySet()
        _usedCodes.value = usedCodesSet

        val friendCodesSet = preferences.getStringSet("earned_friend_codes", emptySet()) ?: emptySet()
        _earnedFriendCodes.value = friendCodesSet.toList()
    }
}

// MARK: - Data Models

enum class UserTier {
    FREE,
    BASIC_PAID,
    PREMIUM;

    val displayName: String
        get() = when (this) {
            FREE -> "Free"
            BASIC_PAID -> "Basic"
            PREMIUM -> "Premium"
        }
}

enum class CodeType(val prefix: String) {
    CLASS_ACCESS("C"),  // Changed from BASIC to CLASS_ACCESS to match iOS
    PREMIUM("P"),
    FRIEND("F"),
    INDIVIDUAL("I");   // Individual purchaser codes

    val displayName: String
        get() = when (this) {
            CLASS_ACCESS -> "Class Access"
            PREMIUM -> "Premium Access"
            FRIEND -> "Friend Referral"
            INDIVIDUAL -> "Individual Purchase"
        }

    companion object {
        fun fromString(code: String): CodeType? {
            if (code.isEmpty()) return null
            val firstChar = code.first().toString()
            return values().find { it.prefix == firstChar }
        }
    }
}

enum class CodeRedemptionResult {
    SUCCESS_BASIC,
    SUCCESS_PREMIUM,
    SUCCESS_FRIEND,
    SUCCESS_INDIVIDUAL,
    INVALID,
    ALREADY_USED;

    val message: String
        get() = when (this) {
            SUCCESS_BASIC -> "🎉 Basic access unlocked! You now have full access to all courses."
            SUCCESS_PREMIUM -> "🌟 Premium access unlocked! You now have access to premium content and certifications."
            SUCCESS_FRIEND -> "👥 Friend code redeemed! You now have basic access thanks to your friend."
            SUCCESS_INDIVIDUAL -> "💳 Individual access unlocked! You now have full access to all basic courses."
            INVALID -> "❌ Invalid code. Please check the code and try again."
            ALREADY_USED -> "⚠️ This code has already been used."
        }

    val isSuccess: Boolean
        get() = when (this) {
            SUCCESS_BASIC, SUCCESS_PREMIUM, SUCCESS_FRIEND, SUCCESS_INDIVIDUAL -> true
            INVALID, ALREADY_USED -> false
        }
}

data class SchoolConfiguration(
    val schoolName: String,
    val program: String,
    val instructor: String,
    val email: String,
    val xpThreshold: Int,
    val bulkLicenseCount: Int
) {
    // School configurations will be loaded from database via API
}

// MARK: - Teacher Code Management

data class CodeUsageAnalytics(
    val basicCodesUsed: Int,
    val premiumCodesUsed: Int
)

data class TeacherData(
    val id: String,
    val name: String,
    val email: String,
    val school: String,
    val schoolId: String,
    val department: String,
    val program: String,
    val classCode: String
)