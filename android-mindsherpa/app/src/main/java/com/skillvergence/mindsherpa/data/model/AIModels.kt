package com.skillvergence.mindsherpa.data.model

/**
 * AI Request model for sending questions to Coach Nova
 * Matches iOS AIRequest structure
 */
data class AIRequest(
    val question: String,
    val context: String? = null
)

/**
 * Enhanced AI Response model
 * Matches iOS AIResponse structure with additional fields
 */
data class AIResponse(
    val response: String,
    val context: String? = null,
    val timestamp: String? = null,
    val confidence: Double? = null,
    val sources: List<String>? = null
) {
    // Computed property to match iOS interface
    val answer: String
        get() = response
}

/**
 * AI Error types for error handling
 * Matches iOS AIError enum
 */
sealed class AIError : Exception() {
    object InvalidURL : AIError() {
        override val message: String = "Invalid URL provided"
    }

    object NoResponse : AIError() {
        override val message: String = "No response received from AI service"
    }

    data class ServerError(override val message: String) : AIError()

    object NetworkError : AIError() {
        override val message: String = "Network connection error"
    }

    object UnknownError : AIError() {
        override val message: String = "An unknown error occurred"
    }
}