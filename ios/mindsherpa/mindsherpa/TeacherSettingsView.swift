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
    @State private var showingStudentImport = false
    @State private var showingClassCodeGenerator = false

    var body: some View {
        NavigationView {
            List {
                // Class Management Section
                classManagementSection

                // Certificate Settings Section
                certificateSettingsSection

                // Account Actions Section
                accountActionsSection
            }
        }
        .sheet(isPresented: $showingStudentImport) {
            StudentImportView(settingsManager: settingsManager)
        }
        .sheet(isPresented: $showingClassCodeGenerator) {
            if let teacher = viewModel.currentTeacher {
                ClassCodeGeneratorView(teacher: teacher)
            }
        }
    }


    private var classManagementSection: some View {
        Section {
            SettingsRow(
                icon: "qrcode",
                title: "Class Join Code",
                subtitle: "Students use this code to join your class and unlock access to basic foundational courses",
                color: .purple
            ) {
                showingClassCodeGenerator = true
            }
        } header: {
            Text("Class Management")
        }
    }

    private var certificateSettingsSection: some View {
        Section {
            Toggle("Auto-approve certificates", isOn: $settingsManager.autoApproveCertificates)

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



    private var accountActionsSection: some View {
        Section {
            Label("Exit Teacher Mode", systemImage: "arrow.backward.circle.fill")
                .foregroundColor(.red)
                .onTapGesture {
                    AccessControlManager.shared.exitTeacherMode()
                }
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

// MARK: - Class Code Share View

struct ClassCodeGeneratorView: View {
    let teacher: Teacher
    @Environment(\.dismiss) private var dismiss

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

                // Current Code Display
                VStack(spacing: 16) {
                    Text("Class Join Code")
                        .font(.headline)

                    Text(teacher.classCode ?? "No Code Available")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)

                    Text("Students use this code to join your class and unlock access to basic foundational courses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    if let classCode = teacher.classCode {
                        HStack(spacing: 16) {
                            Button("Copy Code") {
                                UIPasteboard.general.string = classCode
                            }
                            .buttonStyle(.bordered)

                            Button("Share") {
                                // Implementation for sharing code
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Spacer()

                // Action Button
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Class Join Code")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Settings Manager

@MainActor
class TeacherSettingsManager: ObservableObject {
    @Published var autoApproveCertificates = false
    @Published var minimumCompletionForCertificate: Double = 80.0

    func exportGrades() {
        // Implementation for exporting grades
        print("Exporting grades...")
    }

    func importStudents(method: ImportMethod, data: String) {
        // Implementation for importing students
        print("Importing students via \(method): \(data)")
    }
}

// MARK: - Enums

enum ImportMethod {
    case csv, rosterCode, manual
}


// MARK: - Preview

#Preview {
    TeacherSettingsView(viewModel: TeacherViewModel.preview)
}