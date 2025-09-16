//
//  AdvancedCourse.swift
//  mindsherpa
//
//  Created by Claude on 9/4/25.
//

import Foundation

// MARK: - Advanced Course Models

struct AdvancedCourse: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let prerequisiteCourseId: String // Basic course that must be completed
    let muxPlaybackId: String // Mux video playback ID
    let estimatedHours: Double
    let certificateType: AdvancedCertificateType
    let xpReward: Int
    let skillLevel: AdvancedSkillLevel

    @MainActor var isUnlocked: Bool {
        // Check if prerequisite course is completed
        return ProgressStore.shared.isCourseCompleted(courseId: prerequisiteCourseId)
    }

    var formattedDuration: String {
        let totalMinutes = Int(estimatedHours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return if hours > 0 {
            "\(hours)h \(minutes)m"
        } else {
            "\(minutes)m"
        }
    }
}

enum AdvancedCertificateType: String, CaseIterable, Codable {
    case evFundamentalsAdvanced = "advanced_ev_fundamentals"
    case batterySystemsExpert = "battery_systems_expert"
    case chargingInfrastructureSpecialist = "charging_infrastructure_specialist"
    case motorControlAdvanced = "motor_control_advanced"
    case diagnosticsExpert = "diagnostics_expert"
    
    var displayName: String {
        switch self {
        case .evFundamentalsAdvanced:
            return "Advanced EV Fundamentals Specialist"
        case .batterySystemsExpert:
            return "Battery Systems Expert"
        case .chargingInfrastructureSpecialist:
            return "Charging Infrastructure Specialist"
        case .motorControlAdvanced:
            return "Advanced Motor Control Technician"
        case .diagnosticsExpert:
            return "EV Diagnostics Expert"
        }
    }
    
    var badgeIcon: String {
        switch self {
        case .evFundamentalsAdvanced:
            return "car.fill"
        case .batterySystemsExpert:
            return "battery.100"
        case .chargingInfrastructureSpecialist:
            return "bolt.car.fill"
        case .motorControlAdvanced:
            return "gearshape.2.fill"
        case .diagnosticsExpert:
            return "stethoscope"
        }
    }
}

enum AdvancedSkillLevel: String, CaseIterable, Codable {
    case expert = "expert"
    case master = "master"
    
    var displayName: String {
        switch self {
        case .expert:
            return "Expert Level"
        case .master:
            return "Master Level"
        }
    }
    
    var xpMultiplier: Double {
        switch self {
        case .expert:
            return 2.0
        case .master:
            return 3.0
        }
    }
}

// MARK: - Advanced Course Progress

struct AdvancedCourseProgress: Codable {
    let courseId: String
    let watchedSeconds: Double
    let totalDuration: Double
    let completed: Bool
    let certificateEarned: Bool
    let completedAt: Date?
    let certificateIssuedAt: Date?
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return min(watchedSeconds / totalDuration * 100, 100)
    }
}

// MARK: - Course Overview

struct CourseOverview {
    static let course5Advanced = """
    This comprehensive introductory course provides a solid foundation in electric vehicle (EV) technology, covering the fundamental principles, components, and systems that make EVs function.

    **Course Structure:**

    **Module 1: Introduction to Electric Vehicles**
    • Overview of EV history and evolution
    • Comparison between conventional, hybrid, and fully electric vehicles  
    • Key components of EV powertrains
    • EV charging infrastructure and standards
    • Environmental impact and advantages of EVs

    **Module 2: Electric Vehicle Energy Storage Systems**
    • Basics of battery technology and cell chemistry
    • Types of batteries used in EVs (lithium-ion, LFP, NMC)
    • Battery management systems and thermal management
    • Energy capacity, power density, and efficiency concepts
    • Charging and discharging characteristics
    • Future trends in EV battery technology

    **Module 3: EV Architecture, Motors & Controllers**
    • EV powertrain architectures (in-wheel, centralized)
    • Types of electric motors used in EVs (permanent magnet, induction)
    • Motor control systems and power electronics
    • Regenerative braking systems
    • Efficiency and performance characteristics of EV drivetrains

    Throughout the course, you'll gain comprehensive understanding of how electric vehicles work, their key components, and the principles behind their operation. Perfect preparation for advanced automotive technology careers.
    """
}

// MARK: - Sample Advanced Courses Data

extension AdvancedCourse {
    static let sampleAdvancedCourses: [AdvancedCourse] = [
        AdvancedCourse(
            id: "adv_1",
            title: "1.0 High Voltage Vehicle Safety",
            description: "Master-level 7-module certification covering advanced EV safety protocols, risk assessment, and professional safety management. Maps to 7 individual advanced modules from basic EV Safety Pyramid course.",
            prerequisiteCourseId: "course_1", // Requires basic Course 1 (1.1-1.7) completion - maps to 7 advanced modules
            muxPlaybackId: "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
            estimatedHours: 1.30, // 7 modules, 1:18:03 (78 mins 3 seconds total)
            certificateType: .evFundamentalsAdvanced,
            xpReward: 700, // 7 modules × 100 XP each
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_2", 
            title: "2.0 Electrical Level 1 - Medium Heavy Duty",
            description: "Advanced 4-module certification covering expert-level high voltage safety protocols, hazard mitigation, and professional risk management strategies. Maps to 4 individual advanced modules.",
            prerequisiteCourseId: "course_2", // Requires basic Course 2 (2.1-2.4) completion - maps to 4 advanced modules
            muxPlaybackId: "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
            estimatedHours: 3.89, // 4 modules, 3:53:40 (233 mins 40 seconds total)
            certificateType: .batterySystemsExpert,
            xpReward: 480, // 4 modules × 120 XP each
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_3",
            title: "3.0 Electrical Level 2 - Medium Heavy Duty",
            description: "Expert-level 2-module certification covering advanced electrical shock protection systems, professional grounding techniques, and master-class safety implementations. Maps to 2 individual advanced modules.",
            prerequisiteCourseId: "course_3", // Requires basic Course 3 (3.1-3.2) completion - maps to 2 advanced modules
            muxPlaybackId: "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is", 
            estimatedHours: 2.51, // 2 modules, 2:30:32 (150 mins 32 seconds total)
            certificateType: .chargingInfrastructureSpecialist,
            xpReward: 280, // 2 modules × 140 XP each
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_4",
            title: "4.0 Electric Vehicle Supply Equipment",
            description: "Advanced 2-module certification covering professional-grade PPE selection, expert safety equipment usage, and master-level protection protocols for EV technicians. Maps to 2 individual advanced modules.",
            prerequisiteCourseId: "course_4", // Requires basic Course 4 (4.1-4.2) completion - maps to 2 advanced modules
            muxPlaybackId: "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
            estimatedHours: 1.21, // 2 modules, 1:12:19 (72 mins 19 seconds total)
            certificateType: .motorControlAdvanced,
            xpReward: 320, // 2 modules × 160 XP each
            skillLevel: .master
        ),
        AdvancedCourse(
            id: "adv_5",
            title: "5.0 Introduction to Electric Vehicles", 
            description: "Comprehensive 3-module advanced series covering EV fundamentals, energy storage systems, and motor control architecture. Master the complete technical journey from basic EV principles to advanced powertrain design.",
            prerequisiteCourseId: "course_5", // Requires basic Course 5 (5.1-5.3) completion - maps to 3 advanced modules
            muxPlaybackId: "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedHours: 2.54, // 3 modules, 2:32:42 (152 mins 42 seconds total)
            certificateType: .evFundamentalsAdvanced,
            xpReward: 450, // 3 modules × 150 XP each
            skillLevel: .master
        )
    ]
}