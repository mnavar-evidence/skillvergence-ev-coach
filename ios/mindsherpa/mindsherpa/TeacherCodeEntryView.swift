//
//  TeacherCodeEntryView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

struct TeacherCodeEntryView: View {
    @ObservedObject private var accessControl = AccessControlManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var teacherCode = ""
    @State private var showError = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Teacher Access")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter your teacher access code to view class management dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Code Input
                VStack(spacing: 16) {
                    TextField("Teacher Code (e.g., T12345)", text: $teacherCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            validateCode()
                        }

                    if showError {
                        Text("Invalid teacher code. Please check with your administrator.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Help text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teacher Access Information:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Teacher codes start with 'T' followed by 5 digits")
                            Text("• Contact your school administrator for access")
                            Text("• Fallbrook High School: Contact IT department")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button("Access Teacher Dashboard") {
                        validateCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(teacherCode.count < 6)

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .navigationTitle("Teacher Access")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func validateCode() {
        Task {
            let isValid = await accessControl.validateTeacherCode(teacherCode)

            await MainActor.run {
                if isValid {
                    dismiss()
                } else {
                    showError = true
                    teacherCode = ""

                    // Hide error after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showError = false
                    }
                }
            }
        }
    }
}

#Preview {
    TeacherCodeEntryView()
}