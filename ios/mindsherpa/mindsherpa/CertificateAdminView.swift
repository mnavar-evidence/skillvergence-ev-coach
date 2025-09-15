//
//  CertificateAdminView.swift
//  mindsherpa
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

// MARK: - Certificate Admin Interface

struct CertificateAdminView: View {
    @StateObject private var certificateManager = CertificateManager.shared
    @State private var selectedTab: AdminTab = .pending
    @State private var selectedCertificate: SkillvergenceCertificate?
    @State private var showingCertificateDetail = false
    @State private var showingApprovalDialog = false
    @State private var showingRejectionDialog = false
    @State private var adminNotes = ""
    @State private var rejectionReason = ""
    
    enum AdminTab: String, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case issued = "Issued"
        case all = "All"
        
        var systemImage: String {
            switch self {
            case .pending: return "clock.badge.exclamationmark"
            case .approved: return "checkmark.seal"
            case .issued: return "mail.and.text.magnifyingglass"
            case .all: return "list.bullet.clipboard"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                adminTabBar
                
                // Certificate List
                certificateList
            }
            .navigationTitle("Certificate Admin")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate Test") {
                        generateTestCertificate()
                    }
                    .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingCertificateDetail) {
            if let certificate = selectedCertificate {
                CertificateDetailView(
                    certificate: certificate,
                    onApprove: { cert, notes in
                        certificateManager.approveCertificate(cert, adminNotes: notes)
                        showingCertificateDetail = false
                    },
                    onReject: { cert, reason in
                        certificateManager.rejectCertificate(cert, reason: reason)
                        showingCertificateDetail = false
                    },
                    onIssue: { cert in
                        Task {
                            await certificateManager.issueCertificate(cert)
                            showingCertificateDetail = false
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Admin Tab Bar
    
    private var adminTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 16))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        // Badge with count
                        if certificateCount(for: tab) > 0 {
                            Text("\(certificateCount(for: tab))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(selectedTab == tab ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == tab ? Color.blue : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray6))
    }
    
    private func certificateCount(for tab: AdminTab) -> Int {
        switch tab {
        case .pending: return certificateManager.pendingCertificates.count
        case .approved: return certificateManager.approvedCertificates.count
        case .issued: return certificateManager.issuedCertificates.count
        case .all: return certificateManager.allCertificates.count
        }
    }
    
    // MARK: - Certificate List
    
    private var certificateList: some View {
        List {
            ForEach(certificatesForSelectedTab) { certificate in
                CertificateRowView(certificate: certificate) {
                    selectedCertificate = certificate
                    showingCertificateDetail = true
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Refresh certificates (in real app, would fetch from server)
        }
    }
    
    private var certificatesForSelectedTab: [SkillvergenceCertificate] {
        switch selectedTab {
        case .pending: return certificateManager.pendingCertificates
        case .approved: return certificateManager.approvedCertificates
        case .issued: return certificateManager.issuedCertificates
        case .all: return certificateManager.allCertificates
        }
    }
    
    // MARK: - Test Certificate Generation
    
    private func generateTestCertificate() {
        let testUser = UserProfile(
            id: "test_user_\(Int.random(in: 1000...9999))",
            fullName: "Jane Doe",
            email: "jane.doe@example.com",
            profileImage: nil
        )
        
        let testCourse = AdvancedCourse(
            id: "test_course",
            title: "Advanced Battery Management Systems",
            description: "Comprehensive training on battery systems",
            prerequisiteCourseId: "basic_course",
            muxPlaybackId: "test",
            estimatedHours: 8.5,
            certificateType: .batterySystemsExpert,
            xpReward: 500,
            skillLevel: .expert
        )
        
        let testProgress = AdvancedCourseProgress(
            courseId: "test_course",
            watchedSeconds: 30600, // 8.5 hours
            totalDuration: 30600,
            completed: true,
            certificateEarned: true,
            completedAt: Date(),
            certificateIssuedAt: nil
        )
        
        certificateManager.generateCertificate(
            for: testUser,
            course: testCourse,
            completionData: testProgress
        )
    }
}

// MARK: - Certificate Row View

struct CertificateRowView: View {
    let certificate: SkillvergenceCertificate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Header with status and certificate type
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: certificate.certificateType.badgeIcon)
                            .foregroundColor(.blue)
                        
                        Text(certificate.certificateType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(certificate.status.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(certificate.status.color)
                        .cornerRadius(12)
                }
                
                // Student and course info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Student:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(certificate.userFullName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(certificate.skillLevel.displayName)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Course:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(certificate.courseTitle)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Completed:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(certificate.completionDate, style: .date)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", certificate.totalWatchedHours))h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let score = certificate.finalScore {
                            Text("• \(Int(score))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Certificate number
                HStack {
                    Text("Certificate #\(certificate.certificateNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if certificate.status == .issued, let issuedDate = certificate.issuedDate {
                        Text("Issued \(issuedDate, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Certificate Detail View

struct CertificateDetailView: View {
    let certificate: SkillvergenceCertificate
    let onApprove: (SkillvergenceCertificate, String?) -> Void
    let onReject: (SkillvergenceCertificate, String) -> Void
    let onIssue: (SkillvergenceCertificate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var adminNotes = ""
    @State private var rejectionReason = ""
    @State private var showingApprovalDialog = false
    @State private var showingRejectionDialog = false
    @StateObject private var certificateManager = CertificateManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Certificate Preview
                    CertificateTemplateView(certificate: certificate, size: .standard)
                        .scaleEffect(0.8)
                    
                    // Certificate Details
                    certificateDetailsSection
                    
                    // Admin Actions
                    if certificate.status == .pendingApproval {
                        adminActionsSection
                    } else if certificate.status == .approved {
                        issueActionSection
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Certificate Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Approve Certificate", isPresented: $showingApprovalDialog) {
            TextField("Admin notes (optional)", text: $adminNotes)
            Button("Approve") {
                onApprove(certificate, adminNotes.isEmpty ? nil : adminNotes)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Approve this certificate for \(certificate.userFullName)?")
        }
        .alert("Reject Certificate", isPresented: $showingRejectionDialog) {
            TextField("Rejection reason", text: $rejectionReason)
            Button("Reject", role: .destructive) {
                onReject(certificate, rejectionReason)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Why are you rejecting this certificate?")
        }
    }
    
    private var certificateDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certificate Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Student", value: certificate.userFullName)
                DetailRow(label: "Email", value: certificate.userEmail)
                DetailRow(label: "Course", value: certificate.courseTitle)
                DetailRow(label: "Certificate Type", value: certificate.certificateType.displayName)
                DetailRow(label: "Skill Level", value: certificate.skillLevel.displayName)
                DetailRow(label: "Completion Date", value: DateFormatter.longDate.string(from: certificate.completionDate))
                DetailRow(label: "Training Hours", value: "\(String(format: "%.1f", certificate.totalWatchedHours)) hours")
                
                if let score = certificate.finalScore {
                    DetailRow(label: "Final Score", value: "\(Int(score))%")
                }
                
                DetailRow(label: "Certificate Number", value: certificate.certificateNumber)
                DetailRow(label: "Verification Code", value: certificate.credentialVerificationCode)
                DetailRow(label: "Status", value: certificate.status.displayName)
                
                if let notes = certificate.adminNotes {
                    DetailRow(label: "Admin Notes", value: notes)
                }
                
                if let issuedDate = certificate.issuedDate {
                    DetailRow(label: "Issued Date", value: DateFormatter.longDate.string(from: issuedDate))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var adminActionsSection: some View {
        VStack(spacing: 12) {
            Text("Admin Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                Button("Reject") {
                    showingRejectionDialog = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button("Approve") {
                    showingApprovalDialog = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var issueActionSection: some View {
        VStack(spacing: 12) {
            Text("Issue Certificate")
                .font(.headline)
            
            Button("Send Certificate Email") {
                onIssue(certificate)
            }
            .buttonStyle(.borderedProminent)
            .disabled(certificateManager.isSendingEmail)
            
            if certificateManager.isSendingEmail {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sending certificate email...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - User Profile Extension (if not exists)

struct UserProfile: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    let profileImage: String?
}

// MARK: - Preview

#Preview {
    CertificateAdminView()
}