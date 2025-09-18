//
//  CourseProgressView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Course Progress View (matching Android implementation)

struct CourseProgressView: View {
    @ObservedObject var viewModel: TeacherViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Stats (matching Android)
                summaryStatsSection

                // Course Progress Section
                courseProgressSection

                // Podcast Engagement Section
                podcastEngagementSection

                // Top Performers Section
                topPerformersSection

                // Recent Activity Section
                recentActivitySection
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .refreshable {
            await viewModel.refreshClassData()
        }
        .onAppear {
            viewModel.loadClassData()
        }
    }

    // MARK: - Summary Stats Section

    private var summaryStatsSection: some View {
        HStack(spacing: 12) {
            // Total Students Box
            VStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("\(viewModel.totalStudents)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Total Students")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)

            // Active Today Box
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("\(viewModel.activeToday)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Active Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)

            // Average XP Box
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("\(calculateAverageXP())")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Avg XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }

    // MARK: - Course Progress Section

    private var courseProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course Progress")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(getCourseProgressData(), id: \.id) { course in
                    ProgressCourseRow(course: course)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Podcast Engagement Section

    private var podcastEngagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Podcast Engagement")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(getPodcastEngagementData(), id: \.id) { podcast in
                    PodcastEngagementRow(podcast: podcast)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Top Performers Section

    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(getTopPerformers(), id: \.id) { performer in
                    TopPerformerRow(performer: performer)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(getRecentActivities(), id: \.id) { activity in
                    RecentActivityRow(activity: activity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Data Generation Methods

    private func calculateAverageXP() -> Int {
        guard !viewModel.students.isEmpty else { return 0 }
        let totalXP = viewModel.students.map(\.totalXP).reduce(0, +)
        return totalXP / viewModel.students.count
    }

    private func getCourseProgressData() -> [CourseProgressData] {
        let courses = [
            ("High Voltage Safety Foundation", 12, 15, 80),
            ("Electrical Fundamentals", 10, 15, 67),
            ("EV System Components", 8, 15, 53),
            ("EV Charging Systems", 6, 15, 40),
            ("Advanced EV Systems", 4, 15, 27)
        ]

        return courses.enumerated().map { index, course in
            CourseProgressData(
                id: "course_\(index)",
                courseName: course.0,
                completedStudents: course.1,
                totalStudents: course.2,
                progressPercentage: course.3
            )
        }
    }

    private func getPodcastEngagementData() -> [PodcastEngagementData] {
        let podcasts = [
            ("EV Safety Fundamentals", 8, 15, 45, 53),
            ("Electrical Systems Deep Dive", 6, 15, 38, 40),
            ("Battery Technology Explained", 5, 15, 42, 33),
            ("Charging Infrastructure", 4, 15, 35, 27),
            ("Future of EVs", 3, 15, 28, 20)
        ]

        return podcasts.enumerated().map { index, podcast in
            PodcastEngagementData(
                id: "podcast_\(index)",
                title: podcast.0,
                listenersCount: podcast.1,
                totalStudents: podcast.2,
                avgListenMinutes: podcast.3,
                engagementPercentage: podcast.4
            )
        }
    }

    private func getTopPerformers() -> [TopPerformerData] {
        return viewModel.students
            .sorted { $0.totalXP > $1.totalXP }
            .prefix(5)
            .enumerated()
            .map { index, student in
                TopPerformerData(
                    id: student.id,
                    rank: index + 1,
                    name: student.fullName,
                    level: student.currentLevel,
                    xp: student.totalXP,
                    certificates: student.coursesCompleted.count,
                    progress: (student.coursesCompleted.count * 100) / 5
                )
            }
    }

    private func getRecentActivities() -> [RecentActivityData] {
        return [
            RecentActivityData(id: "1", icon: "📚", description: "Video completed", details: "Murgesh Navar • High Voltage Safety Foundation", timeAgo: "30m ago"),
            RecentActivityData(id: "2", icon: "⚡", description: "Earned 25 XP", details: "Abigail Clark • Electrical Fundamentals Quiz", timeAgo: "45m ago"),
            RecentActivityData(id: "3", icon: "🎯", description: "Started course", details: "John Smith • EV System Components", timeAgo: "1h ago"),
            RecentActivityData(id: "4", icon: "📖", description: "Module progress", details: "Sarah Johnson • 75% complete in EV Charging", timeAgo: "2h ago"),
            RecentActivityData(id: "5", icon: "🔋", description: "Watch streak", details: "Mike Brown • 5 day learning streak", timeAgo: "3h ago"),
            RecentActivityData(id: "6", icon: "⭐", description: "XP milestone", details: "Emma Davis • Reached 500 XP total", timeAgo: "4h ago"),
            RecentActivityData(id: "7", icon: "📺", description: "Video watched", details: "Chris Wilson • Advanced EV Systems Intro", timeAgo: "5h ago")
        ]
    }
}

// MARK: - Supporting Views

struct ProgressCourseRow: View {
    let course: CourseProgressData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.courseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(course.completedStudents)/\(course.totalStudents) students actively engaged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(course.progressPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ProgressView(value: Double(course.progressPercentage), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 50)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PodcastEngagementRow: View {
    let podcast: PodcastEngagementData

    var body: some View {
        HStack {
            Text("🎧")
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(podcast.listenersCount)/\(podcast.totalStudents) students listened • \(podcast.avgListenMinutes) min avg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(podcast.engagementPercentage)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct TopPerformerRow: View {
    let performer: TopPerformerData

    var body: some View {
        HStack {
            // Rank Badge
            Text("\(performer.rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(rankColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(performer.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Level \(performer.level) • \(performer.xp) XP • \(performer.certificates) Certificates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(performer.progress)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private var rankColor: Color {
        switch performer.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct RecentActivityRow: View {
    let activity: RecentActivityData

    var body: some View {
        HStack {
            Text(activity.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(activity.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct CourseProgressData {
    let id: String
    let courseName: String
    let completedStudents: Int
    let totalStudents: Int
    let progressPercentage: Int
}

struct PodcastEngagementData {
    let id: String
    let title: String
    let listenersCount: Int
    let totalStudents: Int
    let avgListenMinutes: Int
    let engagementPercentage: Int
}

struct TopPerformerData {
    let id: String
    let rank: Int
    let name: String
    let level: Int
    let xp: Int
    let certificates: Int
    let progress: Int
}

struct RecentActivityData {
    let id: String
    let icon: String
    let description: String
    let details: String
    let timeAgo: String
}

// MARK: - Preview

#Preview {
    NavigationView {
        CourseProgressView(viewModel: TeacherViewModel.preview)
    }
}