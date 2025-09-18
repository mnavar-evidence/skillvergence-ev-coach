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
    @State private var selectedTab: CertificateTab = .all

    enum CertificateTab: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
    }

    var filteredCertificates: [SimpleCertificate] {
        let certificates = viewModel.certificates.map { apiCert in
            SimpleCertificate(
                id: apiCert.id,
                courseTitle: apiCert.courseTitle,
                studentName: apiCert.studentName,
                completedDate: apiCert.completedDate,
                status: apiCert.status
            )
        }

        switch selectedTab {
        case .all:
            return certificates
        case .pending:
            return certificates.filter { $0.status == "pending" }
        case .approved:
            return certificates.filter { $0.status == "approved" }
        }
    }

    var pendingCount: Int {
        viewModel.certificates.filter { $0.status == "pending" }.count
    }

    var approvedCount: Int {
        viewModel.certificates.filter { $0.status == "approved" }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Stats
            headerSection

            // Filter Tabs
            filterTabsSection

            // Certificate List
            certificateListSection
        }
        .navigationTitle("Certificates")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadClassData()
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Pending Certificates Card
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.badge")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(pendingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("Pending")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            // Approved Certificates Card
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(approvedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Approved")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var filterTabsSection: some View {
        HStack(spacing: 8) {
            ForEach(CertificateTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ?
                                      LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .top, endPoint: .bottom) :
                                      LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                                )
                        )
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .shadow(color: selectedTab == tab ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var certificateListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredCertificates.isEmpty {
                    EmptyStateView(filter: getCertificateFilter(for: selectedTab))
                        .padding(.top, 40)
                } else {
                    ForEach(filteredCertificates, id: \.id) { certificate in
                        CertificateRowView(
                            certificate: certificate,
                            onApprove: { approveCertificate(certificate.id) },
                            onReject: { rejectCertificate(certificate.id) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .refreshable {
            viewModel.refreshData()
        }
    }

    private func approveCertificate(_ certificateId: String) {
        Task {
            await performCertificateAction(certificateId: certificateId, action: "approve")
        }
    }

    private func rejectCertificate(_ certificateId: String) {
        Task {
            await performCertificateAction(certificateId: certificateId, action: "reject")
        }
    }

    private func performCertificateAction(certificateId: String, action: String) async {
        do {
            let _ = try await TeacherAPIService.shared.approveCertificate(
                certId: certificateId,
                action: action,
                teacherId: "teacher-djohnson"
            )

            // Reload certificates to reflect changes
            await MainActor.run {
                viewModel.refreshData()
            }
        } catch {
            print("Error performing certificate action: \(error)")
        }
    }

    private func getCertificateFilter(for tab: CertificateTab) -> MyCertificatesView.CertificateFilter {
        switch tab {
        case .all:
            return .all
        case .pending:
            return .pending
        case .approved:
            return .issued
        }
    }
}

// MARK: - Supporting Views

struct SimpleCertificate {
    let id: String
    let courseTitle: String
    let studentName: String
    let completedDate: String
    let status: String
}

struct CertificateRowView: View {
    let certificate: SimpleCertificate
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Certificate Header with Icon and Status
            HStack(spacing: 12) {
                // Certificate Icon
                Image(systemName: "award.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.yellow.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.courseTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(certificate.studentName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status Badge
                statusBadge
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Action Buttons for Pending Certificates
            if certificate.status == "pending" {
                Divider()
                    .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    Button {
                        onReject()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.red.opacity(0.8), .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(10)
                    }

                    Button {
                        onApprove()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .green],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(certificateBorderColor, lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 4)
    }

    private var statusBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: statusIconName)
                .font(.title3)
                .foregroundColor(statusColor)

            Text(certificate.status.capitalized)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 70, height: 70)
        .background(
            Circle()
                .fill(statusColor.opacity(0.1))
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                )
        )
    }

    private var certificateBorderColor: Color {
        switch certificate.status {
        case "pending":
            return .orange.opacity(0.3)
        case "approved":
            return .green.opacity(0.3)
        default:
            return .gray.opacity(0.3)
        }
    }

    private var statusIconName: String {
        switch certificate.status {
        case "pending":
            return "clock.fill"
        case "approved":
            return "checkmark.seal.fill"
        default:
            return "xmark.seal.fill"
        }
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: certificate.completedDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd"
            return displayFormatter.string(from: date)
        }
        return "Recent"
    }

    private var statusColor: Color {
        switch certificate.status {
        case "pending":
            return .orange
        case "approved":
            return .green
        default:
            return .red
        }
    }
}


// MARK: - Preview

#Preview {
    NavigationView {
        CertificateManagementView(viewModel: TeacherViewModel.preview)
    }
}