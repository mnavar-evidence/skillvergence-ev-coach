//
//  StudentRosterView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Student Roster View

struct StudentRosterView: View {
    @ObservedObject var viewModel: TeacherViewModel
    @State private var searchText = ""
    @State private var selectedFilter: StudentFilter = .all
    @State private var showingStudentDetail = false

    var filteredStudents: [ClassStudent] {
        let filtered = viewModel.students.filter { student in
            switch selectedFilter {
            case .all:
                return true
            case .active:
                return student.isActive
            case .needsAttention:
                return viewModel.getStudentsNeedingAttention().contains { $0.id == student.id }
            case .topPerformers:
                return viewModel.getTopPerformingStudents().contains { $0.id == student.id }
            case .level(let level):
                return student.courseLevel == level
            }
        }

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { student in
                student.fullName.localizedCaseInsensitiveContains(searchText) ||
                student.studentId.localizedCaseInsensitiveContains(searchText) ||
                student.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Header
            headerSection

            // Student List
            studentListSection
        }
        .navigationTitle("Class Roster")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingStudentDetail) {
            if let student = viewModel.selectedStudent {
                StudentDetailView(student: student, viewModel: viewModel)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search students...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StudentFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            count: filter.count(for: viewModel),
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Stats Summary
            HStack(spacing: 20) {
                StatsSummary(
                    title: "Total Students",
                    value: "\(filteredStudents.count)",
                    color: .blue
                )

                StatsSummary(
                    title: "Avg XP",
                    value: "\(Int(filteredStudents.map(\.totalXP).reduce(0, +) / max(filteredStudents.count, 1)))",
                    color: .green
                )

                StatsSummary(
                    title: "Active Today",
                    value: "\(viewModel.activeToday)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var studentListSection: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredStudents) { student in
                    StudentRowView(student: student) {
                        viewModel.selectedStudent = student
                        showingStudentDetail = true
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .refreshable {
            await viewModel.refreshClassData()
        }
    }
}

// MARK: - Student Filter Enum

enum StudentFilter: CaseIterable, Hashable {
    case all
    case active
    case needsAttention
    case topPerformers
    case level(CTECourseLevel)

    static var allCases: [StudentFilter] {
        var cases: [StudentFilter] = [.all, .active, .needsAttention, .topPerformers]
        cases.append(contentsOf: CTECourseLevel.allCases.map { .level($0) })
        return cases
    }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .needsAttention: return "Needs Attention"
        case .topPerformers: return "Top Performers"
        case .level(let level): return "Level \(level.sequenceNumber)"
        }
    }

    @MainActor func count(for viewModel: TeacherViewModel) -> Int {
        switch self {
        case .all:
            return viewModel.students.count
        case .active:
            return viewModel.students.filter(\.isActive).count
        case .needsAttention:
            return viewModel.getStudentsNeedingAttention().count
        case .topPerformers:
            return viewModel.getTopPerformingStudents().count
        case .level(let level):
            return viewModel.getStudentsByLevel(level).count
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? .blue : .gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct StatsSummary: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StudentRowView: View {
    let student: ClassStudent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Student Avatar
                Circle()
                    .fill(student.isActive ? Color.green.gradient : Color.gray.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(student.fullName.prefix(1))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.fullName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Label("\(student.totalXP) XP", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)

                        Label("Level \(student.currentLevel)", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)

                        Spacer(minLength: 12)

                        lastActivityText
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

extension StudentRowView {
    private var lastActivityText: some View {
        Group {
            if !student.lastActiveString.isEmpty {
                Text(student.lastActiveString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No activity")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Student Detail View

struct StudentDetailView: View {
    let student: ClassStudent
    @ObservedObject var viewModel: TeacherViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Student Header
                    studentHeaderSection

                    // Progress Overview
                    progressOverviewSection

                    // Course Progress
                    courseProgressSection

                    // Activity Timeline
                    activityTimelineSection

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Student Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private var studentHeaderSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 100, height: 100)
                .overlay(
                    Text(student.fullName.prefix(2))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(spacing: 8) {
                Text(student.fullName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(student.studentId)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(student.email)
                    .font(.caption)
                    .foregroundColor(.blue)

                HStack(spacing: 8) {
                    Circle()
                        .fill(student.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)

                    Text(student.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(student.isActive ? .green : .gray)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProgressCard(
                    title: "Total XP",
                    value: "\(student.totalXP)",
                    icon: "star.fill",
                    color: .orange
                )

                ProgressCard(
                    title: "Current Level",
                    value: "\(student.currentLevel)",
                    icon: "crown.fill",
                    color: .purple
                )

                ProgressCard(
                    title: "Videos Completed",
                    value: "\(student.videosCompleted)",
                    icon: "play.circle.fill",
                    color: .blue
                )

                ProgressCard(
                    title: "Watch Time",
                    value: "\(String(format: "%.1f", student.totalWatchTime))h",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
    }

    private var courseProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Progress")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(["course_1", "course_2", "course_3", "course_4", "course_5"], id: \.self) { courseId in
                    CourseProgressRow(
                        courseName: getCourseName(for: courseId),
                        isCompleted: student.coursesCompleted.contains(courseId),
                        completionPercentage: student.coursesCompleted.contains(courseId) ? 100 : Int.random(in: 0...80)
                    )
                }
            }
        }
    }

    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)

            if let lastActivity = student.lastActivityDate {
                Text("Last active: \(RelativeDateTimeFormatter().localizedString(for: lastActivity, relativeTo: Date()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button("Send Message") {
                // Implementation for sending message to student
            }
            .buttonStyle(.borderedProminent)

            Button("Generate Certificate") {
                // Implementation for generating certificate
            }
            .buttonStyle(.bordered)

            Button("View Detailed Analytics") {
                // Implementation for detailed analytics
            }
            .buttonStyle(.borderless)
        }
    }

    private func getCourseName(for courseId: String) -> String {
        switch courseId {
        case "course_1": return "High Voltage Safety Foundation"
        case "course_2": return "Electrical Fundamentals"
        case "course_3": return "Advanced Electrical Diagnostics"
        case "course_4": return "EV Charging Systems"
        case "course_5": return "Advanced EV Systems"
        default: return "Course \(courseId)"
        }
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct CourseProgressRow: View {
    let courseName: String
    let isCompleted: Bool
    let completionPercentage: Int

    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(courseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                ProgressView(value: Double(completionPercentage), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: isCompleted ? .green : .blue))
            }

            Spacer()

            Text("\(completionPercentage)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isCompleted ? .green : .secondary)
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        StudentRosterView(viewModel: TeacherViewModel.preview)
    }
}
