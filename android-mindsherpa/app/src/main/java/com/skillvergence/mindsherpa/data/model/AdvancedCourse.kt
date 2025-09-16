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
        get() {
            val totalMinutes = (estimatedHours * 60).toInt()
            val hours = totalMinutes / 60
            val minutes = totalMinutes % 60
            return if (hours > 0) {
                "${hours}h ${minutes}m"
            } else {
                "${minutes}m"
            }
        }
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
 * Advanced Courses Data (exactly matching iOS implementation)
 */
object AdvancedCourseData {
    val sampleAdvancedCourses = listOf(
        AdvancedCourse(
            id = "adv_1",
            title = "1.0 High Voltage Vehicle Safety",
            description = "Master-level 7-module certification covering advanced EV safety protocols, risk assessment, and professional safety management. Maps to 7 individual advanced modules from basic EV Safety Pyramid course.",
            prerequisiteCourseId = "course_1", // Requires basic Course 1 (1.1-1.7) completion
            muxPlaybackId = "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
            estimatedHours = 1.30, // 7 modules, 1:18:03 (78 mins 3 seconds total)
            certificateType = AdvancedCertificateType.EV_FUNDAMENTALS_ADVANCED,
            xpReward = 700, // 7 modules × 100 XP each
            skillLevel = AdvancedSkillLevel.EXPERT
        ),
        AdvancedCourse(
            id = "adv_2",
            title = "2.0 Electrical Level 1 - Medium Heavy Duty",
            description = "Advanced 4-module certification covering expert-level high voltage safety protocols, hazard mitigation, and professional risk management strategies. Maps to 4 individual advanced modules.",
            prerequisiteCourseId = "course_2", // Requires basic Course 2 (2.1-2.4) completion
            muxPlaybackId = "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
            estimatedHours = 3.89, // 4 modules, 3:53:40 (233 mins 40 seconds total)
            certificateType = AdvancedCertificateType.BATTERY_SYSTEMS_EXPERT,
            xpReward = 480, // 4 modules × 120 XP each
            skillLevel = AdvancedSkillLevel.EXPERT
        ),
        AdvancedCourse(
            id = "adv_3",
            title = "3.0 Electrical Level 2 - Medium Heavy Duty",
            description = "Expert-level 2-module certification covering advanced electrical shock protection systems, professional grounding techniques, and master-class safety implementations. Maps to 2 individual advanced modules.",
            prerequisiteCourseId = "course_3", // Requires basic Course 3 (3.1-3.2) completion
            muxPlaybackId = "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",
            estimatedHours = 2.51, // 2 modules, 2:30:32 (150 mins 32 seconds total)
            certificateType = AdvancedCertificateType.CHARGING_INFRASTRUCTURE_SPECIALIST,
            xpReward = 280, // 2 modules × 140 XP each
            skillLevel = AdvancedSkillLevel.EXPERT
        ),
        AdvancedCourse(
            id = "adv_4",
            title = "4.0 Electric Vehicle Supply Equipment",
            description = "Advanced 2-module certification covering professional-grade PPE selection, expert safety equipment usage, and master-level protection protocols for EV technicians. Maps to 2 individual advanced modules.",
            prerequisiteCourseId = "course_4", // Requires basic Course 4 (4.1-4.2) completion
            muxPlaybackId = "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
            estimatedHours = 1.21, // 2 modules, 1:12:19 (72 mins 19 seconds total)
            certificateType = AdvancedCertificateType.EV_MAINTENANCE_PROFESSIONAL,
            xpReward = 320, // 2 modules × 160 XP each
            skillLevel = AdvancedSkillLevel.MASTER
        ),
        AdvancedCourse(
            id = "adv_5",
            title = "5.0 Introduction to Electric Vehicles",
            description = "Comprehensive 3-module advanced series covering EV fundamentals, energy storage systems, and motor control architecture. Master the complete technical journey from basic EV principles to advanced powertrain design.",
            prerequisiteCourseId = "course_5", // Requires basic Course 5 (5.1-5.3) completion
            muxPlaybackId = "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedHours = 2.54, // 3 modules, 2:32:42 (152 mins 42 seconds total)
            certificateType = AdvancedCertificateType.EV_FUNDAMENTALS_ADVANCED,
            xpReward = 450, // 3 modules × 150 XP each
            skillLevel = AdvancedSkillLevel.MASTER
        )
    )
}

/**
 * Course 1.0 Modules (7 individual modules for High Voltage Vehicle Safety)
 */
object Course1ModuleData {
    val course1Modules = listOf(
        Course1Module(
            id = "1-1",
            title = "1.1 High Voltage Workplace Personnel",
            description = "Overview of high voltage safety in electric vehicles covering different roles and qualifications including electrically aware persons, qualified persons, and authorized persons. Understanding training requirements and authorization for high voltage work.",
            muxPlaybackId = "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns", // Individual module ID from iOS
            estimatedMinutes = 8, // Real duration: 07:27 (7 minutes 27 seconds, rounded up)
            xpReward = 100
        ),
        Course1Module(
            id = "1-2",
            title = "1.2 High Voltage Hazards",
            description = "Comprehensive exploration of dangers associated with high voltage systems including electric shock, arc flash, and arc blast hazards. Understanding factors affecting shock severity, body resistance, and current effects.",
            muxPlaybackId = "XOvqV82WjeJnJiu4josaw9JL2k4Rq1hdV3SQA4Sg678", // Individual module ID from iOS
            estimatedMinutes = 11,
            xpReward = 100
        ),
        Course1Module(
            id = "1-3",
            title = "1.3 Shock Protection Boundaries",
            description = "Critical concept of shock protection boundaries in high voltage environments covering limited approach, restricted approach, and arc flash boundaries. Learning to identify and respect safety zones.",
            muxPlaybackId = "bI2WjGdUUWzHJ7w00Gv3aRf7OHz1vn46RDGdgp5YvVcU", // Individual module ID from iOS
            estimatedMinutes = 11,
            xpReward = 100
        ),
        Course1Module(
            id = "1-4",
            title = "1.4 PPE Ratings and Categories",
            description = "Personal protective equipment for high voltage work covering PPE capabilities, ratings, and categories with emphasis on arc ratings and hazard risk categories. Learning to select appropriate PPE for various tasks.",
            muxPlaybackId = "8mRfAgwaHusffNx5gObTyztZz9vtOIUY9umBArsTaic", // Individual module ID from iOS
            estimatedMinutes = 11,
            xpReward = 100
        ),
        Course1Module(
            id = "1-5",
            title = "1.5 High Voltage Components",
            description = "In-depth look at key components of high voltage systems in electric vehicles including energy storage systems, battery management, traction motors, power distribution, inverters, and converters.",
            muxPlaybackId = "NCCNveUpYpRKBkTDINDNksgsooofohQr7q9McFS7DpY", // Individual module ID from iOS
            estimatedMinutes = 12,
            xpReward = 100
        ),
        Course1Module(
            id = "1-6",
            title = "1.6 High-Voltage Safety Procedures",
            description = "Detailed instruction on safety procedures for working with high voltage systems covering precautionary measures, battery disabling techniques, manual service disconnects, and high voltage interlock loops.",
            muxPlaybackId = "AxKaucprgU200mmFTGLNIRlpSkaA02FMZwFmmZ1rmaUrE", // Individual module ID from iOS
            estimatedMinutes = 11,
            xpReward = 100
        ),
        Course1Module(
            id = "1-7",
            title = "1.7 Warning Labels",
            description = "Visual identification of high voltage components in electric vehicles covering badges, wraps, orange cables, and high voltage warning labels. Learning to recognize and interpret various warning signs and markings.",
            muxPlaybackId = "fYYHPmsdI1iYZYBZfOhuUkQgD8RDsfm2tHSScOUIYAw", // Individual module ID from iOS
            estimatedMinutes = 10,
            xpReward = 100
        )
    )
}

/**
 * Course 2.0 Modules (4 individual modules for Electrical Level 1 • 3:53:40)
 */
object Course2ModuleData {
    val course2Modules = listOf(
        Course2Module(
            id = "2-1",
            title = "2.1 Basic Circuit Components & Configuration",
            description = "Understanding electrical components, series and parallel circuits, and calculating voltage, current, resistance, and power. Practical lab exercises reinforce theoretical knowledge for building and testing circuits.",
            muxPlaybackId = "KGnXNWj2cE7FE8usEaoA2ROnqGQAMqZq021Xykgski2k",
            estimatedMinutes = null,
            xpReward = 120
        ),
        Course2Module(
            id = "2-2",
            title = "2.2 Electrical Measurements",
            description = "Comprehensive training on using digital multimeters for automotive electrical measurements, covering voltage, current, resistance, continuity, capacitance, and frequency measurements with safety procedures.",
            muxPlaybackId = "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
            estimatedMinutes = null,
            xpReward = 120
        ),
        Course2Module(
            id = "2-3",
            title = "2.3 Electrical Fault Analysis",
            description = "Comprehensive training in diagnosing and troubleshooting electrical issues including high resistance faults, open circuits, shorts to ground, and component faults using digital multimeters.",
            muxPlaybackId = "f7bWarA02aIjBloGalrhHuSXRGGEEtpwvJ3nLnjAtxV4",
            estimatedMinutes = null,
            xpReward = 120
        ),
        Course2Module(
            id = "2-4",
            title = "2.4 Circuit Diagnosis",
            description = "Essential skills for troubleshooting electrical systems, reading wiring diagrams, tracing current flow, and systematic diagnostic approaches using digital multimeters and voltage drop tests.",
            muxPlaybackId = "k7feJpMDdL6CJc1GeCS2MHRR9B1h2Yotr02Kypy2bupg",
            estimatedMinutes = null,
            xpReward = 120
        )
    )
}

/**
 * Course 3.0 Modules (2 individual modules for Electrical Level 2 • 2:30:32)
 */
object Course3ModuleData {
    val course3Modules = listOf(
        Course3Module(
            id = "3-1",
            title = "3.1 Advanced Electrical Systems Diagnosis",
            description = "Advanced digital multimeter functions and oscilloscope operation for precise voltage, current, and waveform analysis. In-depth study of computer input/output circuits, sensors, and actuators in modern vehicles with hands-on diagnostic techniques.",
            muxPlaybackId = "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",
            estimatedMinutes = null,
            xpReward = 140
        ),
        Course3Module(
            id = "3-2",
            title = "3.2 Automotive Communication Systems",
            description = "Comprehensive overview of automotive bus communication systems including K-CAN, PT-CAN, LIN, FlexRay, MOST, and Ethernet. Understanding gateway modules, fiber optics, LVDS, real-time vehicle scanning, and diagnostic strategies for complex network architectures.",
            muxPlaybackId = "WMQlHCyi1zrF018XtLXycNXHqTMnvVxV70001tMSXOS02J4",
            estimatedMinutes = null,
            xpReward = 140
        )
    )
}

/**
 * Course 4.0 Modules (2 individual modules for EV Supply Equipment • 1:12:19)
 */
object Course4ModuleData {
    val course4Modules = listOf(
        Course4Module(
            id = "4-1",
            title = "4.1 Electric Vehicle Supply Equipment & Electric Vehicle Charging Systems",
            description = "Comprehensive exploration of EV charging infrastructure including EVSE types, charging levels (Level 1, 2, DC Fast), charging standards and connectors (J1772, CCS, CHAdeMO), AC/DC charging principles, safety features, and communication protocols between EVs and charging stations.",
            muxPlaybackId = "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
            estimatedMinutes = null,
            xpReward = 160
        ),
        Course4Module(
            id = "4-2",
            title = "4.2 Battery Management Systems",
            description = "In-depth study of EV battery systems fundamentals, battery charging/discharging characteristics, Battery Management System (BMS) functions and components, battery health monitoring, thermal management, and safety considerations in battery charging and management with hands-on diagnostic techniques.",
            muxPlaybackId = "zfSZVFnzqFm02QkqkNw301mhZtC700qvgd5IH6srTBmtJo",
            estimatedMinutes = null,
            xpReward = 160
        )
    )
}

/**
 * Course 5 Modules (special case with individual modules)
 */
object Course5ModuleData {
    val course5Modules = listOf(
        Course5Module(
            id = "5-1",
            title = "5.1 Introduction to Electric Vehicles",
            description = "Overview of EV history and evolution, comparison between conventional, hybrid, and fully electric vehicles, key components of EV powertrains, EV charging infrastructure and standards, and environmental impact and advantages of EVs.",
            muxPlaybackId = "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedMinutes = 90,
            xpReward = 150
        ),
        Course5Module(
            id = "5-2",
            title = "5.2 Electric Vehicle Energy Storage Systems",
            description = "Basics of battery technology and cell chemistry, types of batteries used in EVs (lithium-ion, LFP, NMC), battery management systems and thermal management, energy capacity, power density, efficiency concepts, charging and discharging characteristics, and future trends in EV battery technology.",
            muxPlaybackId = "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedMinutes = 90,
            xpReward = 150
        ),
        Course5Module(
            id = "5-3",
            title = "5.3 Electric Vehicle Architecture, Motors & Controllers",
            description = "EV powertrain architectures (in-wheel, centralized), types of electric motors used in EVs (permanent magnet, induction), motor control systems and power electronics, regenerative braking systems, and efficiency and performance characteristics of EV drivetrains.",
            muxPlaybackId = "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4",
            estimatedMinutes = 90,
            xpReward = 150
        )
    )
}

/**
 * Course 1.0 Module data model
 */
data class Course1Module(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int,
    val xpReward: Int
) {
    val formattedDuration: String
        get() = "$estimatedMinutes min"
}

/**
 * Course 2.0 Module data model
 */
data class Course2Module(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int?,
    val xpReward: Int
) {
    val formattedDuration: String
        get() = if (estimatedMinutes != null) "$estimatedMinutes min" else "..."
}

/**
 * Course 3.0 Module data model
 */
data class Course3Module(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int?,
    val xpReward: Int
) {
    val formattedDuration: String
        get() = if (estimatedMinutes != null) "$estimatedMinutes min" else "..."
}

/**
 * Course 4.0 Module data model
 */
data class Course4Module(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int?,
    val xpReward: Int
) {
    val formattedDuration: String
        get() = if (estimatedMinutes != null) "$estimatedMinutes min" else "..."
}

/**
 * Course 5 Module data model
 */
data class Course5Module(
    val id: String,
    val title: String,
    val description: String,
    val muxPlaybackId: String,
    val estimatedMinutes: Int,
    val xpReward: Int
) {
    val formattedDuration: String
        get() = "$estimatedMinutes min"
}