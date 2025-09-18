//
//  PaywallView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @ObservedObject private var accessControl = AccessControlManager.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCodeEntry = false
    @State private var showNameCollection = false
    @State private var purchaseInProgress = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Celebration Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)

                        Text("Amazing Progress!")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("You've earned \(progressStore.getTotalXP()) XP and unlocked your potential!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Progress Achievement
                    VStack(spacing: 16) {
                        Text("🎯 You've reached the 50 XP milestone!")
                            .font(.headline)
                            .foregroundColor(.orange)

                        ProgressView(value: Double(progressStore.getTotalXP()), total: 50.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2, anchor: .center)

                        Text("\(progressStore.getTotalXP()) / 50 XP")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.orange.opacity(0.1))
                    .cornerRadius(16)

                    // Continue Learning Section
                    VStack(spacing: 20) {
                        Text("Continue Your Journey")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose how you'd like to continue your learning journey with basic courses:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        // Option 1: School Code
                        PaywallOptionCard(
                            icon: "graduationcap.fill",
                            title: "Class Access Code",
                            subtitle: "Get a code from your instructor",
                            description: "Ask your instructor for your class access code",
                            buttonText: "Enter Code",
                            buttonColor: .blue,
                            isRecommended: true
                        ) {
                            showCodeEntry = true
                        }

                        // Option 2: Individual Purchase
                        PaywallOptionCard(
                            icon: "creditcard.fill",
                            title: "Individual Access",
                            subtitle: "One-time purchase",
                            description: "Continue with basic courses and podcasts beyond 50 XP",
                            buttonText: purchaseInProgress ? "Processing..." : "Buy for $49",
                            buttonColor: .green,
                            isRecommended: false
                        ) {
                            purchaseIndividualAccess()
                        }
                    }

                    // What You Get
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What You'll Unlock:")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 12) {
                            BenefitRow(icon: "play.circle.fill", text: "Continue all 5 basic video courses", color: .blue)
                            BenefitRow(icon: "headphones", text: "Access to all podcast content", color: .indigo)
                            BenefitRow(icon: "star.fill", text: "Unlimited XP earning potential", color: .orange)
                            BenefitRow(icon: "person.3.fill", text: "Friend referral codes to share", color: .green)
                            BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Progress tracking and analytics", color: .red)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    .cornerRadius(16)

                    // School Information
                    VStack(spacing: 12) {
                        Text("Fallbrook High School")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("CTE Pathway: Transportation Technology")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Instructor: Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Unlock Full Access")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Maybe Later") {
                    dismiss()
                },
                trailing: Button("Restore") {
                    restorePurchases()
                }
            )
        }
        .sheet(isPresented: $showCodeEntry) {
            CodeEntryView()
        }
        .sheet(isPresented: $showNameCollection) {
            NameCollectionView()
        }
        .interactiveDismissDisabled() // Prevent dismissing by swiping
    }

    private func purchaseIndividualAccess() {
        guard !purchaseInProgress else { return }

        purchaseInProgress = true

        // Simulate in-app purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // In real app, this would be actual StoreKit purchase
            accessControl.currentUserTier = .basicPaid
            purchaseInProgress = false

            // Show name collection after successful purchase
            showNameCollection = true

            // Generate friend codes
            accessControl.checkAndGenerateFriendCodes()

            dismiss()
        }
    }

    private func restorePurchases() {
        // In real app, this would restore previous purchases via StoreKit
        print("Restoring purchases...")
    }
}

// MARK: - Supporting Views

struct PaywallOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let buttonText: String
    let buttonColor: Color
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(buttonColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange)
                                .cornerRadius(8)
                        }
                    }

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button(buttonText) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonColor)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRecommended ? .orange : .clear, lineWidth: 2)
        )
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Name Collection Integration

extension NameCollectionView {
    init(isFromPurchase: Bool = false) {
        // Can be enhanced to show different messaging based on context
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}