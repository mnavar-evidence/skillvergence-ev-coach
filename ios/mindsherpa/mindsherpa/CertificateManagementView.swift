//
//  CertificateManagementView.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI

// MARK: - Certificate Management View

struct CertificateManagementView: View {
    @ObservedObject var viewModel: TeacherViewModel
    @StateObject private var certificateManager = TeacherCertificateManager()
    @State private var selectedStatus: CertificateStatus = .pendingApproval
    @State private var showingCertificateDetail = false
    @State private var selectedCertificate: SkillvergenceCertificate?

    var filteredCertificates: [SkillvergenceCertificate] {
        certificateManager.certificates.filter { $0.status == selectedStatus }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Status Tabs
            headerSection

            // Certificate List
            certificateListSection
        }
        .navigationTitle("Certificate Management")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            certificateManager.loadCertificates()
        }
        .sheet(isPresented: $showingCertificateDetail) {
            if let certificate = selectedCertificate {
                CertificateDetailView(
                    certificate: certificate,
                    certificateManager: certificateManager
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Summary Stats
            HStack(spacing: 20) {
                CertificateStatCard(
                    title: "Pending",
                    count: certificateManager.getCertificatesByStatus(.pendingApproval).count,
                    color: .orange
                )

                CertificateStatCard(
                    title: "Approved",
                    count: certificateManager.getCertificatesByStatus(.approved).count,
                    color: .green
                )

                CertificateStatCard(
                    title: "Issued",
                    count: certificateManager.getCertificatesByStatus(.issued).count,
                    color: .blue
                )

                CertificateStatCard(
                    title: "Rejected",
                    count: certificateManager.getCertificatesByStatus(.rejected).count,
                    color: .red
                )
            }

            // Status Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CertificateStatus.allCases, id: \.self) { status in
                        StatusTab(
                            status: status,
                            count: certificateManager.getCertificatesByStatus(status).count,
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = status
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Quick Actions
            HStack(spacing: 16) {
                Button("Approve All Pending") {
                    certificateManager.bulkApproveAllPending()
                }
                .buttonStyle(.borderedProminent)
                .disabled(certificateManager.getCertificatesByStatus(.pendingApproval).isEmpty)

                Button("Export Report") {
                    certificateManager.exportCertificateReport()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var certificateListSection: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredCertificates, id: \.id) { certificate in
                    CertificateRowView(certificate: certificate) {
                        selectedCertificate = certificate
                        showingCertificateDetail = true
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .refreshable {
            certificateManager.loadCertificates()
        }
    }
}

// MARK: - Supporting Views

struct CertificateStatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatusTab: View {
    let status: CertificateStatus
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? status.color : .gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct CertificateRowView: View {
    let certificate: SkillvergenceCertificate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Status Indicator
                Circle()
                    .fill(certificate.status.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(certificate.userFullName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(certificate.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(certificate.status.color.opacity(0.1))
                            .foregroundColor(certificate.status.color)
                            .cornerRadius(8)
                    }

                    Text(certificate.courseTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Label(certificate.certificateType.displayName, systemImage: certificate.certificateType.badgeIcon)
                            .font(.caption)
                            .foregroundColor(.blue)

                        Label("\(String(format: "%.1f", certificate.totalWatchedHours))h", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        if let score = certificate.finalScore {
                            Label("\(Int(score))%", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Text(RelativeDateTimeFormatter().localizedString(for: certificate.completionDate, relativeTo: Date()))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Certificate Detail View

struct CertificateDetailView: View {
    let certificate: SkillvergenceCertificate
    @ObservedObject var certificateManager: TeacherCertificateManager
    @Environment(\.dismiss) private var dismiss
    @State private var adminNotes = ""
    @State private var showingCertificatePreview = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Certificate Header
                    certificateHeaderSection

                    // Student Information
                    studentInfoSection

                    // Course Details
                    courseDetailsSection

                    // Certificate Preview
                    certificatePreviewSection

                    // Admin Actions
                    adminActionsSection
                }
                .padding()
            }
            .navigationTitle("Certificate Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    certificateManager.updateCertificateNotes(certificate.id, notes: adminNotes)
                    dismiss()
                }
            )
        }
        .onAppear {
            adminNotes = certificate.adminNotes ?? ""
        }
        .sheet(isPresented: $showingCertificatePreview) {
            CertificateTemplateView(certificate: certificate, size: .large)
        }
    }

    private var certificateHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: certificate.certificateType.badgeIcon)
                    .font(.largeTitle)
                    .foregroundColor(certificate.status.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.certificateType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Certificate #\(certificate.certificateNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(certificate.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(certificate.status.color.opacity(0.1))
                        .foregroundColor(certificate.status.color)
                        .cornerRadius(8)

                    Text("Completed \(RelativeDateTimeFormatter().localizedString(for: certificate.completionDate, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var studentInfoSection: some View {
        GroupBox("Student Information") {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Name", value: certificate.userFullName)
                InfoRow(label: "Email", value: certificate.userEmail)
                InfoRow(label: "User ID", value: certificate.userId)
                InfoRow(label: "Completion Date", value: DateFormatter.certificateLongDate.string(from: certificate.completionDate))
            }
        }
    }

    private var courseDetailsSection: some View {
        GroupBox("Course Details") {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Course", value: certificate.courseTitle)
                InfoRow(label: "Skill Level", value: certificate.skillLevel.displayName)
                InfoRow(label: "Watch Time", value: "\(String(format: "%.1f", certificate.totalWatchedHours)) hours")
                InfoRow(label: "Instructor", value: certificate.instructorName)

                if let score = certificate.finalScore {
                    InfoRow(label: "Final Score", value: "\(Int(score))%")
                }

                InfoRow(label: "Verification Code", value: certificate.credentialVerificationCode)
            }
        }
    }

    private var certificatePreviewSection: some View {
        GroupBox("Certificate Preview") {
            VStack(spacing: 16) {
                Button("View Full Certificate") {
                    showingCertificatePreview = true
                }
                .buttonStyle(.borderedProminent)

                // Mini preview thumbnail
                CertificateTemplateView(certificate: certificate, size: .standard)
                    .scaleEffect(0.3)
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    private var adminActionsSection: some View {
        GroupBox("Admin Actions") {
            VStack(spacing: 16) {
                // Admin Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Admin Notes")
                        .font(.headline)
                        .fontWeight(.medium)

                    TextEditor(text: $adminNotes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Action Buttons
                if certificate.status == .pendingApproval {
                    HStack(spacing: 16) {
                        Button("Approve") {
                            certificateManager.approveCertificate(certificate.id, adminNotes: adminNotes)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button("Reject") {
                            certificateManager.rejectCertificate(certificate.id, adminNotes: adminNotes)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                } else if certificate.status == .approved {
                    Button("Issue Certificate") {
                        certificateManager.issueCertificate(certificate.id, adminNotes: adminNotes)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Teacher Certificate Manager

@MainActor
class TeacherCertificateManager: ObservableObject {
    @Published var certificates: [SkillvergenceCertificate] = []
    @Published var isLoading = false

    func loadCertificates() {
        isLoading = true

        // Simulate loading certificates from backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.certificates = self.generateSampleCertificates()
            self.isLoading = false
        }
    }

    func getCertificatesByStatus(_ status: CertificateStatus) -> [SkillvergenceCertificate] {
        return certificates.filter { $0.status == status }
    }

    func approveCertificate(_ certificateId: String, adminNotes: String?) {
        updateCertificateStatus(certificateId, status: .approved, adminNotes: adminNotes)
    }

    func rejectCertificate(_ certificateId: String, adminNotes: String?) {
        updateCertificateStatus(certificateId, status: .rejected, adminNotes: adminNotes)
    }

    func issueCertificate(_ certificateId: String, adminNotes: String?) {
        updateCertificateStatus(certificateId, status: .issued, adminNotes: adminNotes)
    }

    func bulkApproveAllPending() {
        let pendingCertificates = getCertificatesByStatus(.pendingApproval)
        for certificate in pendingCertificates {
            approveCertificate(certificate.id, adminNotes: "Bulk approved by teacher")
        }
    }

    func updateCertificateNotes(_ certificateId: String, notes: String) {
        if let index = certificates.firstIndex(where: { $0.id == certificateId }) {
            // Note: This would normally update the backend
            print("Updated notes for certificate \(certificateId): \(notes)")
        }
    }

    func exportCertificateReport() {
        // Implementation for exporting certificate report
        print("Exporting certificate report...")
    }

    private func updateCertificateStatus(_ certificateId: String, status: CertificateStatus, adminNotes: String?) {
        if let index = certificates.firstIndex(where: { $0.id == certificateId }) {
            // Note: This would normally make an API call to update the backend
            print("Updated certificate \(certificateId) to status: \(status.displayName)")
            // Reload certificates to reflect changes
            loadCertificates()
        }
    }

    private func generateSampleCertificates() -> [SkillvergenceCertificate] {
        let sampleStudents = [
            ("Marcus Williams", "marcus.williams@student.fuhsd.net"),
            ("Emma Chen", "emma.chen@student.fuhsd.net"),
            ("Sofia Garcia", "sofia.garcia@student.fuhsd.net"),
            ("Ethan Thompson", "ethan.thompson@student.fuhsd.net"),
            ("Ava Martinez", "ava.martinez@student.fuhsd.net"),
            ("Noah Johnson", "noah.johnson@student.fuhsd.net"),
            ("Isabella Brown", "isabella.brown@student.fuhsd.net"),
            ("Liam Davis", "liam.davis@student.fuhsd.net")
        ]

        var certificates: [SkillvergenceCertificate] = []

        for (index, student) in sampleStudents.enumerated() {
            let status: CertificateStatus = {
                switch index % 4 {
                case 0: return .pendingApproval
                case 1: return .approved
                case 2: return .issued
                default: return .rejected
                }
            }()

            let certificateType: AdvancedCertificateType = {
                switch index % 5 {
                case 0: return .evFundamentalsAdvanced
                case 1: return .batterySystemsExpert
                case 2: return .chargingInfrastructureSpecialist
                case 3: return .motorControlAdvanced
                default: return .diagnosticsExpert
                }
            }()

            let certificate = SkillvergenceCertificate(
                userId: "student_\(index + 1)",
                userFullName: student.0,
                userEmail: student.1,
                courseId: "course_\(index % 5 + 1)",
                courseTitle: getCourseTitle(for: index % 5 + 1),
                certificateType: certificateType,
                skillLevel: .expert,
                completionDate: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date()) ?? Date(),
                totalWatchedHours: Double.random(in: 8...25),
                finalScore: Double.random(in: 75...100)
            )

            certificates.append(certificate)
        }

        return certificates.sorted { $0.completionDate > $1.completionDate }
    }

    private func getCourseTitle(for courseNumber: Int) -> String {
        switch courseNumber {
        case 1: return "High Voltage Safety Foundation"
        case 2: return "Electrical Fundamentals"
        case 3: return "Advanced Electrical Diagnostics"
        case 4: return "EV Charging Systems"
        case 5: return "Advanced EV Systems"
        default: return "Course \(courseNumber)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let certificateLongDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    NavigationView {
        CertificateManagementView(viewModel: TeacherViewModel.preview)
    }
}