//
//  AdvancedCourseListView.swift
//  mindsherpa
//
//  Created by Claude on 9/4/25.
//

import SwiftUI

struct AdvancedCourseListView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var selectedCourse: AdvancedCourse?
    
    let advancedCourses = AdvancedCourse.sampleAdvancedCourses
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(advancedCourses) { course in
                        AdvancedCourseCard(
                            course: course,
                            onTap: {
                                handleCourseSelection(course)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Advanced Courses")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Certificates hidden for TestFlight
                        // NavigationLink(destination: CertificateAdminView()) {
                        //     Image(systemName: "graduationcap.circle")
                        //         .font(.title3)
                        //         .foregroundColor(.blue)
                        // }

                        Text("5 courses")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.gray.opacity(0.15))
                            )
                    }
                }
            }
            .sheet(item: $selectedCourse) { course in
                if subscriptionManager.isCourseUnlocked(courseId: course.id) {
                    // Course is purchased - check if prerequisite is completed
                    if course.isUnlocked {
                        // Both purchased and prerequisite complete - show module list for all courses
                        switch course.id {
                        case "adv_1":
                            Course1ModuleListView(course: course)
                        case "adv_2":
                            Course2ModuleListView(course: course)
                        case "adv_3":
                            Course3ModuleListView(course: course)
                        case "adv_4":
                            Course4ModuleListView(course: course)
                        case "adv_5":
                            Course5ModuleListView(course: course)
                        default:
                            UnifiedVideoPlayer(advancedCourse: course)
                        }
                    } else {
                        // Purchased but prerequisite incomplete - show prerequisite message
                        CoursePrerequisiteView(course: course)
                    }
                } else {
                    // Not purchased - show paywall
                    CoursePaywallView(course: course)
                }
            }
        }
    }
    
    private var subscriptionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: subscriptionManager.hasActiveSubscription ? "crown.fill" : "lock.fill")
                .font(.caption)
            Text(subscriptionManager.currentTier.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(subscriptionManager.hasActiveSubscription ? .orange : .gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(subscriptionManager.hasActiveSubscription ? .orange.opacity(0.1) : .gray.opacity(0.1))
        )
    }
    
    private func handleCourseSelection(_ course: AdvancedCourse) {
        // Always allow users to see the paywall, regardless of prerequisite status
        selectedCourse = course
    }
}

// MARK: - Course 1 Module List View
struct Course1ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course1Module?
    @State private var modulesWithRealDurations: [Course1Module] = []

    // Course 1 modules data - 7 modules for High Voltage Vehicle Safety
    private let course1Modules = [
        Course1Module(
            id: "1-1",
            title: "1.1 High Voltage Workplace Personnel",
            description: "Overview of high voltage safety in electric vehicles covering different roles and qualifications including electrically aware persons, qualified persons, and authorized persons. Understanding training requirements and authorization for high voltage work.",
            muxPlaybackId: "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-2",
            title: "1.2 High Voltage Hazards",
            description: "Comprehensive exploration of dangers associated with high voltage systems including electric shock, arc flash, and arc blast hazards. Understanding factors affecting shock severity, body resistance, and current effects.",
            muxPlaybackId: "XOvqV82WjeJnJiu4josaw9JL2k4Rq1hdV3SQA4Sg678",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-3",
            title: "1.3 Shock Protection Boundaries",
            description: "Critical concept of shock protection boundaries in high voltage environments covering limited approach, restricted approach, and arc flash boundaries. Learning to identify and respect safety zones.",
            muxPlaybackId: "bI2WjGdUUWzHJ7w00Gv3aRf7OHz1vn46RDGdgp5YvVcU",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-4",
            title: "1.4 PPE Ratings and Categories",
            description: "Personal protective equipment for high voltage work covering PPE capabilities, ratings, and categories with emphasis on arc ratings and hazard risk categories. Learning to select appropriate PPE for various tasks.",
            muxPlaybackId: "8mRfAgwaHusffNx5gObTyztZz9vtOIUY9umBArsTaic",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-5",
            title: "1.5 High Voltage Components",
            description: "In-depth look at key components of high voltage systems in electric vehicles including energy storage systems, battery management, traction motors, power distribution, inverters, and converters.",
            muxPlaybackId: "NCCNveUpYpRKBkTDINDNksgsooofohQr7q9McFS7DpY",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-6",
            title: "1.6 High-Voltage Safety Procedures",
            description: "Detailed instruction on safety procedures for working with high voltage systems covering precautionary measures, battery disabling techniques, manual service disconnects, and high voltage interlock loops.",
            muxPlaybackId: "AxKaucprgU200mmFTGLNIRlpSkaA02FMZwFmmZ1rmaUrE",
            estimatedMinutes: nil,
            xpReward: 100
        ),
        Course1Module(
            id: "1-7",
            title: "1.7 Warning Labels",
            description: "Visual identification of high voltage components in electric vehicles covering badges, wraps, orange cables, and high voltage warning labels. Learning to recognize and interpret various warning signs and markings.",
            muxPlaybackId: "fYYHPmsdI1iYZYBZfOhuUkQgD8RDsfm2tHSScOUIYAw",
            estimatedMinutes: nil,
            xpReward: 100
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(course1Modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }

                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))

                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modulesWithRealDurations.isEmpty ? course1Modules : modulesWithRealDurations) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRealDurations()
            }
        }
        .sheet(item: $selectedModule) { module in
            // Convert Course1Module to AdvancedCourse for UnifiedVideoPlayer
            let advancedCourse = AdvancedCourse(
                id: "adv_\(module.id)",
                title: module.title,
                description: module.description,
                prerequisiteCourseId: "course_1",
                muxPlaybackId: module.muxPlaybackId,
                estimatedHours: Double(module.estimatedMinutes ?? 0) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .expert
            )

            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }

    private func fetchRealDurations() {
        modulesWithRealDurations = course1Modules
        print("🎬 Fetching real video durations from Mux for Course 1...")

        for (index, module) in course1Modules.enumerated() {
            Task {
                do {
                    let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                    let durationMinutes = max(1, Int(duration / 60))

                    print("✅ \(module.id): Real duration = \(durationMinutes) minutes (\(Int(duration)) seconds)")

                    await MainActor.run {
                        var updatedModule = module
                        updatedModule.estimatedMinutes = durationMinutes
                        modulesWithRealDurations[index] = updatedModule
                    }
                } catch {
                    print("❌ \(module.id): Error fetching duration - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Course 2 Module List View
struct Course2ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course2Module?
    @State private var modulesWithRealDurations: [Course2Module] = []

    // Course 2 modules data - Electrical Level 1 (4 modules • 3:53:40)
    private let course2Modules = [
        Course2Module(
            id: "2-1",
            title: "2.1 Basic Circuit Components & Configuration",
            description: "Understanding electrical components, series and parallel circuits, and calculating voltage, current, resistance, and power. Practical lab exercises reinforce theoretical knowledge for building and testing circuits.",
            muxPlaybackId: "KGnXNWj2cE7FE8usEaoA2ROnqGQAMqZq021Xykgski2k",
            estimatedMinutes: nil,
            xpReward: 120
        ),
        Course2Module(
            id: "2-2",
            title: "2.2 Electrical Measurements",
            description: "Comprehensive training on using digital multimeters for automotive electrical measurements, covering voltage, current, resistance, continuity, capacitance, and frequency measurements with safety procedures.",
            muxPlaybackId: "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
            estimatedMinutes: nil,
            xpReward: 120
        ),
        Course2Module(
            id: "2-3",
            title: "2.3 Electrical Fault Analysis",
            description: "Comprehensive training in diagnosing and troubleshooting electrical issues including high resistance faults, open circuits, shorts to ground, and component faults using digital multimeters.",
            muxPlaybackId: "f7bWarA02aIjBloGalrhHuSXRGGEEtpwvJ3nLnjAtxV4",
            estimatedMinutes: nil,
            xpReward: 120
        ),
        Course2Module(
            id: "2-4",
            title: "2.4 Circuit Diagnosis",
            description: "Essential skills for troubleshooting electrical systems, reading wiring diagrams, tracing current flow, and systematic diagnostic approaches using digital multimeters and voltage drop tests.",
            muxPlaybackId: "k7feJpMDdL6CJc1GeCS2MHRR9B1h2Yotr02Kypy2bupg",
            estimatedMinutes: nil,
            xpReward: 120
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(course2Modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }

                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))

                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modulesWithRealDurations.isEmpty ? course2Modules : modulesWithRealDurations) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRealDurations()
            }
        }
        .sheet(item: $selectedModule) { module in
            // Convert Course2Module to AdvancedCourse for UnifiedVideoPlayer
            let advancedCourse = AdvancedCourse(
                id: "adv_\(module.id)",
                title: module.title,
                description: module.description,
                prerequisiteCourseId: "course_2",
                muxPlaybackId: module.muxPlaybackId,
                estimatedHours: Double(module.estimatedMinutes ?? 0) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .expert
            )

            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }

    private func fetchRealDurations() {
        modulesWithRealDurations = course2Modules
        print("🎬 Fetching real video durations from Mux for Course 2...")

        for (index, module) in course2Modules.enumerated() {
            Task {
                do {
                    let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                    let durationMinutes = max(1, Int(duration / 60))

                    print("✅ \(module.id): Real duration = \(durationMinutes) minutes (\(Int(duration)) seconds)")

                    await MainActor.run {
                        var updatedModule = module
                        updatedModule.estimatedMinutes = durationMinutes
                        modulesWithRealDurations[index] = updatedModule
                    }
                } catch {
                    print("❌ \(module.id): Error fetching duration - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Course 3 Module List View
struct Course3ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course3Module?
    @State private var modulesWithRealDurations: [Course3Module] = []

    // Course 3 modules data - Electrical Level 2 (2 modules • 2:30:32)
    private let course3Modules = [
        Course3Module(
            id: "3-1",
            title: "3.1 Advanced Electrical Systems Diagnosis",
            description: "Advanced digital multimeter functions and oscilloscope operation for precise voltage, current, and waveform analysis. In-depth study of computer input/output circuits, sensors, and actuators in modern vehicles with hands-on diagnostic techniques.",
            muxPlaybackId: "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",
            estimatedMinutes: nil,
            xpReward: 140
        ),
        Course3Module(
            id: "3-2",
            title: "3.2 Automotive Communication Systems",
            description: "Comprehensive overview of automotive bus communication systems including K-CAN, PT-CAN, LIN, FlexRay, MOST, and Ethernet. Understanding gateway modules, fiber optics, LVDS, real-time vehicle scanning, and diagnostic strategies for complex network architectures.",
            muxPlaybackId: "WMQlHCyi1zrF018XtLXycNXHqTMnvVxV70001tMSXOS02J4",
            estimatedMinutes: nil,
            xpReward: 140
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(course3Modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }

                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))

                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modulesWithRealDurations.isEmpty ? course3Modules : modulesWithRealDurations) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRealDurations()
            }
        }
        .sheet(item: $selectedModule) { module in
            // Convert Course3Module to AdvancedCourse for UnifiedVideoPlayer
            let advancedCourse = AdvancedCourse(
                id: "adv_\(module.id)",
                title: module.title,
                description: module.description,
                prerequisiteCourseId: "course_3",
                muxPlaybackId: module.muxPlaybackId,
                estimatedHours: Double(module.estimatedMinutes ?? 0) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .expert
            )

            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }

    private func fetchRealDurations() {
        modulesWithRealDurations = course3Modules
        print("🎬 Fetching real video durations from Mux for Course 3...")

        for (index, module) in course3Modules.enumerated() {
            Task {
                do {
                    let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                    let durationMinutes = max(1, Int(duration / 60))

                    print("✅ \(module.id): Real duration = \(durationMinutes) minutes (\(Int(duration)) seconds)")

                    await MainActor.run {
                        var updatedModule = module
                        updatedModule.estimatedMinutes = durationMinutes
                        modulesWithRealDurations[index] = updatedModule
                    }
                } catch {
                    print("❌ \(module.id): Error fetching duration - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Course 4 Module List View
struct Course4ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course4Module?
    @State private var modulesWithRealDurations: [Course4Module] = []

    // Course 4 modules data - EV Supply Equipment (2 modules • 1:12:19)
    private let course4Modules = [
        Course4Module(
            id: "4-1",
            title: "4.1 Electric Vehicle Supply Equipment & Electric Vehicle Charging Systems",
            description: "Comprehensive exploration of EV charging infrastructure including EVSE types, charging levels (Level 1, 2, DC Fast), charging standards and connectors (J1772, CCS, CHAdeMO), AC/DC charging principles, safety features, and communication protocols between EVs and charging stations.",
            muxPlaybackId: "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
            estimatedMinutes: nil,
            xpReward: 160
        ),
        Course4Module(
            id: "4-2",
            title: "4.2 Battery Management Systems",
            description: "In-depth study of EV battery systems fundamentals, battery charging/discharging characteristics, Battery Management System (BMS) functions and components, battery health monitoring, thermal management, and safety considerations in battery charging and management with hands-on diagnostic techniques.",
            muxPlaybackId: "zfSZVFnzqFm02QkqkNw301mhZtC700qvgd5IH6srTBmtJo",
            estimatedMinutes: nil,
            xpReward: 160
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(course4Modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }

                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))

                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modulesWithRealDurations.isEmpty ? course4Modules : modulesWithRealDurations) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRealDurations()
            }
        }
        .sheet(item: $selectedModule) { module in
            // Convert Course4Module to AdvancedCourse for UnifiedVideoPlayer
            let advancedCourse = AdvancedCourse(
                id: "adv_\(module.id)",
                title: module.title,
                description: module.description,
                prerequisiteCourseId: "course_4",
                muxPlaybackId: module.muxPlaybackId,
                estimatedHours: Double(module.estimatedMinutes ?? 0) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .expert
            )

            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }

    private func fetchRealDurations() {
        modulesWithRealDurations = course4Modules
        print("🎬 Fetching real video durations from Mux for Course 4...")

        for (index, module) in course4Modules.enumerated() {
            Task {
                do {
                    let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                    let durationMinutes = max(1, Int(duration / 60))

                    print("✅ \(module.id): Real duration = \(durationMinutes) minutes (\(Int(duration)) seconds)")

                    await MainActor.run {
                        var updatedModule = module
                        updatedModule.estimatedMinutes = durationMinutes
                        modulesWithRealDurations[index] = updatedModule
                    }
                } catch {
                    print("❌ \(module.id): Error fetching duration - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Course 5 Module List View
struct Course5ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course5Module?
    @State private var modulesWithRealDurations: [Course5Module] = []

    // Course 5 modules data - will be updated with real durations
    private let course5Modules = [
        Course5Module(
            id: "5-1",
            title: "5.1 Introduction to Electric Vehicles",
            description: "Overview of EV history and evolution, comparison between conventional, hybrid, and fully electric vehicles, key components of EV powertrains, EV charging infrastructure and standards, and environmental impact and advantages of EVs.",
            muxPlaybackId: "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedMinutes: nil, // Start with nil - will be updated with real duration
            xpReward: 150
        ),
        Course5Module(
            id: "5-2",
            title: "5.2 Electric Vehicle Energy Storage Systems",
            description: "Basics of battery technology and cell chemistry, types of batteries used in EVs (lithium-ion, LFP, NMC), battery management systems and thermal management, energy capacity, power density, efficiency concepts, charging and discharging characteristics, and future trends in EV battery technology.",
            muxPlaybackId: "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedMinutes: nil, // Start with nil - will be updated with real duration
            xpReward: 150
        ),
        Course5Module(
            id: "5-3",
            title: "5.3 Electric Vehicle Architecture, Motors & Controllers",
            description: "EV powertrain architectures (in-wheel, centralized), types of electric motors used in EVs (permanent magnet, induction), motor control systems and power electronics, regenerative braking systems, and efficiency and performance characteristics of EV drivetrains.",
            muxPlaybackId: "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4",
            estimatedMinutes: nil, // Start with nil - will be updated with real duration
            xpReward: 150
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(course5Modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }
                    
                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))
                
                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modulesWithRealDurations.isEmpty ? course5Modules : modulesWithRealDurations) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRealDurations()
            }
        }
        .sheet(item: $selectedModule) { module in
            // Convert Course5Module to AdvancedCourse for UnifiedVideoPlayer
            let advancedCourse = AdvancedCourse(
                id: "adv_\(module.id)",
                title: module.title,
                description: module.description,
                prerequisiteCourseId: "course_5",
                muxPlaybackId: module.muxPlaybackId,
                estimatedHours: Double(module.estimatedMinutes ?? 0) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .master
            )
            
            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }

    // MARK: - Real Duration Fetching

    private func fetchRealDurations() {
        // Initialize with modules that have nil durations (show ... until real duration is fetched)
        modulesWithRealDurations = course5Modules

        print("🎬 Fetching real video durations from Mux for Course 5...")

        // Fetch real durations for each module asynchronously
        for (index, module) in course5Modules.enumerated() {
            Task {
                do {
                    let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                    let durationMinutes = max(1, Int(duration / 60)) // Convert seconds to minutes, minimum 1 minute

                    print("✅ \(module.id): Real duration = \(durationMinutes) minutes (\(Int(duration)) seconds)")

                    // Update the module with real duration on main thread
                    await MainActor.run {
                        var updatedModule = module
                        updatedModule.estimatedMinutes = durationMinutes
                        modulesWithRealDurations[index] = updatedModule
                    }
                } catch {
                    print("❌ \(module.id): Error fetching duration - \(error.localizedDescription)")
                    // Keep nil duration on error to show ... instead of wrong placeholder
                }
            }
        }
    }
}

// MARK: - Course Module Data Models

protocol CourseModule: Identifiable {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    var muxPlaybackId: String { get }
    var estimatedMinutes: Int? { get set }
    var xpReward: Int { get }
    var formattedDuration: String { get }
}

extension CourseModule {
    var formattedDuration: String {
        guard let minutes = estimatedMinutes else {
            return "..." // Show loading indicator instead of placeholder
        }

        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// Course 1 Module
struct Course1Module: CourseModule {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    var estimatedMinutes: Int?
    let xpReward: Int
}

// Course 2 Module
struct Course2Module: CourseModule {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    var estimatedMinutes: Int?
    let xpReward: Int
}

// Course 3 Module
struct Course3Module: CourseModule {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    var estimatedMinutes: Int?
    let xpReward: Int
}

// Course 4 Module
struct Course4Module: CourseModule {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    var estimatedMinutes: Int?
    let xpReward: Int
}

// Course 5 Module
struct Course5Module: CourseModule {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    var estimatedMinutes: Int?
    let xpReward: Int
}

// MARK: - Generic Course Module Card
struct CourseModuleCard<T: CourseModule>: View {
    let module: T
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(module.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("\(module.xpReward) XP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }

                Text(module.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AdvancedCourseCard: View {
    let course: AdvancedCourse
    let onTap: () -> Void
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with lock/unlock status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("Prerequisite: Complete \(course.prerequisiteCourseId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: courseStatusIcon)
                            .font(.title2)
                            .foregroundColor(courseStatusColor)
                        
                        Text(courseStatusText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(courseStatusColor)
                        
                        Text("\(course.xpReward) XP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                // Description
                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Course details
                HStack {
                    Label(course.formattedDuration, systemImage: "clock")
                    
                    Spacer()
                    
                    Label(course.skillLevel.displayName, systemImage: course.certificateType.badgeIcon)
                    
                    if !subscriptionManager.hasActiveSubscription {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
    
    @MainActor private var isUnlocked: Bool {
        // Check if prerequisite course is completed AND course is purchased
        return course.isUnlocked && subscriptionManager.isCourseUnlocked(courseId: course.id)
    }
    
    @MainActor private var courseStatusIcon: String {
        let isPurchased = subscriptionManager.isCourseUnlocked(courseId: course.id)
        let prerequisiteComplete = course.isUnlocked

        if isPurchased && prerequisiteComplete {
            return "play.circle.fill"  // Ready to play
        } else if isPurchased {
            return "checkmark.circle.fill"  // Purchased but prerequisite needed
        } else {
            return "lock.fill"  // Not purchased
        }
    }
    
    @MainActor private var courseStatusColor: Color {
        let isPurchased = subscriptionManager.isCourseUnlocked(courseId: course.id)
        let prerequisiteComplete = course.isUnlocked

        if isPurchased && prerequisiteComplete {
            return .green  // Ready to play
        } else if isPurchased {
            return .blue  // Purchased but prerequisite needed
        } else {
            return .gray  // Not purchased
        }
    }
    
    @MainActor private var courseStatusText: String {
        let isPurchased = subscriptionManager.isCourseUnlocked(courseId: course.id)
        let prerequisiteComplete = course.isUnlocked

        if isPurchased && prerequisiteComplete {
            return "Ready"
        } else if isPurchased {
            return "Owned"
        } else {
            return "Locked"
        }
    }
}

// MARK: - Course Prerequisite View

struct CoursePrerequisiteView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    
    private var prerequisiteCourseName: String {
        let courseNumber = course.prerequisiteCourseId.replacingOccurrences(of: "course_", with: "")
        switch courseNumber {
        case "1":
            return "Basic Course - High Voltage Safety Foundation"
        case "2":
            return "Basic Course - Electrical Fundamentals"
        case "3":
            return "Basic Course - EV System Components"
        case "4":
            return "Basic Course - EV Charging Systems"
        case "5":
            return "Basic Course - Advanced EV Systems"
        default:
            return "Basic Course \(courseNumber)"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Course Purchased!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(course.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                // Prerequisite requirement
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    Text("Prerequisite Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("To access this advanced course, you must first complete \(prerequisiteCourseName).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Once you complete the prerequisite course, this advanced content will be available.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Course-Specific Paywall View

struct CoursePaywallView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var authorizationCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    
    // Course unlock codes (individual + universal test codes)
    private var courseUnlockCodes: [String: [String]] {
        [
            "adv_1": ["100001", "654321"], // Course 1.0 High Voltage Vehicle Safety
            "adv_2": ["200002", "654322"], // Course 2.0 Electrical Level 1
            "adv_3": ["300003", "654323"], // Course 3.0 Electrical Level 2
            "adv_4": ["400004", "654324"], // Course 4.0 Electric Vehicle Supply Equipment
            "adv_5": ["500005", "654325"]  // Course 5.0 Introduction to Electric Vehicles
        ]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with course-specific info
                VStack(spacing: 12) {
                    Image(systemName: course.certificateType.badgeIcon)
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Purchase Course")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(course.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Enter your purchase code to unlock this course")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Course details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                        Text("\(course.formattedDuration) of content")
                    }
                    HStack {
                        Image(systemName: "star.fill")
                        Text("\(course.xpReward) XP reward")
                    }
                    HStack {
                        Image(systemName: course.certificateType.badgeIcon)
                        Text(course.skillLevel.displayName)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Authorization Code Input
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Course Purchase Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SixDigitCodeView(code: $authorizationCode, onCodeChanged: {
                            // Clear error when user types
                            if showError {
                                showError = false
                            }
                        })
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: validateCourseCode) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isValidating ? "Validating..." : "Unlock Course")
                                .font(.headline)
                        }
                    }
                    .disabled(authorizationCode.count != 6 || isValidating)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (authorizationCode.count == 6 && !isValidating) ? Color.orange : Color.gray
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
    
    private func validateCourseCode() {
        isValidating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let expectedCodes = courseUnlockCodes[course.id], 
               expectedCodes.contains(authorizationCode) {
                // Valid code - unlock this specific course
                subscriptionManager.unlockCourse(courseId: course.id)
                dismiss()
            } else {
                // Invalid code
                showError = true
                errorMessage = "Invalid purchase code for this course. Please check your code and try again."
            }
            isValidating = false
        }
    }
}

// MARK: - Six Digit Code Entry View

struct SixDigitCodeView: View {
    @Binding var code: String
    let onCodeChanged: () -> Void
    
    @State private var internalCode = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Hidden text field for actual input
            TextField("", text: $internalCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isTextFieldFocused)
                .opacity(0)
                .frame(height: 0)
                .onChange(of: internalCode) { oldValue, newValue in
                    handleCodeChange(newValue)
                }
            
            // Visual digit display
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    DigitBox(
                        digit: getDigitAt(index),
                        isFocused: isTextFieldFocused && index == min(internalCode.count, 5)
                    )
                }
            }
            .onTapGesture {
                isTextFieldFocused = true
            }
        }
        .onAppear {
            // Initialize internal code from binding
            internalCode = code
            // Auto-focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleCodeChange(_ newValue: String) {
        // Only allow numeric input and limit to 6 digits
        let numericOnly = newValue.filter { $0.isNumber }
        let limitedCode = String(numericOnly.prefix(6))
        
        if limitedCode != internalCode {
            internalCode = limitedCode
        }
        
        // Update the binding
        if limitedCode != code {
            code = limitedCode
            onCodeChanged()
        }
    }
    
    private func getDigitAt(_ index: Int) -> String {
        if index < internalCode.count {
            return String(internalCode[internalCode.index(internalCode.startIndex, offsetBy: index)])
        }
        return ""
    }
}

struct DigitBox: View {
    let digit: String
    let isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.orange : Color(.systemGray4), lineWidth: 2)
                )
                .frame(width: 40, height: 50)
            
            if digit.isEmpty {
                // Show cursor when focused and empty
                if isFocused {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: 20)
                        .opacity(0.8)
                }
            } else {
                Text(digit)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    AdvancedCourseListView()
}