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
                if subscriptionManager.isCourseUnlocked(courseId: course.id) {
                    // Course is purchased - check if prerequisite is completed
                    if course.isUnlocked {
                        // Both purchased and prerequisite complete - show content
                        if course.prerequisiteCourseId == "course_5" {
                            Course5ModuleListView(course: course)
                        } else {
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
        return "Course \(courseNumber)"
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
    
    // Unique codes for each course (in production, these would come from a server)
    private var courseUnlockCodes: [String: String] {
        [
            "adv_1": "100001", // Course 1.0 High Voltage Vehicle Safety
            "adv_2": "200002", // Course 2.0 Electrical Level 1
            "adv_3": "300003", // Course 3.0 Electrical Level 2
            "adv_4": "400004", // Course 4.0 Electric Vehicle Supply Equipment
            "adv_5": "500005"  // Course 5.0 Introduction to Electric Vehicles
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
                        Text("\(String(format: "%.1f", course.estimatedHours)) hours of content")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateCourseCode() {
        isValidating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let expectedCode = courseUnlockCodes[course.id], authorizationCode == expectedCode {
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
    
    @State private var digits: [String] = ["", "", "", "", "", ""]
    @FocusState private var focusedField: Int?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                TextField("", text: Binding(
                    get: { digits[index] },
                    set: { newValue in
                        handleDigitInput(at: index, input: newValue)
                    }
                ))
                .frame(width: 40, height: 50)
                .multilineTextAlignment(.center)
                .font(.title2)
                .fontWeight(.semibold)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: index)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == index ? Color.orange : Color(.systemGray4), lineWidth: 2)
                        )
                )
                .onTapGesture {
                    focusedField = index
                }
                .onChange(of: focusedField) { _, newFocus in
                    // Clear selection when focus changes to prevent cursor issues
                    if newFocus != index && !digits[index].isEmpty {
                        // This helps prevent cursor getting stuck
                    }
                }
            }
        }
        .onAppear {
            // Initialize from existing code if any
            initializeDigits()
            // Focus on first empty field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = findFirstEmptyField()
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private func handleDigitInput(at index: Int, input: String) {
        // Handle backspace (empty input)
        if input.isEmpty {
            digits[index] = ""
            // Move to previous field
            if index > 0 {
                focusedField = index - 1
            }
            updateCode()
            return
        }
        
        // Handle digit input
        let filtered = input.filter { $0.isNumber }
        if let lastChar = filtered.last {
            digits[index] = String(lastChar)
            
            // Move to next field if available
            if index < 5 {
                focusedField = index + 1
            } else {
                // All fields filled, dismiss keyboard
                focusedField = nil
            }
            
            updateCode()
        }
    }
    
    private func updateCode() {
        let newCode = digits.joined()
        if newCode != code {
            code = newCode
            onCodeChanged()
        }
    }
    
    private func initializeDigits() {
        if !code.isEmpty {
            let codeArray = Array(code)
            for i in 0..<min(codeArray.count, 6) {
                digits[i] = String(codeArray[i])
            }
        }
    }
    
    private func findFirstEmptyField() -> Int {
        for i in 0..<6 {
            if digits[i].isEmpty {
                return i
            }
        }
        return 0
    }
}

#Preview {
    AdvancedCourseListView()
}