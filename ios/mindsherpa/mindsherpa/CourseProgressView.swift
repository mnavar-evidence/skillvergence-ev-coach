//
//  CourseProgressView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Course Progress Analytics View

struct CourseProgressView: View {
    @ObservedObject var viewModel: TeacherViewModel
    @StateObject private var analyticsManager = CourseAnalyticsManager()
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedCourse: String = "all"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Controls
                headerControlsSection

                // Overview Stats
                overviewStatsSection

                // Course Completion Chart
                courseCompletionChartSection

                // Student Engagement Chart
                studentEngagementSection

                // Performance by Course Level
                performanceByCourseSection

                // Top Performers
                topPerformersSection

                // Students Needing Attention
                studentsNeedingAttentionSection
            }
            .padding()
        }
        .navigationTitle("Course Analytics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            analyticsManager.loadAnalytics(for: viewModel.students)
        }
    }

    private var headerControlsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analytics Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Export Report") {
                    analyticsManager.exportAnalyticsReport()
                }
                .buttonStyle(.bordered)
            }

            // Time Frame Selector
            Picker("Time Frame", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)

            // Course Filter
            Picker("Course", selection: $selectedCourse) {
                Text("All Courses").tag("all")
                ForEach(analyticsManager.availableCourses, id: \.self) { course in
                    Text(course).tag(course)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var overviewStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsCard(
                title: "Class Average",
                value: "\(Int(analyticsManager.classAverage))%",
                subtitle: "Course Completion",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                trend: analyticsManager.completionTrend
            )

            AnalyticsCard(
                title: "Engagement Rate",
                value: "\(Int(analyticsManager.engagementRate))%",
                subtitle: "Daily Active Users",
                icon: "person.3.fill",
                color: .green,
                trend: analyticsManager.engagementTrend
            )

            AnalyticsCard(
                title: "Avg Watch Time",
                value: "\(String(format: "%.1f", analyticsManager.averageWatchTime))h",
                subtitle: "Per Student",
                icon: "clock.fill",
                color: .orange,
                trend: analyticsManager.watchTimeTrend
            )
        }
    }

    private var courseCompletionChartSection: some View {
        GroupBox("Course Completion Progress") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Course completion data visualization would be displayed here")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        Text("Chart View")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }

    private var studentEngagementSection: some View {
        GroupBox("Student Engagement Over Time") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Student engagement trends would be displayed here")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        Text("Line Chart View")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }

    private var performanceByCourseSection: some View {
        GroupBox("Performance by Course Level") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(CTECourseLevel.allCases, id: \.self) { level in
                    let studentsInLevel = viewModel.getStudentsByLevel(level)
                    let averageXP = studentsInLevel.map(\.totalXP).reduce(0, +) / max(studentsInLevel.count, 1)
                    let completionRate = Double(studentsInLevel.filter { !$0.coursesCompleted.isEmpty }.count) / Double(max(studentsInLevel.count, 1)) * 100

                    CourseLevelRow(
                        level: level,
                        studentCount: studentsInLevel.count,
                        averageXP: averageXP,
                        completionRate: completionRate
                    )
                }
            }
        }
    }

    private var topPerformersSection: some View {
        GroupBox("Top Performers") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.getTopPerformingStudents(limit: 5).prefix(5), id: \.id) { student in
                    StudentPerformanceRow(student: student, rank: viewModel.getTopPerformingStudents().firstIndex(where: { $0.id == student.id })! + 1)
                }
            }
        }
    }

    private var studentsNeedingAttentionSection: some View {
        GroupBox("Students Needing Attention") {
            VStack(alignment: .leading, spacing: 12) {
                let needingAttention = viewModel.getStudentsNeedingAttention().prefix(5)
                if needingAttention.isEmpty {
                    Text("All students are on track! 🎉")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(Array(needingAttention), id: \.id) { student in
                        StudentAttentionRow(student: student)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                TrendIndicator(trend: trend)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct TrendIndicator: View {
    let trend: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
            Text("\(String(format: "%.1f", abs(trend)))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(trend >= 0 ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background((trend >= 0 ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(8)
    }
}

struct CourseLevelRow: View {
    let level: CTECourseLevel
    let studentCount: Int
    let averageXP: Int
    let completionRate: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(level.displayName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text("\(studentCount) students")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(averageXP)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Avg XP")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(completionRate))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Completion")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct StudentPerformanceRow: View {
    let student: ClassStudent
    let rank: Int

    var body: some View {
        HStack {
            // Rank Badge
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(rankColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(student.totalXP) XP • Level \(student.currentLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(student.coursesCompleted.count)/5")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Courses")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct StudentAttentionRow: View {
    let student: ClassStudent

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(attentionReason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Contact") {
                // Implementation for contacting student
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var attentionReason: String {
        if let lastActivity = student.lastActivityDate {
            let days = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            if days > 7 {
                return "Inactive for \(days) days"
            }
        }

        if student.totalXP < 100 {
            return "Low engagement (\(student.totalXP) XP)"
        }

        return "Needs support"
    }
}

// MARK: - Analytics Manager

@MainActor
class CourseAnalyticsManager: ObservableObject {
    @Published var courseCompletionData: [CourseCompletionData] = []
    @Published var engagementData: [EngagementData] = []
    @Published var classAverage: Double = 0
    @Published var engagementRate: Double = 0
    @Published var averageWatchTime: Double = 0

    // Trends (percentage change)
    @Published var completionTrend: Double = 0
    @Published var engagementTrend: Double = 0
    @Published var watchTimeTrend: Double = 0

    let availableCourses = [
        "High Voltage Safety",
        "Electrical Fundamentals",
        "Advanced Diagnostics",
        "EV Charging Systems",
        "Advanced EV Systems"
    ]

    func loadAnalytics(for students: [ClassStudent]) {
        generateCourseCompletionData(for: students)
        generateEngagementData()
        calculateOverallMetrics(for: students)
        calculateTrends()
    }

    func exportAnalyticsReport() {
        print("Exporting analytics report...")
    }

    private func generateCourseCompletionData(for students: [ClassStudent]) {
        let courses = [
            ("Course 1: Safety", "course_1", Color.red),
            ("Course 2: Electrical", "course_2", Color.orange),
            ("Course 3: Diagnostics", "course_3", Color.yellow),
            ("Course 4: Charging", "course_4", Color.green),
            ("Course 5: Advanced", "course_5", Color.blue)
        ]

        courseCompletionData = courses.map { (name, id, color) in
            let completedCount = students.filter { $0.coursesCompleted.contains(id) }.count
            let completionPercentage = Double(completedCount) / Double(students.count) * 100

            return CourseCompletionData(
                courseName: name,
                completionPercentage: completionPercentage,
                color: color
            )
        }
    }

    private func generateEngagementData() {
        let calendar = Calendar.current
        let today = Date()

        engagementData = (0..<7).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let activeStudents = Int.random(in: 25...45) // Simulated data

            return EngagementData(date: date, activeStudents: activeStudents)
        }.reversed()
    }

    private func calculateOverallMetrics(for students: [ClassStudent]) {
        // Class average completion
        let totalCompletions = students.map { $0.coursesCompleted.count }.reduce(0, +)
        classAverage = Double(totalCompletions) / Double(students.count * 5) * 100

        // Engagement rate (students active in last 7 days)
        let activeStudents = students.filter { student in
            guard let lastActivity = student.lastActivityDate else { return false }
            let daysSinceActivity = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 999
            return daysSinceActivity <= 7
        }.count
        engagementRate = Double(activeStudents) / Double(students.count) * 100

        // Average watch time
        averageWatchTime = students.map(\.totalWatchTime).reduce(0, +) / Double(students.count)
    }

    private func calculateTrends() {
        // Simulated trend data (in real app, compare with previous period)
        completionTrend = Double.random(in: -5...15)
        engagementTrend = Double.random(in: -10...20)
        watchTimeTrend = Double.random(in: -8...12)
    }
}

// MARK: - Data Models

struct CourseCompletionData {
    let courseName: String
    let completionPercentage: Double
    let color: Color
}

struct EngagementData {
    let date: Date
    let activeStudents: Int
}

enum TimeFrame: CaseIterable {
    case week, month, semester, year

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .semester: return "Semester"
        case .year: return "Year"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CourseProgressView(viewModel: TeacherViewModel.preview)
    }
}