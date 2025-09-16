//
//  MyCertificatesView.swift
//  mindsherpa
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

// MARK: - My Certificates View (User-Facing)

struct MyCertificatesView: View {
    @StateObject private var certificateManager = StudentCertificateManager.shared
    @State private var selectedCertificate: SkillvergenceCertificate?
    @State private var showingCertificateDetail = false
    @State private var selectedFilter: CertificateFilter = .all
    
    // Mock current user ID - replace with your auth system
    private let currentUserId = "current_user"
    
    enum CertificateFilter: String, CaseIterable {
        case all = "All"
        case issued = "Earned"
        case pending = "In Review"
        case inProgress = "In Progress"
        
        var systemImage: String {
            switch self {
            case .all: return "graduationcap"
            case .issued: return "checkmark.seal.fill"
            case .pending: return "clock.badge"
            case .inProgress: return "progress.indicator"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Stats
                certificateStatsHeader
                
                // Filter Tabs
                filterTabBar
                
                // Certificate Grid/List
                certificateContent
            }
            .navigationTitle("My Certificates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // In real app, would refresh from server
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingCertificateDetail) {
            if let certificate = selectedCertificate {
                UserCertificateDetailView(certificate: certificate)
            }
        }
        .onAppear {
            generateSampleCertificatesIfNeeded()
        }
    }
    
    // MARK: - Certificate Stats Header
    
    private var certificateStatsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Total Certificates
                StatCard(
                    title: "Total",
                    value: "\(userCertificates.count)",
                    icon: "graduationcap.fill",
                    color: .blue
                )
                
                // Issued Certificates
                StatCard(
                    title: "Earned",
                    value: "\(issuedCertificates.count)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
                
                // Pending Certificates
                StatCard(
                    title: "Pending",
                    value: "\(pendingCertificates.count)",
                    icon: "clock.badge",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Filter Tab Bar
    
    private var filterTabBar: some View {
        HStack(spacing: 0) {
            ForEach(CertificateFilter.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.systemImage)
                                .font(.system(size: 16))
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedFilter == filter ? .white : .gray)
                        
                        // Badge with count
                        if certificateCount(for: filter) > 0 {
                            Text("\(certificateCount(for: filter))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(selectedFilter == filter ? .white : .gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(selectedFilter == filter ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedFilter == filter ? Color.blue : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray6))
    }
    
    private func certificateCount(for filter: CertificateFilter) -> Int {
        switch filter {
        case .all: return userCertificates.count
        case .issued: return issuedCertificates.count
        case .pending: return pendingCertificates.count
        case .inProgress: return 0 // Could be courses in progress
        }
    }
    
    // MARK: - Certificate Content
    
    private var certificateContent: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredCertificates) { certificate in
                    CertificateCard(certificate: certificate) {
                        selectedCertificate = certificate
                        showingCertificateDetail = true
                    }
                }
            }
            .padding()
            
            if filteredCertificates.isEmpty {
                EmptyStateView(filter: selectedFilter)
                    .padding(.top, 50)
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
    
    // MARK: - Computed Properties
    
    private var userCertificates: [SkillvergenceCertificate] {
        certificateManager.getMyCertificates()
    }
    
    private var issuedCertificates: [SkillvergenceCertificate] {
        userCertificates.filter { $0.status == .issued }
    }
    
    private var pendingCertificates: [SkillvergenceCertificate] {
        userCertificates.filter { $0.status == .pendingApproval || $0.status == .approved }
    }
    
    private var filteredCertificates: [SkillvergenceCertificate] {
        switch selectedFilter {
        case .all: return userCertificates
        case .issued: return issuedCertificates
        case .pending: return pendingCertificates
        case .inProgress: return [] // Could show courses in progress
        }
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleCertificatesIfNeeded() {
        // Generate sample certificates if none exist for demo purposes
        if userCertificates.isEmpty {
            let sampleCertificates = [
                createSampleCertificate(
                    type: .evFundamentalsAdvanced,
                    title: "Advanced EV Fundamentals",
                    status: .issued,
                    completionDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                    hours: 12.5,
                    score: 94
                ),
                createSampleCertificate(
                    type: .batterySystemsExpert,
                    title: "Battery Systems Expert Training",
                    status: .pendingApproval,
                    completionDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                    hours: 8.0,
                    score: 89
                ),
                createSampleCertificate(
                    type: .chargingInfrastructureSpecialist,
                    title: "Charging Infrastructure Specialist",
                    status: .approved,
                    completionDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    hours: 15.5,
                    score: 96
                )
            ]
            
            // Add sample certificates to manager
            for certificate in sampleCertificates {
                certificateManager.myCertificates.append(certificate)
            }
        }
    }
    
    private func createSampleCertificate(
        type: AdvancedCertificateType,
        title: String,
        status: CertificateStatus,
        completionDate: Date,
        hours: Double,
        score: Double
    ) -> SkillvergenceCertificate {
        var certificate = SkillvergenceCertificate(
            userId: currentUserId,
            userFullName: "John Smith",
            userEmail: "john.smith@example.com",
            courseId: "course_\(type.rawValue)",
            courseTitle: title,
            certificateType: type,
            skillLevel: .expert,
            completionDate: completionDate,
            totalWatchedHours: hours,
            finalScore: score
        )
        
        // Update status and issued date if needed
        if status == .issued {
            certificate = SkillvergenceCertificate(
                id: certificate.id,
                userId: certificate.userId,
                userFullName: certificate.userFullName,
                userEmail: certificate.userEmail,
                courseId: certificate.courseId,
                courseTitle: certificate.courseTitle,
                certificateType: certificate.certificateType,
                skillLevel: certificate.skillLevel,
                completionDate: certificate.completionDate,
                issuedDate: completionDate.addingTimeInterval(86400 * 3), // 3 days later
                certificateNumber: certificate.certificateNumber,
                status: status,
                adminNotes: nil,
                totalWatchedHours: certificate.totalWatchedHours,
                finalScore: certificate.finalScore,
                instructorName: certificate.instructorName,
                credentialVerificationCode: certificate.credentialVerificationCode
            )
        }
        
        return certificate
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Certificate Card

struct CertificateCard: View {
    let certificate: SkillvergenceCertificate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Certificate Icon and Status
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(certificate.status.color.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: certificate.certificateType.badgeIcon)
                            .font(.title2)
                            .foregroundColor(certificate.status.color)
                    }
                    
                    // Status Badge
                    Text(certificate.status.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(certificate.status.color)
                        .cornerRadius(10)
                }
                
                // Certificate Info
                VStack(spacing: 6) {
                    Text(certificate.certificateType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(certificate.courseTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Completion Date
                    Text(certificate.completionDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Additional Info
                    HStack(spacing: 4) {
                        Text("\(String(format: "%.1f", certificate.totalWatchedHours))h")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let score = certificate.finalScore {
                            Text("• \(Int(score))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Certificate Number
                Text("#\(certificate.certificateNumber.suffix(6))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding()
            .frame(height: 220)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let filter: MyCertificatesView.CertificateFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if filter == .issued {
                Button("Browse Courses") {
                    // Navigate to courses
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all: return "No Certificates Yet"
        case .issued: return "No Certificates Earned"
        case .pending: return "No Certificates Pending"
        case .inProgress: return "No Courses in Progress"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "Complete advanced courses to earn professional certificates from Skillvergence."
        case .issued: return "You haven't earned any certificates yet. Complete advanced courses to get started!"
        case .pending: return "You don't have any certificates pending approval right now."
        case .inProgress: return "You don't have any courses in progress. Start learning to earn certificates!"
        }
    }
}

// MARK: - User Certificate Detail View

struct UserCertificateDetailView: View {
    let certificate: SkillvergenceCertificate
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Certificate Preview
                    CertificateTemplateView(certificate: certificate, size: .standard)
                        .scaleEffect(0.9)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // Certificate Actions
                    if certificate.status == .issued {
                        certificateActionsSection
                    } else {
                        certificateStatusSection
                    }
                    
                    // Certificate Details
                    certificateDetailsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [certificate.certificateNumber, "I earned a certificate from Skillvergence!"])
        }
    }
    
    private var certificateActionsSection: some View {
        VStack(spacing: 12) {
            Text("Certificate Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                Button("Download PDF") {
                    // Download PDF functionality
                    downloadCertificate()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("Share") {
                    showingShareSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("Verify") {
                    // Open verification URL
                    openVerificationURL()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var certificateStatusSection: some View {
        VStack(spacing: 12) {
            Text("Certificate Status")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(certificate.status.color)
                    Text(certificate.status.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusMessage: String {
        switch certificate.status {
        case .pendingApproval:
            return "Your certificate is under review by our certification team. You'll be notified once it's approved."
        case .approved:
            return "Your certificate has been approved and will be issued shortly. You'll receive it via email."
        case .rejected:
            return "Your certificate was rejected. Please contact support for more information."
        case .revoked:
            return "This certificate has been revoked. Please contact support for more information."
        case .issued:
            return "Your certificate has been issued and sent to your email address."
        }
    }
    
    private var certificateDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certificate Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Certificate Type", value: certificate.certificateType.displayName)
                DetailRow(label: "Course", value: certificate.courseTitle)
                DetailRow(label: "Skill Level", value: certificate.skillLevel.displayName)
                DetailRow(label: "Completion Date", value: DateFormatter.longDate.string(from: certificate.completionDate))
                DetailRow(label: "Training Hours", value: "\(String(format: "%.1f", certificate.totalWatchedHours)) hours")
                
                if let score = certificate.finalScore {
                    DetailRow(label: "Final Score", value: "\(Int(score))%")
                }
                
                DetailRow(label: "Certificate Number", value: certificate.certificateNumber)
                DetailRow(label: "Verification Code", value: certificate.credentialVerificationCode)
                
                if let issuedDate = certificate.issuedDate {
                    DetailRow(label: "Issue Date", value: DateFormatter.longDate.string(from: issuedDate))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func downloadCertificate() {
        // Implement PDF download functionality
        print("Downloading certificate PDF...")
    }
    
    private func openVerificationURL() {
        let urlString = "https://skillvergence.com/verify/\(certificate.credentialVerificationCode)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    MyCertificatesView()
}