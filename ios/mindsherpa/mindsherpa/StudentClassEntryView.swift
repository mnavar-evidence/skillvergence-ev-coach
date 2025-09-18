//
//  StudentClassEntryView.swift
//  mindsherpa
//
//  Created by Claude Code on 9/17/25.
//

import SwiftUI

struct StudentClassEntryView: View {
    @ObservedObject private var progressAPI = StudentProgressAPI.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var classCode = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @FocusState private var focusedField: Field?

    enum Field {
        case classCode, firstName, lastName, email
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Join Your Class")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Enter your class code and student information to connect with your instructor")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Form
                    VStack(spacing: 16) {
                        // Class Code
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class Code")
                                .font(.headline)
                                .fontWeight(.semibold)

                            TextField("Enter class code (e.g., ABN0E0)", text: $classCode)
                                .textFieldStyle(.roundedBorder)
                                .font(.title3)
                                .textCase(.uppercase)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .classCode)
                                .onSubmit {
                                    focusedField = .firstName
                                }

                            Text("Ask your instructor for your class code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Student Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Student Information")
                                .font(.headline)
                                .fontWeight(.semibold)

                            // First Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                TextField("Enter your first name", text: $firstName)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .firstName)
                                    .onSubmit {
                                        focusedField = .lastName
                                    }
                            }

                            // Last Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                TextField("Enter your last name", text: $lastName)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .lastName)
                                    .onSubmit {
                                        focusedField = .email
                                    }
                            }

                            // Email (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .onSubmit {
                                        joinClass()
                                    }
                            }
                        }

                        // Current Student Status
                        if progressAPI.isStudentLinked {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Linked to Class")
                                        .fontWeight(.medium)
                                }

                                VStack(spacing: 4) {
                                    Text("Student: \(progressAPI.studentDisplayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let classCode = progressAPI.studentInfo?.classCode {
                                        Text("Class: \(classCode)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Show detailed class information if available
                                if let classDetails = progressAPI.studentInfo?.classDetails {
                                    VStack(spacing: 6) {
                                        Divider()

                                        StudentInfoCard(title: "Teacher", value: classDetails.teacherName, icon: "person.circle")
                                        StudentInfoCard(title: "School", value: classDetails.schoolName, icon: "building.2")
                                        StudentInfoCard(title: "Program", value: classDetails.programName, icon: "graduationcap")
                                        StudentInfoCard(title: "Email", value: classDetails.teacherEmail, icon: "envelope")
                                    }
                                }

                                Button("Change Class") {
                                    progressAPI.clearStudentInfo()
                                    clearForm()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    Spacer(minLength: 32)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: joinClass) {
                            HStack {
                                if progressAPI.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                }
                                Text(progressAPI.isStudentLinked ? "Update Information" : "Join Class")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canJoinClass || progressAPI.isLoading)

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding()
            }
            .navigationTitle("Student Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            loadExistingInfo()
            focusedField = .classCode

            // Register device when view appears
            Task {
                await progressAPI.registerDevice()
            }
        }
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("Great!") {
                dismiss()
            }
        } message: {
            Text("You've successfully joined the class! Your progress will now be tracked by your instructor.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(progressAPI.lastError ?? "Failed to join class. Please check your information and try again.")
        }
    }

    private var canJoinClass: Bool {
        return !classCode.isEmpty && !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
    }

    private func loadExistingInfo() {
        if let studentInfo = progressAPI.studentInfo {
            classCode = studentInfo.classCode ?? ""
            firstName = studentInfo.firstName ?? ""
            lastName = studentInfo.lastName ?? ""
            email = studentInfo.email ?? ""
        } else {
            // Load from UserDefaults or use existing user name
            let existingName = progressStore.getUserName()
            if !existingName.isEmpty {
                let nameParts = existingName.components(separatedBy: " ")
                if nameParts.count >= 2 {
                    firstName = nameParts[0]
                    lastName = nameParts[1...].joined(separator: " ")
                } else {
                    firstName = existingName
                }
            }
        }
    }

    private func clearForm() {
        classCode = ""
        firstName = ""
        lastName = ""
        email = ""
    }

    private func joinClass() {
        Task {
            let success = await progressAPI.joinClass(
                classCode: classCode.uppercased(),
                firstName: firstName,
                lastName: lastName,
                email: email
            )

            await MainActor.run {
                if success {
                    // Update the progress store user name
                    progressStore.setUserName("\(firstName) \(lastName)")
                    showSuccessAlert = true
                } else {
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StudentInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    StudentClassEntryView()
}