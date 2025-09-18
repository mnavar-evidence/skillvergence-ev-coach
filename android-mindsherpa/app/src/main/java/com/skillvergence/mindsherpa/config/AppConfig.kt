package com.skillvergence.mindsherpa.config

/**
 * App Configuration matching iOS Config.swift
 * Handles Railway backend integration and environment switching
 */
object AppConfig {

    // MARK: - API Configuration

    // Primary: Custom domain with SSL certificate
    const val BASE_URL = "https://api.mindsherpa.ai"  // Custom domain URL

    // Development: Local backend
    const val DEV_BASE_URL = "http://192.168.86.46:3000"  // Local development server

    // Fallback: Direct Railway URLs (update when needed)
    const val FALLBACK_BASE_URL = "https://backend-production-f873.up.railway.app"
    const val CONFIGURATION_URL = "https://skillvergence.mindsherpa.ai/config.json"  // Dynamic config

    const val IS_PRODUCTION = true

    // Dynamic configuration support
    private var _dynamicBaseURL: String? = null

    val currentBaseURL: String
        get() = _dynamicBaseURL ?: if (IS_PRODUCTION) BASE_URL else DEV_BASE_URL

    val apiURL: String
        get() = "$currentBaseURL/api/"

    // MARK: - API Endpoints (Updated to use dynamic configuration)

    val coursesEndpoint: String
        get() = "$apiURL/courses"

    val aiEndpoint: String
        get() = "$apiURL/ai/ask"

    val analyticsEndpoint: String
        get() = "$apiURL/analytics/events"

    val progressEndpoint: String
        get() = "$apiURL/progress"

    val podcastsEndpoint: String
        get() = "$apiURL/podcasts"

    val videoProgressEndpoint: String
        get() = "$apiURL/video/progress"

    // MARK: - Network Configuration

    const val ENABLE_NETWORK_LOGGING = true
    const val REQUEST_TIMEOUT = 30L // seconds
    const val CONNECT_TIMEOUT = 15L // seconds
    const val READ_TIMEOUT = 30L // seconds

    // MARK: - App Information

    const val APP_NAME = "MindSherpa"
    const val USER_AGENT = "MindSherpa-Android/1.0"

    // MARK: - Dynamic Configuration Loading

    suspend fun loadDynamicConfiguration() {
        try {
            // TODO: Implement dynamic config loading
            // Similar to iOS version - fetch config.json and update _dynamicBaseURL
            println("✅ Using static config: $BASE_URL")
        } catch (e: Exception) {
            println("⚠️ Could not load dynamic config, using default: ${e.message}")
        }
    }

    // MARK: - Debug Information

    fun printConfiguration() {
        println("📱 MindSherpa Android Configuration")
        println("   Environment: ${if (IS_PRODUCTION) "Production" else "Development"}")
        println("   Current Base URL: $currentBaseURL")
        println("   API URL: $apiURL")
        println("   Courses URL: $coursesEndpoint")
        println("   Network Logging: $ENABLE_NETWORK_LOGGING")

        if (IS_PRODUCTION) {
            println("   🌐 Using Railway production backend")
            println("   📡 Testing network connectivity...")
        } else {
            println("   ⚠️  Development mode - using local backend: $DEV_BASE_URL")
            println("   📶 Ensure your device is on the same WiFi network")
        }
    }

    // Initialize configuration and print debug info
    fun init() {
        printConfiguration()
        println("🔧 Android API Debug:")
        println("   Full courses URL: $coursesEndpoint")
        if (IS_PRODUCTION) {
            println("   Expected: https://api.mindsherpa.ai/api/courses")
        } else {
            println("   Expected: http://192.168.86.46:3000/api/courses")
        }
    }
}

/**
 * Dynamic Configuration Model
 * Matches iOS DynamicConfig structure
 */
data class DynamicConfig(
    val apiBaseURL: String,
    val cdnBaseURL: String? = null,
    val version: String? = null,
    val features: Map<String, Boolean>? = null
)