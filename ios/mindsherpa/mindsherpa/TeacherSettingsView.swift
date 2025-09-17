//
//  TeacherSettingsView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Teacher Settings View

struct TeacherSettingsView: View {
    @ObservedObject var viewModel: TeacherViewModel
    @StateObject private var settingsManager = TeacherSettingsManager()
    @State private var showingLogoutAlert = false
    @State private var showingStudentImport = false
    @State private var showingClassCodeGenerator = false

    var body: some View {
        NavigationView {
            List {
                // Teacher Profile Section
                teacherProfileSection

                // Class Management Section
                classManagementSection

                // Certificate Settings Section
                certificateSettingsSection

                // Notification Settings Section
                notificationSettingsSection

                // Data & Privacy Section
                dataPrivacySection

                // Help & Support Section
                helpSupportSection

                // Account Actions Section
                accountActionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingStudentImport) {
            StudentImportView(settingsManager: settingsManager)
        }
        .sheet(isPresented: $showingClassCodeGenerator) {
            ClassCodeGeneratorView(teacher: viewModel.currentTeacher)
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                settingsManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out of your teacher account?")
        }
    }

    private var teacherProfileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Teacher Avatar
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(viewModel.currentTeacher.fullName.prefix(2))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentTeacher.fullName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(viewModel.currentTeacher.department)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(viewModel.currentTeacher.school)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Edit") {
                    // Navigate to profile editing
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Teacher Profile")
        }
    }

    private var classManagementSection: some View {
        Section {
            SettingsRow(
                icon: "person.3.fill",
                title: "Manage Students",
                subtitle: "\(viewModel.totalStudents) students enrolled",
                color: .blue
            ) {
                // Navigate to student management
            }

            SettingsRow(
                icon: "square.and.arrow.up",
                title: "Import Students",
                subtitle: "Add students from CSV or roster",
                color: .green
            ) {
                showingStudentImport = true
            }

            SettingsRow(
                icon: "qrcode",
                title: "Class Join Code",
                subtitle: "Generate code for student enrollment",
                color: .purple
            ) {
                showingClassCodeGenerator = true
            }

            SettingsRow(
                icon: "chart.bar.xaxis",
                title: "Grade Export",
                subtitle: "Export to gradebook or LMS",
                color: .orange
            ) {
                settingsManager.exportGrades()
            }
        } header: {
            Text("Class Management")
        }
    }

    private var certificateSettingsSection: some View {
        Section {
            Toggle("Auto-approve certificates", isOn: $settingsManager.autoApproveCertificates)

            SettingsRow(
                icon: "doc.badge.plus",
                title: "Certificate Templates",
                subtitle: "Customize certificate designs",
                color: .indigo
            ) {
                // Navigate to certificate templates
            }

            SettingsRow(
                icon: "signature",
                title: "Digital Signature",
                subtitle: "Add your signature to certificates",
                color: .brown
            ) {
                // Navigate to signature setup
            }

            HStack {
                Label("Minimum completion for certificate", systemImage: "percent")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(settingsManager.minimumCompletionForCertificate))%")
                    .foregroundColor(.secondary)
            }

            Slider(
                value: $settingsManager.minimumCompletionForCertificate,
                in: 50...100,
                step: 5
            )
        } header: {
            Text("Certificate Settings")
        } footer: {
            Text("Students must complete at least \(Int(settingsManager.minimumCompletionForCertificate))% of a course to be eligible for a certificate.")
        }
    }

    private var notificationSettingsSection: some View {
        Section {
            Toggle("Certificate requests", isOn: $settingsManager.notifyOnCertificateRequests)
            Toggle("Student milestones", isOn: $settingsManager.notifyOnStudentMilestones)
            Toggle("Weekly progress summary", isOn: $settingsManager.weeklyProgressSummary)
            Toggle("Inactive student alerts", isOn: $settingsManager.inactiveStudentAlerts)

            Picker("Email digest frequency", selection: $settingsManager.emailDigestFrequency) {
                Text("Daily").tag(EmailDigestFrequency.daily)
                Text("Weekly").tag(EmailDigestFrequency.weekly)
                Text("Monthly").tag(EmailDigestFrequency.monthly)
                Text("Never").tag(EmailDigestFrequency.never)
            }
        } header: {
            Text("Notifications")
        }
    }

    private var dataPrivacySection: some View {
        Section {
            SettingsRow(
                icon: "shield.fill",
                title: "Privacy Policy",
                subtitle: "Review our privacy practices",
                color: .green
            ) {
                settingsManager.openPrivacyPolicy()
            }

            SettingsRow(
                icon: "doc.text.fill",
                title: "Data Usage",
                subtitle: "See how student data is used",
                color: .blue
            ) {
                settingsManager.openDataUsageInfo()
            }

            SettingsRow(
                icon: "square.and.arrow.down",
                title: "Export Class Data",
                subtitle: "Download your class information",
                color: .orange
            ) {
                settingsManager.exportClassData()
            }

            SettingsRow(
                icon: "trash.fill",
                title: "Delete Class Data",
                subtitle: "Permanently remove all class data",
                color: .red
            ) {
                settingsManager.showDeleteClassDataAlert()
            }
        } header: {
            Text("Data & Privacy")
        }
    }

    private var helpSupportSection: some View {
        Section {
            SettingsRow(
                icon: "questionmark.circle.fill",
                title: "Help Center",
                subtitle: "Find answers and tutorials",
                color: .blue
            ) {
                settingsManager.openHelpCenter()
            }

            SettingsRow(
                icon: "message.fill",
                title: "Contact Support",
                subtitle: "Get help from our team",
                color: .green
            ) {
                settingsManager.contactSupport()
            }

            SettingsRow(
                icon: "star.fill",
                title: "Rate MindSherpa",
                subtitle: "Share your feedback",
                color: .yellow
            ) {
                settingsManager.openAppStore()
            }

            HStack {
                Label("App Version", systemImage: "info.circle")
                    .foregroundColor(.secondary)
                Spacer()
                Text("2.1.0 (Build 47)")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Help & Support")
        }
    }

    private var accountActionsSection: some View {
        Section {
            Button("Sign Out") {
                showingLogoutAlert = true
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Student Import View

struct StudentImportView: View {
    @ObservedObject var settingsManager: TeacherSettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var importMethod: ImportMethod = .csv
    @State private var csvText = ""
    @State private var rosterCode = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Import Method Picker
                Picker("Import Method", selection: $importMethod) {
                    Text("CSV File").tag(ImportMethod.csv)
                    Text("Roster Code").tag(ImportMethod.rosterCode)
                    Text("Manual Entry").tag(ImportMethod.manual)
                }
                .pickerStyle(.segmented)

                // Import Content
                switch importMethod {
                case .csv:
                    csvImportSection
                case .rosterCode:
                    rosterCodeSection
                case .manual:
                    manualEntrySection
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Import Students") {
                        settingsManager.importStudents(method: importMethod, data: csvText.isEmpty ? rosterCode : csvText)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(csvText.isEmpty && rosterCode.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Import Students")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var csvImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CSV Import")
                .font(.headline)

            Text("Paste your student roster CSV data below. Format: Name, Email, Student ID, Course Level")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $csvText)
                .frame(minHeight: 200)
                .padding(8)
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )

            Button("Sample CSV Format") {
                csvText = """
                John Doe, john.doe@student.fuhsd.net, ST2024001, Transportation Tech I
                Jane Smith, jane.smith@student.fuhsd.net, ST2024002, Transportation Tech II
                """
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
        }
    }

    private var rosterCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("School Roster Code")
                .font(.headline)

            Text("Enter the roster code provided by your school's student information system.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Enter roster code", text: $rosterCode)
                .textFieldStyle(.roundedBorder)
                .textContentType(.oneTimeCode)

            Button("Connect to PowerSchool") {
                // Implementation for PowerSchool integration
            }
            .buttonStyle(.bordered)
        }
    }

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Entry")
                .font(.headline)

            Text("Add students one by one using the manual entry form.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Add Student Manually") {
                // Navigate to manual student entry form
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Class Code Generator View

struct ClassCodeGeneratorView: View {
    let teacher: Teacher
    @Environment(\.dismiss) private var dismiss
    @State private var generatedCode = ""
    @State private var expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Class Info
                VStack(spacing: 12) {
                    Text(teacher.classTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(teacher.school)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Generated Code Display
                if !generatedCode.isEmpty {
                    VStack(spacing: 16) {
                        Text("Class Join Code")
                            .font(.headline)

                        Text(generatedCode)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .cornerRadius(12)

                        Text("Students can use this code to join your class")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button("Copy Code") {
                                UIPasteboard.general.string = generatedCode
                            }
                            .buttonStyle(.bordered)

                            Button("Share") {
                                // Implementation for sharing code
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Code Settings")
                        .font(.headline)

                    DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)

                    Toggle("Allow new student registration", isOn: .constant(true))
                }
                .padding()
                .background(.gray.opacity(0.05))
                .cornerRadius(12)

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button(generatedCode.isEmpty ? "Generate Code" : "Regenerate Code") {
                        generateClassCode()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Class Join Code")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if generatedCode.isEmpty {
                generateClassCode()
            }
        }
    }

    private func generateClassCode() {
        // Generate a 6-character alphanumeric code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        generatedCode = String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - Settings Manager

@MainActor
class TeacherSettingsManager: ObservableObject {
    @Published var autoApproveCertificates = false
    @Published var minimumCompletionForCertificate: Double = 80.0
    @Published var notifyOnCertificateRequests = true
    @Published var notifyOnStudentMilestones = true
    @Published var weeklyProgressSummary = true
    @Published var inactiveStudentAlerts = true
    @Published var emailDigestFrequency: EmailDigestFrequency = .weekly

    func signOut() {
        // Implementation for signing out
        print("Teacher signed out")
    }

    func exportGrades() {
        // Implementation for exporting grades
        print("Exporting grades...")
    }

    func importStudents(method: ImportMethod, data: String) {
        // Implementation for importing students
        print("Importing students via \(method): \(data)")
    }

    func openPrivacyPolicy() {
        // Implementation for opening privacy policy
        print("Opening privacy policy...")
    }

    func openDataUsageInfo() {
        // Implementation for opening data usage info
        print("Opening data usage info...")
    }

    func exportClassData() {
        // Implementation for exporting class data
        print("Exporting class data...")
    }

    func showDeleteClassDataAlert() {
        // Implementation for showing delete alert
        print("Showing delete class data alert...")
    }

    func openHelpCenter() {
        // Implementation for opening help center
        print("Opening help center...")
    }

    func contactSupport() {
        // Implementation for contacting support
        print("Contacting support...")
    }

    func openAppStore() {
        // Implementation for opening app store
        print("Opening app store...")
    }
}

// MARK: - Enums

enum ImportMethod {
    case csv, rosterCode, manual
}

enum EmailDigestFrequency: CaseIterable {
    case daily, weekly, monthly, never

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .never: return "Never"
        }
    }
}

// MARK: - Preview

#Preview {
    TeacherSettingsView(viewModel: TeacherViewModel.preview)
}