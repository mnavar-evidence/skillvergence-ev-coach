//
//  CertificateModels.swift
//  mindsherpa
//
//  Created by Claude on 9/10/25.
//

import Foundation
import SwiftUI

// MARK: - Certificate Models

struct SkillvergenceCertificate: Identifiable, Codable {
    let id: String
    let userId: String
    let userFullName: String
    let userEmail: String
    let courseId: String
    let courseTitle: String
    let certificateType: AdvancedCertificateType
    let skillLevel: AdvancedSkillLevel
    let completionDate: Date
    let issuedDate: Date?
    let certificateNumber: String
    let status: CertificateStatus
    let adminNotes: String?
    
    // Certificate metadata
    let totalWatchedHours: Double
    let finalScore: Double? // If quiz/assessment exists
    let instructorName: String
    let credentialVerificationCode: String
    
    init(
        userId: String,
        userFullName: String,
        userEmail: String,
        courseId: String,
        courseTitle: String,
        certificateType: AdvancedCertificateType,
        skillLevel: AdvancedSkillLevel,
        completionDate: Date,
        totalWatchedHours: Double,
        finalScore: Double? = nil,
        instructorName: String = "Dr. Sarah Chen",
        status: CertificateStatus = .pendingApproval
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.userFullName = userFullName
        self.userEmail = userEmail
        self.courseId = courseId
        self.courseTitle = courseTitle
        self.certificateType = certificateType
        self.skillLevel = skillLevel
        self.completionDate = completionDate
        self.issuedDate = nil
        self.certificateNumber = CertificateNumberGenerator.generate(type: certificateType)
        self.status = status
        self.adminNotes = nil
        self.totalWatchedHours = totalWatchedHours
        self.finalScore = finalScore
        self.instructorName = instructorName
        self.credentialVerificationCode = UUID().uuidString.prefix(8).uppercased() + String(format: "%04d", Int.random(in: 1000...9999))
    }
}

enum CertificateStatus: String, CaseIterable, Codable {
    case pendingApproval = "pending_approval"
    case approved = "approved"
    case issued = "issued"
    case rejected = "rejected"
    case revoked = "revoked"
    
    var displayName: String {
        switch self {
        case .pendingApproval: return "Pending Approval"
        case .approved: return "Approved"
        case .issued: return "Issued"
        case .rejected: return "Rejected"
        case .revoked: return "Revoked"
        }
    }
    
    var color: Color {
        switch self {
        case .pendingApproval: return .orange
        case .approved: return .green
        case .issued: return .blue
        case .rejected: return .red
        case .revoked: return .gray
        }
    }
}

// MARK: - Certificate Number Generation

struct CertificateNumberGenerator {
    static func generate(type: AdvancedCertificateType) -> String {
        let prefix = type.certificatePrefix
        let year = Calendar.current.component(.year, from: Date())
        let randomSuffix = String(format: "%06d", Int.random(in: 100000...999999))
        return "SKV-\(prefix)-\(year)-\(randomSuffix)"
    }
}

extension AdvancedCertificateType {
    var certificatePrefix: String {
        switch self {
        case .evFundamentalsAdvanced: return "EVF"
        case .batterySystemsExpert: return "BSE"
        case .chargingInfrastructureSpecialist: return "CIS"
        case .motorControlAdvanced: return "MCA"
        case .diagnosticsExpert: return "EDX"
        }
    }
    
    var certificateDescription: String {
        switch self {
        case .evFundamentalsAdvanced:
            return "This certificate validates comprehensive knowledge of advanced electric vehicle fundamentals, including powertrain systems, energy management, and performance optimization."
        case .batterySystemsExpert:
            return "This certificate validates expertise in battery technology, thermal management, state estimation, and advanced battery management systems for electric vehicles."
        case .chargingInfrastructureSpecialist:
            return "This certificate validates specialized knowledge of EV charging infrastructure, including AC/DC charging, grid integration, and charging network management."
        case .motorControlAdvanced:
            return "This certificate validates advanced skills in electric motor control, inverter technology, and drive system optimization for electric vehicles."
        case .diagnosticsExpert:
            return "This certificate validates expert-level diagnostic capabilities for electric vehicle systems, troubleshooting, and advanced repair techniques."
        }
    }
}

// MARK: - Certificate Template Data

struct CertificateTemplateData {
    let certificate: SkillvergenceCertificate
    let companyLogo: String = "skillvergence-logo"
    let backgroundColor: Color = Color(red: 0.97, green: 0.98, blue: 1.0) // Light blue tint
    let accentColor: Color = .blue
    let borderColor: Color = Color(red: 0.2, green: 0.4, blue: 0.8)
    
    var formattedCompletionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: certificate.completionDate)
    }
    
    var formattedIssuedDate: String {
        guard let issuedDate = certificate.issuedDate else { return "Pending" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: issuedDate)
    }
    
    var credentialVerificationURL: String {
        return "https://skillvergence.com/verify/\(certificate.credentialVerificationCode)"
    }
}