//
//  CertificateTemplate.swift
//  mindsherpa
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

// MARK: - Certificate Template View

struct CertificateTemplateView: View {
    let templateData: CertificateTemplateData
    let size: CertificateSize
    
    init(certificate: SkillvergenceCertificate, size: CertificateSize = .standard) {
        self.templateData = CertificateTemplateData(certificate: certificate)
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(templateData.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(templateData.borderColor, lineWidth: size.borderWidth)
                )
            
            VStack(spacing: size.verticalSpacing) {
                // Header with Logo and Title
                headerSection
                
                // Certificate Title
                certificateTitleSection
                
                // Recipient Section
                recipientSection
                
                // Course Details
                courseDetailsSection
                
                // Completion Details
                completionDetailsSection
                
                Spacer()
                
                // Footer with Signatures and Verification
                footerSection
            }
            .padding(size.padding)
        }
        .frame(width: size.width, height: size.height)
        .background(Color.white)
    }
    
    // MARK: - Certificate Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Company Logo Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(templateData.accentColor.opacity(0.1))
                .frame(width: size.logoSize.width, height: size.logoSize.height)
                .overlay(
                    Text("WATTWORKS")
                        .font(.system(size: size.logoFontSize, weight: .bold))
                        .foregroundColor(templateData.accentColor)
                )
            
            Text("PROFESSIONAL CERTIFICATION")
                .font(.system(size: size.subtitleFontSize, weight: .medium))
                .foregroundColor(.gray)
                .tracking(2)
        }
    }
    
    private var certificateTitleSection: some View {
        VStack(spacing: 8) {
            Text("CERTIFICATE OF COMPLETION")
                .font(.system(size: size.titleFontSize, weight: .bold))
                .foregroundColor(templateData.borderColor)
                .tracking(1)
            
            Rectangle()
                .fill(templateData.accentColor)
                .frame(width: size.dividerWidth, height: 3)
        }
    }
    
    private var recipientSection: some View {
        VStack(spacing: 16) {
            Text("This is to certify that")
                .font(.system(size: size.bodyFontSize))
                .foregroundColor(.gray)
            
            Text(templateData.certificate.userFullName)
                .font(.system(size: size.nameFontSize, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(templateData.accentColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(templateData.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            
            Text("has successfully completed the requirements for")
                .font(.system(size: size.bodyFontSize))
                .foregroundColor(.gray)
        }
    }
    
    private var courseDetailsSection: some View {
        VStack(spacing: 12) {
            // Certificate Type Badge
            HStack {
                Image(systemName: templateData.certificate.certificateType.badgeIcon)
                    .font(.system(size: size.badgeIconSize))
                    .foregroundColor(templateData.accentColor)
                
                Text(templateData.certificate.certificateType.displayName)
                    .font(.system(size: size.courseTitleFontSize, weight: .bold))
                    .foregroundColor(templateData.borderColor)
                    .multilineTextAlignment(.center)
            }
            
            // Course Title
            Text(templateData.certificate.courseTitle)
                .font(.system(size: size.bodyFontSize, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Skill Level Badge
            Text(templateData.certificate.skillLevel.displayName)
                .font(.system(size: size.skillLevelFontSize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(templateData.accentColor)
                .cornerRadius(20)
        }
    }
    
    private var completionDetailsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 40) {
                VStack {
                    Text("Completion Date")
                        .font(.system(size: size.labelFontSize))
                        .foregroundColor(.gray)
                    Text(templateData.formattedCompletionDate)
                        .font(.system(size: size.bodyFontSize, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                VStack {
                    Text("Training Hours")
                        .font(.system(size: size.labelFontSize))
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", templateData.certificate.totalWatchedHours)) hrs")
                        .font(.system(size: size.bodyFontSize, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                if let score = templateData.certificate.finalScore {
                    VStack {
                        Text("Final Score")
                            .font(.system(size: size.labelFontSize))
                            .foregroundColor(.gray)
                        Text("\(Int(score))%")
                            .font(.system(size: size.bodyFontSize, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Certificate Description
            Text(templateData.certificate.certificateType.certificateDescription)
                .font(.system(size: size.descriptionFontSize))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            HStack(spacing: 60) {
                // Instructor Signature
                VStack(spacing: 8) {
                    Text("_________________________")
                        .foregroundColor(.gray)
                    Text(templateData.certificate.instructorName)
                        .font(.system(size: size.signatureFontSize, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Lead Instructor")
                        .font(.system(size: size.labelFontSize))
                        .foregroundColor(.gray)
                }
                
                // Certificate Authority
                VStack(spacing: 8) {
                    Text("_________________________")
                        .foregroundColor(.gray)
                    Text("WattWorks Academy")
                        .font(.system(size: size.signatureFontSize, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Certification Authority")
                        .font(.system(size: size.labelFontSize))
                        .foregroundColor(.gray)
                }
            }
            
            // Certificate Number and Verification
            VStack(spacing: 4) {
                Text("Certificate Number: \(templateData.certificate.certificateNumber)")
                    .font(.system(size: size.labelFontSize, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("Verification Code: \(templateData.certificate.credentialVerificationCode)")
                    .font(.system(size: size.labelFontSize, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("Verify at: \(templateData.credentialVerificationURL)")
                    .font(.system(size: size.labelFontSize - 1))
                    .foregroundColor(.blue)
                    .underline()
            }
        }
    }
}

// MARK: - Certificate Size Configurations

enum CertificateSize {
    case standard
    case large
    case print
    
    var width: CGFloat {
        switch self {
        case .standard: return 800
        case .large: return 1200
        case .print: return 1100 // 8.5x11 aspect ratio
        }
    }
    
    var height: CGFloat {
        switch self {
        case .standard: return 600
        case .large: return 900
        case .print: return 850
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .standard: return 40
        case .large: return 60
        case .print: return 50
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .standard: return 12
        case .large: return 16
        case .print: return 8
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard: return 2
        case .large: return 3
        case .print: return 2
        }
    }
    
    var titleFontSize: CGFloat {
        switch self {
        case .standard: return 28
        case .large: return 36
        case .print: return 32
        }
    }
    
    var nameFontSize: CGFloat {
        switch self {
        case .standard: return 32
        case .large: return 40
        case .print: return 36
        }
    }
    
    var courseTitleFontSize: CGFloat {
        switch self {
        case .standard: return 22
        case .large: return 28
        case .print: return 24
        }
    }
    
    var bodyFontSize: CGFloat {
        switch self {
        case .standard: return 16
        case .large: return 20
        case .print: return 18
        }
    }
    
    var labelFontSize: CGFloat {
        switch self {
        case .standard: return 12
        case .large: return 14
        case .print: return 13
        }
    }
    
    var subtitleFontSize: CGFloat {
        switch self {
        case .standard: return 14
        case .large: return 16
        case .print: return 15
        }
    }
    
    var skillLevelFontSize: CGFloat {
        switch self {
        case .standard: return 14
        case .large: return 16
        case .print: return 15
        }
    }
    
    var signatureFontSize: CGFloat {
        switch self {
        case .standard: return 16
        case .large: return 18
        case .print: return 17
        }
    }
    
    var descriptionFontSize: CGFloat {
        switch self {
        case .standard: return 13
        case .large: return 15
        case .print: return 14
        }
    }
    
    var logoFontSize: CGFloat {
        switch self {
        case .standard: return 18
        case .large: return 22
        case .print: return 20
        }
    }
    
    var logoSize: CGSize {
        switch self {
        case .standard: return CGSize(width: 180, height: 60)
        case .large: return CGSize(width: 220, height: 75)
        case .print: return CGSize(width: 200, height: 70)
        }
    }
    
    var badgeIconSize: CGFloat {
        switch self {
        case .standard: return 24
        case .large: return 30
        case .print: return 27
        }
    }
    
    var verticalSpacing: CGFloat {
        switch self {
        case .standard: return 20
        case .large: return 25
        case .print: return 22
        }
    }
    
    var dividerWidth: CGFloat {
        switch self {
        case .standard: return 100
        case .large: return 120
        case .print: return 110
        }
    }
}

// MARK: - Preview

#Preview("Certificate Template") {
    let sampleCertificate = SkillvergenceCertificate(
        userId: "user123",
        userFullName: "John Smith",
        userEmail: "john.smith@example.com",
        courseId: "course1",
        courseTitle: "Advanced Electric Vehicle Systems",
        certificateType: .evFundamentalsAdvanced,
        skillLevel: .expert,
        completionDate: Date(),
        totalWatchedHours: 12.5,
        finalScore: 95.0
    )
    
    CertificateTemplateView(certificate: sampleCertificate, size: .standard)
        .padding()
}