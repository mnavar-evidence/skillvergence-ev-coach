//
//  CoachViews.swift
//  mindsherpa
//
//  Created by Murgesh Navar on 8/26/25.
//

import SwiftUI


struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LevelMetricView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var showLevelDetails = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Level badge icon
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            // Level title
            Text("Level")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            // Current level with XP progress
            VStack(spacing: 2) {
                Text("L\(progressStore.getCurrentLevel())")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // XP Progress bar
                let levelProgress = progressStore.getXPProgressInCurrentLevel()
                
                ProgressView(value: levelProgress.percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .scaleEffect(y: 0.6)
                    .frame(width: 40)
                
                Text("\(progressStore.getTotalXP()) XP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showLevelDetails = true
        }
        .sheet(isPresented: $showLevelDetails) {
            LevelDetailsView()
        }
    }
}

struct LevelDetailsView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Current Status
                    VStack(spacing: 16) {
                        Image(systemName: progressStore.getCurrentXPLevel().icon)
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text(progressStore.getCurrentXPLevel().displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(progressStore.getTotalXP()) XP")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        let progress = progressStore.getXPProgressToNextLevel()
                        VStack(spacing: 8) {
                            ProgressView(value: progress.percentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .scaleEffect(y: 2)
                            
                            HStack {
                                Text("\(progress.current)/\(progress.needed) XP")
                                Spacer()
                                let currentLevel = progressStore.getCurrentXPLevel()
                                if currentLevel != .diamond {
                                    let nextLevelIndex = XPLevel.allCases.firstIndex(of: currentLevel)! + 1
                                    let nextLevel = XPLevel.allCases[nextLevelIndex]
                                    Text("→ \(nextLevel.displayName)")
                                } else {
                                    Text("Max Level!")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                            let userName = progressStore.getUserName()
                            let xpNeeded = progressStore.getXPForNextLevel() - progressStore.getTotalXP()
                            Text(userName.isEmpty ? 
                                 "Need \(xpNeeded) more XP to level up!" :
                                 "\(userName), you need \(xpNeeded) more XP to level up!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                    Divider()
                    
                    // How to Earn XP
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Earn XP")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            XPSourceRow(icon: "play.circle.fill", title: "Complete a video", xp: "+50 XP", color: .blue)
                            XPSourceRow(icon: "eye.fill", title: "Watch part of a video", xp: "+10-40 XP", color: .purple)
                            XPSourceRow(icon: "flame.fill", title: "Daily learning streak", xp: "+10 XP/day", color: .red)
                        }
                    }
                    
                    Divider()
                    
                    // Level Progression
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Level Progression")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            let currentLevel = progressStore.getCurrentXPLevel()
                            let totalXP = progressStore.getTotalXP()
                            
                            XPLevelProgressRow(level: .bronze, xp: "0-999 XP", isCurrentOrPast: totalXP >= XPLevel.bronze.minXP, isCurrent: currentLevel == .bronze)
                            XPLevelProgressRow(level: .silver, xp: "1000-2499 XP", isCurrentOrPast: totalXP >= XPLevel.silver.minXP, isCurrent: currentLevel == .silver)
                            XPLevelProgressRow(level: .gold, xp: "2500-4999 XP", isCurrentOrPast: totalXP >= XPLevel.gold.minXP, isCurrent: currentLevel == .gold)
                            XPLevelProgressRow(level: .platinum, xp: "5000-9999 XP", isCurrentOrPast: totalXP >= XPLevel.platinum.minXP, isCurrent: currentLevel == .platinum)
                            XPLevelProgressRow(level: .diamond, xp: "10000+ XP", isCurrentOrPast: totalXP >= XPLevel.diamond.minXP, isCurrent: currentLevel == .diamond)
                        }
                    }
                    
                    Divider()
                    
                    // Professional Certification Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Professional Certification")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Current Certification Status
                        let certificationLevel = progressStore.getCurrentCertificationLevel()
                        let completedCourses = progressStore.getCompletedCoursesCount()
                        
                        HStack(spacing: 16) {
                            Image(systemName: certificationLevel.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(certificationLevel == .none ? .gray : .blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(certificationLevel.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("\(completedCourses)/5 courses completed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if certificationLevel != .certified {
                                    let nextLevel = getNextCertificationLevel(current: certificationLevel)
                                    let coursesNeeded = nextLevel.coursesRequired - completedCourses
                                    Text("\(coursesNeeded) more course\(coursesNeeded == 1 ? "" : "s") for \(nextLevel.shortName)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Certification Progression Roadmap
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Certification Pathway")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                CertificationProgressRow(level: .none, requirements: "Start learning", isCurrentOrPast: true, isCurrent: certificationLevel == .none, completedCourses: completedCourses)
                                CertificationProgressRow(level: .foundation, requirements: "1 course", isCurrentOrPast: completedCourses >= 1, isCurrent: certificationLevel == .foundation, completedCourses: completedCourses)
                                CertificationProgressRow(level: .associate, requirements: "2 courses", isCurrentOrPast: completedCourses >= 2, isCurrent: certificationLevel == .associate, completedCourses: completedCourses)
                                CertificationProgressRow(level: .professional, requirements: "4 courses", isCurrentOrPast: completedCourses >= 4, isCurrent: certificationLevel == .professional, completedCourses: completedCourses)
                                CertificationProgressRow(level: .certified, requirements: "5 courses", isCurrentOrPast: completedCourses >= 5, isCurrent: certificationLevel == .certified, completedCourses: completedCourses)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Course Completion Progress
                        VStack(spacing: 8) {
                            let courseDetails = progressStore.getCourseCompletionDetails()
                            
                            ForEach(Array(courseDetails.enumerated()), id: \.offset) { index, detail in
                                CourseCompletionRow(
                                    courseNumber: Int(detail.courseId) ?? 1,
                                    courseName: getCourseName(for: detail.courseId),
                                    isCompleted: detail.completed,
                                    videosCompleted: detail.videosCompleted,
                                    totalVideos: detail.totalVideos
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        let level = progressStore.getCurrentLevel()
                        let xp = progressStore.getTotalXP()
                        let levelName = progressStore.getLevelTitle()
                        ShareManager.shared.shareLevelAchievement(level: level, xp: xp, levelName: levelName)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Helper functions for certification level management
    private func getNextCertificationLevel(current: CertificationLevel) -> CertificationLevel {
        let allLevels = CertificationLevel.allCases
        if let currentIndex = allLevels.firstIndex(of: current),
           currentIndex < allLevels.count - 1 {
            return allLevels[currentIndex + 1]
        }
        return .certified // Already at max
    }
    
    private func getCourseName(for courseId: String) -> String {
        // Professional certification shows ADVANCED course names, not basic course names
        switch courseId {
        case "1": return "1.0 High Voltage Vehicle Safety (Advanced)"
        case "2": return "2.0 Electrical Level 1 - Medium Heavy Duty (Advanced)"
        case "3": return "3.0 Electrical Level 2 - Medium Heavy Duty (Advanced)"
        case "4": return "4.0 Electric Vehicle Supply Equipment (Advanced)"
        case "5": return "5.0 Introduction to Electric Vehicles (Advanced)"
        default: return "Advanced Course \(courseId)"
        }
    }
}

struct XPSourceRow: View {
    let icon: String
    let title: String
    let xp: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(xp)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }
}

struct LevelProgressRow: View {
    let level: Int
    let title: String
    let xp: String
    let isCurrentOrPast: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrentOrPast ? .orange : .gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                if isCurrentOrPast {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text("\(level)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCurrentOrPast ? .semibold : .regular)
                    .foregroundStyle(isCurrentOrPast ? .primary : .secondary)
                
                Text(xp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct XPLevelProgressRow: View {
    let level: XPLevel
    let xp: String
    let isCurrentOrPast: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrent ? .orange : (isCurrentOrPast ? .green : .gray.opacity(0.3)))
                    .frame(width: 32, height: 32)
                
                if isCurrentOrPast {
                    Image(systemName: isCurrent ? level.icon : "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: level.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level.displayName)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : (isCurrentOrPast ? .medium : .regular))
                    .foregroundStyle(isCurrent ? .primary : (isCurrentOrPast ? .primary : .secondary))
                
                Text(xp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct CertificationProgressRow: View {
    let level: CertificationLevel
    let requirements: String
    let isCurrentOrPast: Bool
    let isCurrent: Bool
    let completedCourses: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrent ? .orange : (isCurrentOrPast ? .green : .gray.opacity(0.3)))
                    .frame(width: 32, height: 32)
                
                if isCurrentOrPast {
                    Image(systemName: isCurrent ? level.icon : "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: level.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level.displayName)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : (isCurrentOrPast ? .medium : .regular))
                    .foregroundStyle(isCurrent ? .primary : (isCurrentOrPast ? .primary : .secondary))
                
                Text(requirements)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isCurrent && level != .none {
                Text("\(completedCourses)/\(level.coursesRequired)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

struct CourseCompletionRow: View {
    let courseNumber: Int
    let courseName: String
    let isCompleted: Bool
    let videosCompleted: Int
    let totalVideos: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? .green : .gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text("\(courseNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(courseName)
                    .font(.subheadline)
                    .fontWeight(isCompleted ? .semibold : .regular)
                    .foregroundStyle(isCompleted ? .primary : .secondary)
                
                Text("\(videosCompleted)/\(totalVideos) videos completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !isCompleted && videosCompleted > 0 {
                Text("\(Int(Double(videosCompleted)/Double(totalVideos) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MediaTabsView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Video", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Podcast", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Premium", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if title == "Premium" {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .white : .orange)
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.accentColor : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}



struct CoachHeaderView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var showNamePrompt = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Coach Nova
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: 2) {
                        let userName = progressStore.getUserName()
                        Text(userName.isEmpty ? "Coach Nova • personalized" : "Welcome back, \(userName)!")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(userName.isEmpty ? "Training that pays. Careers that last." : 
                             "You're \(progressStore.getXPForNextLevel() - progressStore.getTotalXP()) XP from \(getNextLevelTitle())!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Share streak button (only show if user has a streak > 1)
                let currentStreak = progressStore.getCurrentStreak()
                if currentStreak > 1 {
                    Button {
                        ShareManager.shared.shareLearningStreak(streakDays: currentStreak)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                            Text("\(currentStreak) days")
                                .font(.caption.weight(.medium))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Progress Metrics
            HStack(spacing: 12) {
                MetricView(
                    title: "Streak", 
                    value: "\(ProgressStore.shared.getCurrentStreak())d", 
                    icon: "flame.fill"
                )
                MetricView(
                    title: "Today", 
                    value: String(format: "%.0fm", ProgressStore.shared.getTodayActivity()), 
                    icon: "clock.fill"
                )
                LevelMetricView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 4)
        .onAppear {
            // Show name prompt after user has some progress (completed at least 1 video or has streak)
            if !progressStore.hasUserName() && shouldPromptForName() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showNamePrompt = true
                }
            }
        }
        .sheet(isPresented: $showNamePrompt) {
            NameCollectionView()
        }
    }
    
    private func getNextLevelTitle() -> String {
        let nextLevel = progressStore.getCurrentLevel() + 1
        switch nextLevel {
        case 2: return "Tech Trainee"
        case 3: return "Junior Technician"
        case 4: return "EV Technician"
        case 5: return "Senior Tech"
        case 6: return "EV Specialist"
        case 7: return "Master Tech"
        case 8: return "EV Expert"
        default: return "EV Master"
        }
    }
    
    private func shouldPromptForName() -> Bool {
        // Prompt for name after user has shown engagement
        let hasProgress = progressStore.getTotalXP() >= 50 // Completed at least 1 video
        let hasStreak = progressStore.getCurrentStreak() >= 2 // Has a 2-day streak
        return hasProgress || hasStreak
    }
}

struct NameCollectionView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var nameInput = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Celebration/Progress context
                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange)
                    
                    Text("Great Progress!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if progressStore.getTotalXP() >= 50 {
                        Text("You've completed your first video and earned \(progressStore.getTotalXP()) XP!")
                    } else if progressStore.getCurrentStreak() >= 2 {
                        Text("You're on a \(progressStore.getCurrentStreak())-day learning streak!")
                    } else {
                        Text("You're making excellent progress!")
                    }
                    
                    Text("I'd love to personalize your experience!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Name input
                VStack(spacing: 16) {
                    Text("What should I call you?")
                        .font(.headline)
                    
                    TextField("Enter your first name", text: $nameInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .autocorrectionDisabled()
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .onSubmit {
                            saveName()
                        }
                    
                    Text("Just your first name or nickname - this stays private on your device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button("Continue") {
                        saveName()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Maybe later") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Personalize")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            progressStore.setUserName(trimmed)
            dismiss()
        }
    }
}

struct VideoView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView("Loading courses...")
                            .controlSize(.large)
                        Text("Preparing your EV training content...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                } else if viewModel.courses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                            .symbolRenderingMode(.hierarchical)
                        Text("Unable to Load Courses")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("Check your connection and try again")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Retry") {
                            viewModel.loadCourses()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.courses, id: \.id) { course in
                            NavigationLink(
                                destination: CourseDetailView(course: course, viewModel: viewModel)
                                    .onAppear { viewModel.selectCourse(course) }
                            ) {
                                CourseCardView(course: course, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // AI Interaction with proper spacing
                AIInteractionView(viewModel: viewModel)
                    .padding(.top, 20)
                
                // Bottom safe area padding
                Color.clear
                    .frame(height: 50)
                
                // Modern navigation handled by navigationDestination
            }
            .padding()
        }
    }
}

struct CourseCardView: View {
    let course: Course
    @ObservedObject var viewModel: EVCoachViewModel
    
    // Computed properties to avoid crashes from accessing @Published during init
    private var formattedDuration: String {
        Self.formatHours(course.estimatedHours)
    }
    
    private var completionPercentage: Double {
        let totalVideos = course.videos.count
        guard totalVideos > 0 else { return 0 }
        
        let completedCount = course.videos.filter { video in
            ProgressStore.shared.videoProgress(videoId: video.id)?.completed ?? false
        }.count
        
        return Double(completedCount) / Double(totalVideos) * 100.0
    }
    
    private var completedVideoCount: Int {
        return course.videos.filter { video in
            ProgressStore.shared.videoProgress(videoId: video.id)?.completed ?? false
        }.count
    }
    
    private var hasAnyProgress: Bool {
        return course.videos.contains { video in
            if let progress = ProgressStore.shared.videoProgress(videoId: video.id) {
                return progress.watchedSec > 30 // Show progress if watched more than 30 seconds
            }
            return false
        }
    }
    
    private static func formatHours(_ hours: Double) -> String {
        if hours < 1.0 {
            let minutes = Int(hours * 60)
            return "\(minutes) min"
        } else if hours == 1.0 {
            return "1 hour"
        } else {
            let roundedHours = hours.rounded()
            return "\(Int(roundedHours)) hours"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: course.category.icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(course.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                    
                    if completionPercentage > 0 {
                        Text("\(Int(completionPercentage))%")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Text(course.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Progress bar if course has any progress
            if hasAnyProgress {
                VStack(spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(completedVideoCount) of \(course.videos.count) videos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    MediaProgressIndicator(
                        progress: completionPercentage / 100.0,
                        isCompleted: completionPercentage >= 100,
                        mediaType: .course,
                        size: .medium
                    )
                }
            }
            
            HStack {
                Label(course.skillLevel.displayName, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                    Text("\(course.videos.count) videos")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                // Share button for completed courses
                if completionPercentage >= 100 {
                    Button(action: {
                        ShareManager.shared.shareCourseCompletion(
                            courseName: course.title,
                            totalVideos: course.videos.count,
                            totalHours: course.estimatedHours
                        )
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
}

// Keep the rest of your views unchanged...

struct AIInteractionView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    @State private var questionText = ""
    @FocusState private var isTextFieldFocused: Bool

    let quickQuestions = [
        "Compare alternator vs DC-DC",
        "Explain DC fast charging",
        "What PPE do I need?",
        "How does regen braking work?"
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Quick Question Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickQuestions, id: \.self) { question in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { 
                                questionText = question
                                isTextFieldFocused = true // Focus the text field for editing
                            }
                        } label: {
                            Text(question).font(.caption).foregroundStyle(.primary)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                }
                .padding(.horizontal)
            }

            // Question Input
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                    TextField("Ask about this content...", text: $questionText)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            sendQuestion()
                        }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)

               
                
                //Button {
                  //  viewModel.askAI(question: questionText)
                    //questionText = ""
                //} label: {
                  //  Image(systemName: questionText.isEmpty ? "paperplane" : "paperplane.fill").font(.caption)
                //}
                //.buttonStyle(.borderedProminent)
                //.controlSize(.small)
                //.disabled(questionText.isEmpty || viewModel.isAILoading)
                
                Button {
                    sendQuestion()
                } label: {
                    Image(systemName: questionText.isEmpty ? "paperplane" : "paperplane.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(questionText.isEmpty || viewModel.isAILoading)
                .symbolRenderingMode(.hierarchical)
            }
            .padding(.horizontal)

            // AI response
           // if !viewModel.aiResponse.isEmpty {
             //   VStack(alignment: .leading, spacing: 8) {
             //       HStack {
              //          Image(systemName: "brain.head.profile").foregroundStyle(.blue).font(.caption)
              //          Text("Coach Nova").font(.caption).fontWeight(.medium).foregroundStyle(.primary)
              //          Spacer()
              //          Button("Clear") { viewModel.clearAIResponse() }
              //              .font(.caption2).foregroundStyle(.secondary)
              //      }
              //      Text(viewModel.aiResponse)
              //          .font(.subheadline)
              //          .foregroundStyle(.primary)
              //          .padding(12)
              //          .background(.regularMaterial)
              //          .clipShape(RoundedRectangle(cornerRadius: 8))
              //  }
              //  .padding(.horizontal)
              //  .padding(.top, 8)
           // }
            
            // Show AI response
            if !viewModel.aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Coach Nova")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text(viewModel.aiResponse)
                        .font(.subheadline)
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Show loading state
            if viewModel.isAILoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Coach Nova is thinking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .onTapGesture {
            // Dismiss keyboard when tapping outside text field
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Methods
    
    private func sendQuestion() {
        guard !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Dismiss keyboard first
        isTextFieldFocused = false
        
        // Send to AI
        viewModel.askAI(question: questionText)
        questionText = ""
    }
}

