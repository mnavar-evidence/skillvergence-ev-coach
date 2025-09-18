//
//  CodeEntryView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Code Entry View

struct CodeEntryView: View {
    @ObservedObject private var accessControl = AccessControlManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var showResult = false
    @State private var redemptionResult: CodeRedemptionResult = .invalid
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Enter Access Code")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter a code from your instructor to unlock content")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Code Input
                VStack(spacing: 16) {
                    TextField("Enter code (e.g., B12345)", text: $enteredCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            validateCode()
                        }

                    // Code Format Help
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Code Types:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack(spacing: 20) {
                            CodeTypeIndicator(prefix: "C", description: "Class Access", color: .blue)
                            CodeTypeIndicator(prefix: "P", description: "Premium Access", color: .purple)
                            CodeTypeIndicator(prefix: "F", description: "Friend Referral", color: .green)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                // Current Status
                if accessControl.currentUserTier != .free {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Current Access: \(accessControl.currentUserTier.displayName)")
                                .fontWeight(.medium)
                        }

                        if !accessControl.earnedFriendCodes.isEmpty {
                            Text("You have \(accessControl.earnedFriendCodes.count) friend codes to share!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button("Validate Code") {
                        validateCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(enteredCode.count < 6)

                    if !accessControl.earnedFriendCodes.isEmpty {
                        Button("Share Friend Codes") {
                            // Show friend codes sharing
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .navigationTitle("Access Code")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .alert("Code Result", isPresented: $showResult) {
            Button("OK") {
                if redemptionResult.isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(redemptionResult.message)
        }
    }

    private func validateCode() {
        redemptionResult = accessControl.validateAndRedeemCode(enteredCode)
        showResult = true

        if redemptionResult.isSuccess {
            enteredCode = ""

            // Generate friend codes based on level achievement
            accessControl.checkAndGenerateFriendCodes()
        }
    }
}

// MARK: - Supporting Views

struct CodeTypeIndicator: View {
    let prefix: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(prefix)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Friend Codes Sharing View

struct FriendCodesView: View {
    @ObservedObject private var accessControl = AccessControlManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Share with Friends")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("You've earned friend codes to share! Each code gives a friend free basic access.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Friend Codes List
                    LazyVStack(spacing: 12) {
                        ForEach(accessControl.earnedFriendCodes, id: \.self) { code in
                            FriendCodeRow(code: code)
                        }
                    }

                    // How to Earn More
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Earn More Friend Codes")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            EarnCodeRow(level: "Bronze (Level 1)", codes: "1 code")
                            EarnCodeRow(level: "Silver (Level 2)", codes: "2 codes")
                            EarnCodeRow(level: "Gold (Level 3)", codes: "4 codes")
                            EarnCodeRow(level: "Platinum (Level 4)", codes: "8 codes")
                            EarnCodeRow(level: "Diamond (Level 5+)", codes: "16 codes")
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Friend Codes")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct FriendCodeRow: View {
    let code: String
    @State private var copied = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(code)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Tap to copy and share")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(copied ? "Copied!" : "Copy") {
                UIPasteboard.general.string = code
                copied = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    copied = false
                }
            }
            .buttonStyle(.bordered)
            .foregroundColor(copied ? .green : .blue)
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct EarnCodeRow: View {
    let level: String
    let codes: String

    var body: some View {
        HStack {
            Text(level)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(codes)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview

#Preview("Code Entry") {
    CodeEntryView()
}

#Preview("Friend Codes") {
    FriendCodesView()
}