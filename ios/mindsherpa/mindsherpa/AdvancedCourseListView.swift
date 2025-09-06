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
            .sheet(item: $selectedCourse) { course in
                // Course 5 has multiple modules - show module list
                if course.prerequisiteCourseId == "course_5" {
                    Course5ModuleListView(course: course)
                } else {
                    // Other courses have single advanced videos
                    if course.isUnlocked && subscriptionManager.hasActiveSubscription {
                        UnifiedVideoPlayer(advancedCourse: course)
                    } else {
                        PremiumPaywallView()
                    }
                }
            }
            .sheet(isPresented: $subscriptionManager.showPaywall) {
                PremiumPaywallView()
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
        // Course 5 advanced videos are free for anyone who completed basic Course 5
        if course.prerequisiteCourseId == "course_5" && course.isUnlocked {
            selectedCourse = course
        } else if subscriptionManager.hasActiveSubscription && course.isUnlocked {
            selectedCourse = course
        } else {
            subscriptionManager.requestAdvancedAccess()
        }
    }
}

// MARK: - Course 5 Module List View
struct Course5ModuleListView: View {
    let course: AdvancedCourse
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedModule: Course5Module?
    
    // Course 5 modules data
    private let course5Modules = [
        Course5Module(
            id: "5-1",
            title: "5.1 Introduction to Electric Vehicles",
            description: "Comprehensive exploration of EV history, powertrain fundamentals, and charging infrastructure standards.",
            muxPlaybackId: "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
            estimatedMinutes: 90,
            xpReward: 150
        ),
        Course5Module(
            id: "5-2", 
            title: "5.2 Electric Vehicle Energy Storage Systems",
            description: "Advanced study of battery chemistry, cell technology, and thermal management systems.",
            muxPlaybackId: "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
            estimatedMinutes: 90,
            xpReward: 150
        ),
        Course5Module(
            id: "5-3",
            title: "5.3 EV Architecture, Motors & Controllers", 
            description: "Master-level analysis of EV powertrain architectures and motor control systems.",
            muxPlaybackId: "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4",
            estimatedMinutes: 90,
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
                        ForEach(course5Modules) { module in
                            Course5ModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
                estimatedHours: Double(module.estimatedMinutes) / 60.0,
                certificateType: .evFundamentalsAdvanced,
                xpReward: module.xpReward,
                skillLevel: .master
            )
            
            UnifiedVideoPlayer(advancedCourse: advancedCourse)
        }
    }
}

// MARK: - Course 5 Module Data Model
struct Course5Module: Identifiable {
    let id: String
    let title: String
    let description: String
    let muxPlaybackId: String
    let estimatedMinutes: Int
    let xpReward: Int
    
    var formattedDuration: String {
        return "\(estimatedMinutes) min"
    }
}

// MARK: - Course 5 Module Card
struct Course5ModuleCard: View {
    let module: Course5Module
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
                        
                        Text("Advanced Module • \(module.formattedDuration)")
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
                        Image(systemName: isUnlocked ? "play.circle.fill" : "lock.fill")
                            .font(.title2)
                            .foregroundColor(isUnlocked ? .green : .gray)
                        
                        #if DEBUG
                        // Debug info
                        VStack(spacing: 2) {
                            if course.prerequisiteCourseId == "course_5" {
                                Text("Free C5")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("Sub: \(subscriptionManager.hasActiveSubscription ? "✓" : "✗")")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            Text("C5: \(course.isUnlocked ? "✓" : "✗")")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        #endif
                        
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
                    Label("\(String(format: "%.1f", course.estimatedHours)) hours", systemImage: "clock")
                    
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
        // For Course 5 advanced videos: unlock if basic Course 5 is completed (no subscription needed)
        // For other advanced courses: require subscription AND prerequisite completion
        
        if course.prerequisiteCourseId == "course_5" {
            // Course 5 advanced videos are free for anyone who completed basic Course 5
            return course.isUnlocked
        } else {
            // Other advanced courses require subscription + prerequisite completion
            return subscriptionManager.hasActiveSubscription && course.isUnlocked
        }
    }
}

// MARK: - Placeholder Paywall View

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var authorizationCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    
    private let masterCode = "654321"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Access Advanced Courses")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your authorization code to unlock expert-level content")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(SubscriptionTier.premium.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.subheadline)
                        }
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
                        Text("Authorization Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter 6-digit code", text: $authorizationCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .onChange(of: authorizationCode) { oldValue, newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    authorizationCode = String(newValue.prefix(6))
                                }
                                // Clear error when user types
                                if showError {
                                    showError = false
                                }
                            }
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: validateAuthorizationCode) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isValidating ? "Validating..." : "Unlock Courses")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateAuthorizationCode() {
        isValidating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if authorizationCode == masterCode {
                // Valid code - grant premium access
                subscriptionManager.grantPremiumAccess()
                dismiss()
            } else {
                // Invalid code
                showError = true
                errorMessage = "Invalid authorization code. Please try again."
            }
            isValidating = false
        }
    }
}

#Preview {
    AdvancedCourseListView()
}