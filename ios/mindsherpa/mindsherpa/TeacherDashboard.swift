//
//  TeacherDashboard.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Teacher Dashboard Main View

struct TeacherDashboardView: View {
    @StateObject private var teacherViewModel = TeacherViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            FixedTabView(selection: $selectedTab) {
                // Class Overview Tab
                ClassOverviewView(viewModel: teacherViewModel)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Overview")
                    }
                    .tag(0)

                // Student List Tab
                StudentRosterView(viewModel: teacherViewModel)
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Students")
                    }
                    .tag(1)

                // Certificates Tab
                CertificateManagementView(viewModel: teacherViewModel)
                    .tabItem {
                        Image(systemName: "graduationcap.fill")
                        Text("Certificates")
                    }
                    .tag(2)

                // Course Progress Tab
                CourseProgressView(viewModel: teacherViewModel)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(3)

                // Settings Tab
                TeacherSettingsView(viewModel: teacherViewModel)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .navigationTitle("Teacher Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .onAppear {
                teacherViewModel.loadClassData()
            }
        }
    }
}

// MARK: - Class Overview View

struct ClassOverviewView: View {
    @ObservedObject var viewModel: TeacherViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Teacher Header
                teacherHeaderSection

                // Quick Stats Cards
                statsCardsSection
            }
            .padding()
        }
        .refreshable {
            await viewModel.forceRefreshClassData()
        }
        .onAppear {
            // Only load data if not already loaded
            viewModel.loadClassData()
        }
        .overlay {
            if viewModel.isLoading && viewModel.students.isEmpty {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading class data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var teacherHeaderSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Teacher Avatar
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("DJ")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    if let teacherName = AccessControlManager.shared.teacherData?.name {
                        Text(teacherName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    if let program = AccessControlManager.shared.teacherData?.program {
                        Text(program)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let school = AccessControlManager.shared.teacherData?.school {
                        Text(school)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let email = AccessControlManager.shared.teacherData?.email {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                            Text(email)
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }

                    if let classCode = AccessControlManager.shared.teacherData?.classCode {
                        HStack(spacing: 4) {
                            Image(systemName: "qrcode")
                                .font(.caption)
                            Text("Class Code: \(classCode)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var statsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            DashboardStatCard(
                title: "Total Students",
                value: "\(viewModel.totalStudents)",
                icon: "person.3.fill",
                color: .blue
            )

            DashboardStatCard(
                title: "Active Today",
                value: "\(viewModel.activeToday)",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )

            DashboardStatCard(
                title: "Certificates Pending",
                value: "\(viewModel.pendingCertificates)",
                icon: "graduationcap.circle",
                color: .orange
            )

            DashboardStatCard(
                title: "Course Completion",
                value: "\(Int(viewModel.averageCompletion))%",
                icon: "checkmark.circle.fill",
                color: .purple
            )
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVStack(spacing: 8) {
                ForEach(viewModel.recentActivities.prefix(5), id: \.id) { activity in
                    ActivityRowView(activity: activity)
                }
            }
            .padding()
            .background(.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Review Certificates",
                    icon: "graduationcap.fill",
                    color: .orange
                ) {
                    // Navigate to certificates tab
                }

                QuickActionButton(
                    title: "Export Progress",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    viewModel.exportClassProgress()
                }

                QuickActionButton(
                    title: "Send Announcements",
                    icon: "megaphone.fill",
                    color: .purple
                ) {
                    viewModel.showAnnouncementDialog = true
                }

                QuickActionButton(
                    title: "Class Analytics",
                    icon: "chart.bar.xaxis",
                    color: .green
                ) {
                    // Navigate to analytics
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct ActivityRowView: View {
    let activity: StudentActivity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(activity.studentName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(activity.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TeacherDashboardView()
}
