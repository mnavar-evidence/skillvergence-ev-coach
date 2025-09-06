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
            title: "Advanced EV Fundamentals Deep Dive",
            description: "Master-level understanding of electric vehicle principles, advanced motor theory, and cutting-edge EV technology.",
            prerequisiteCourseId: "course_1", // Requires basic Course 1 (1.1-1.7) completion
            muxPlaybackId: "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
            estimatedHours: 3.5,
            certificateType: .evFundamentalsAdvanced,
            xpReward: 200,
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_2", 
            title: "Battery Systems Expert Certification",
            description: "Deep technical dive into battery chemistry, thermal management, and advanced BMS diagnostics.",
            prerequisiteCourseId: "course_2", // Requires basic Course 2 (2.1-2.4) completion
            muxPlaybackId: "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
            estimatedHours: 4.0,
            certificateType: .batterySystemsExpert,
            xpReward: 250,
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_3",
            title: "Charging Infrastructure Specialist",
            description: "Master DC fast charging, grid integration, and advanced charging system troubleshooting.",
            prerequisiteCourseId: "course_3", // Requires basic Course 3 (3.1-3.2) completion
            muxPlaybackId: "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is", 
            estimatedHours: 3.0,
            certificateType: .chargingInfrastructureSpecialist,
            xpReward: 200,
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_4",
            title: "Advanced Motor Control Systems",
            description: "Expert-level motor control algorithms, inverter design, and performance optimization techniques.",
            prerequisiteCourseId: "course_4", // Requires basic Course 4 (4.1-4.2) completion
            muxPlaybackId: "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
            estimatedHours: 3.5,
            certificateType: .motorControlAdvanced,
            xpReward: 225,
            skillLevel: .master
        ),
        AdvancedCourse(
            id: "adv_5_1",
            title: "Introduction to Electric Vehicles - Advanced Deep Dive", 
            description: "Comprehensive exploration of EV history, powertrain fundamentals, charging infrastructure standards, and environmental impact analysis. Master the evolution from conventional to electric vehicles and understand key EV components at an expert level.",
            prerequisiteCourseId: "course_5", // Requires basic Course 5 (5.1-5.3) completion
            muxPlaybackId: "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedHours: 1.5,
            certificateType: .evFundamentalsAdvanced,
            xpReward: 150,
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_5_2",
            title: "Electric Vehicle Energy Storage Systems - Expert Level",
            description: "Advanced study of battery chemistry, cell technology, and thermal management systems. Deep dive into lithium-ion, LFP, and NMC technologies, BMS architecture, energy density concepts, and future battery innovations.",
            prerequisiteCourseId: "course_5", // Requires basic Course 5 (5.1-5.3) completion
            muxPlaybackId: "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedHours: 1.5,
            certificateType: .batterySystemsExpert,
            xpReward: 150,
            skillLevel: .expert
        ),
        AdvancedCourse(
            id: "adv_5_3",
            title: "EV Architecture, Motors & Controllers - Master Class",
            description: "Master-level analysis of EV powertrain architectures, motor control systems, and regenerative braking. Explore permanent magnet vs induction motors, power electronics, efficiency optimization, and performance characteristics of advanced drivetrains.",
            prerequisiteCourseId: "course_5", // Requires basic Course 5 (5.1-5.3) completion
            muxPlaybackId: "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4",
            estimatedHours: 1.5,
            certificateType: .motorControlAdvanced,
            xpReward: 150,
            skillLevel: .master
        )
    ]
}