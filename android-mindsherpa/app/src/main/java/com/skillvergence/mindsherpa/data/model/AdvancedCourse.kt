package com.skillvergence.mindsherpa.data.model

import com.google.gson.annotations.SerializedName

/**
 * Advanced Course model matching iOS structure
 * For premium courses with prerequisites
 */
data class AdvancedCourse(
    val id: String,
    val title: String,
    val description: String,
    @SerializedName("prerequisite_course_id")
    val prerequisiteCourseId: String,
    @SerializedName("mux_playback_id")
    val muxPlaybackId: String,
    @SerializedName("estimated_hours")
    val estimatedHours: Double,
    @SerializedName("certificate_type")
    val certificateType: AdvancedCertificateType,
    @SerializedName("xp_reward")
    val xpReward: Int,
    @SerializedName("skill_level")
    val skillLevel: AdvancedSkillLevel
) {
    // Computed property for unlocked status
    val isUnlocked: Boolean
        get() {
            // This would check if prerequisite course is completed
            // For now, return true - implement with progress tracking later
            return true
        }

    val formattedDuration: String
        get() = "${estimatedHours.format(1)} hours"
}

/**
 * Advanced Certificate Types matching iOS enum
 */
enum class AdvancedCertificateType(val value: String) {
    @SerializedName("ev_fundamentals_advanced")
    EV_FUNDAMENTALS_ADVANCED("ev_fundamentals_advanced"),

    @SerializedName("battery_systems_expert")
    BATTERY_SYSTEMS_EXPERT("battery_systems_expert"),

    @SerializedName("charging_infrastructure_specialist")
    CHARGING_INFRASTRUCTURE_SPECIALIST("charging_infrastructure_specialist"),

    @SerializedName("ev_maintenance_professional")
    EV_MAINTENANCE_PROFESSIONAL("ev_maintenance_professional"),

    @SerializedName("smart_grid_integration")
    SMART_GRID_INTEGRATION("smart_grid_integration");

    val displayName: String
        get() = when (this) {
            EV_FUNDAMENTALS_ADVANCED -> "EV Fundamentals Advanced"
            BATTERY_SYSTEMS_EXPERT -> "Battery Systems Expert"
            CHARGING_INFRASTRUCTURE_SPECIALIST -> "Charging Infrastructure Specialist"
            EV_MAINTENANCE_PROFESSIONAL -> "EV Maintenance Professional"
            SMART_GRID_INTEGRATION -> "Smart Grid Integration"
        }

    val badgeIcon: String
        get() = when (this) {
            EV_FUNDAMENTALS_ADVANCED -> "electric_bolt"
            BATTERY_SYSTEMS_EXPERT -> "battery_charging_full"
            CHARGING_INFRASTRUCTURE_SPECIALIST -> "ev_station"
            EV_MAINTENANCE_PROFESSIONAL -> "build"
            SMART_GRID_INTEGRATION -> "grid_3x3"
        }

    val certificateDescription: String
        get() = when (this) {
            EV_FUNDAMENTALS_ADVANCED -> "Advanced understanding of electric vehicle fundamentals, powertrain systems, and energy management."
            BATTERY_SYSTEMS_EXPERT -> "Expert-level knowledge of battery chemistry, thermal management, and energy storage systems."
            CHARGING_INFRASTRUCTURE_SPECIALIST -> "Specialized expertise in EV charging infrastructure, standards, and deployment strategies."
            EV_MAINTENANCE_PROFESSIONAL -> "Professional-grade skills in electric vehicle maintenance, diagnostics, and repair procedures."
            SMART_GRID_INTEGRATION -> "Advanced knowledge of smart grid technologies and EV integration strategies."
        }
}

/**
 * Advanced Skill Levels matching iOS enum
 */
enum class AdvancedSkillLevel(val value: String) {
    @SerializedName("intermediate")
    INTERMEDIATE("intermediate"),

    @SerializedName("advanced")
    ADVANCED("advanced"),

    @SerializedName("expert")
    EXPERT("expert"),

    @SerializedName("master")
    MASTER("master");

    val displayName: String
        get() = value.replaceFirstChar { it.uppercaseChar() }
}

// Extension function for Double formatting
fun Double.format(digits: Int) = "%.${digits}f".format(this)

/**
 * Sample Advanced Courses (matching iOS structure)
 */
object AdvancedCourseSamples {
    val sampleAdvancedCourses = listOf(
        AdvancedCourse(
            id = "adv_1",
            title = "Advanced High Voltage Vehicle Safety",
            description = "Master-level safety protocols for high-voltage electric vehicle systems including arc flash protection, lockout/tagout procedures, and emergency response protocols.",
            prerequisiteCourseId = "course_1",
            muxPlaybackId = "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedHours = 8.5,
            certificateType = AdvancedCertificateType.EV_FUNDAMENTALS_ADVANCED,
            xpReward = 200,
            skillLevel = AdvancedSkillLevel.ADVANCED
        ),
        AdvancedCourse(
            id = "adv_2",
            title = "Battery Management Systems Deep Dive",
            description = "Advanced study of BMS architecture, cell balancing algorithms, thermal management strategies, and safety system integration.",
            prerequisiteCourseId = "course_2",
            muxPlaybackId = "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedHours = 12.0,
            certificateType = AdvancedCertificateType.BATTERY_SYSTEMS_EXPERT,
            xpReward = 300,
            skillLevel = AdvancedSkillLevel.EXPERT
        ),
        AdvancedCourse(
            id = "adv_3",
            title = "DC Fast Charging Infrastructure Design",
            description = "Comprehensive course on DC fast charging station design, power electronics, grid integration, and load management systems.",
            prerequisiteCourseId = "course_4",
            muxPlaybackId = "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4",
            estimatedHours = 15.5,
            certificateType = AdvancedCertificateType.CHARGING_INFRASTRUCTURE_SPECIALIST,
            xpReward = 400,
            skillLevel = AdvancedSkillLevel.EXPERT
        ),
        AdvancedCourse(
            id = "adv_4",
            title = "Electric Vehicle Diagnostics & Repair",
            description = "Professional-grade training in EV diagnostics, component replacement, and advanced troubleshooting techniques.",
            prerequisiteCourseId = "course_3",
            muxPlaybackId = "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedHours = 20.0,
            certificateType = AdvancedCertificateType.EV_MAINTENANCE_PROFESSIONAL,
            xpReward = 500,
            skillLevel = AdvancedSkillLevel.MASTER
        ),
        AdvancedCourse(
            id = "adv_5",
            title = "Vehicle-to-Grid Integration Systems",
            description = "Master-level exploration of V2G technology, grid stability, energy trading, and smart charging algorithms.",
            prerequisiteCourseId = "course_5",
            muxPlaybackId = "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedHours = 18.0,
            certificateType = AdvancedCertificateType.SMART_GRID_INTEGRATION,
            xpReward = 600,
            skillLevel = AdvancedSkillLevel.MASTER
        )
    )
}