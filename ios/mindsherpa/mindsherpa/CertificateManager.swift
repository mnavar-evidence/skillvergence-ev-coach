//
//  CertificateManager.swift
//  mindsherpa
//
//  Created by Claude on 9/10/25.
//

import Foundation
import SwiftUI
import Combine
import MessageUI

// MARK: - Certificate Manager

@MainActor
class CertificateManager: ObservableObject {
    static let shared = CertificateManager()
    
    @Published var pendingCertificates: [SkillvergenceCertificate] = []
    @Published var approvedCertificates: [SkillvergenceCertificate] = []
    @Published var issuedCertificates: [SkillvergenceCertificate] = []
    @Published var allCertificates: [SkillvergenceCertificate] = []
    
    @Published var isGeneratingCertificate = false
    @Published var isSendingEmail = false
    
    private let userDefaults = UserDefaults.standard
    private let certificatesKey = "skillvergence_certificates"
    
    private init() {
        loadCertificates()
    }
    
    // MARK: - Certificate Generation
    
    func generateCertificate(
        for user: UserProfile,
        course: AdvancedCourse,
        completionData: AdvancedCourseProgress
    ) {
        isGeneratingCertificate = true
        
        let certificate = SkillvergenceCertificate(
            userId: user.id,
            userFullName: user.fullName,
            userEmail: user.email,
            courseId: course.id,
            courseTitle: course.title,
            certificateType: course.certificateType,
            skillLevel: course.skillLevel,
            completionDate: completionData.completedAt ?? Date(),
            totalWatchedHours: completionData.totalDuration / 3600, // Convert seconds to hours
            finalScore: calculateFinalScore(for: completionData)
        )
        
        // Add to pending certificates
        pendingCertificates.append(certificate)
        allCertificates.append(certificate)
        
        // Save to storage
        saveCertificates()
        
        isGeneratingCertificate = false
        
        print("📜 Certificate generated for \(user.fullName): \(certificate.certificateNumber)")
    }
    
    private func calculateFinalScore(for progress: AdvancedCourseProgress) -> Double? {
        // If there are quizzes or assessments, calculate score
        // For now, base it on completion percentage and watching behavior
        let completionRatio = progress.watchedSeconds / progress.totalDuration
        return min(100, completionRatio * 100)
    }
    
    // MARK: - Admin Approval Workflow
    
    func approveCertificate(_ certificate: SkillvergenceCertificate, adminNotes: String? = nil) {
        guard let index = pendingCertificates.firstIndex(where: { $0.id == certificate.id }) else { return }
        
        var updatedCertificate = certificate
        updatedCertificate = SkillvergenceCertificate(
            id: certificate.id,
            userId: certificate.userId,
            userFullName: certificate.userFullName,
            userEmail: certificate.userEmail,
            courseId: certificate.courseId,
            courseTitle: certificate.courseTitle,
            certificateType: certificate.certificateType,
            skillLevel: certificate.skillLevel,
            completionDate: certificate.completionDate,
            issuedDate: nil,
            certificateNumber: certificate.certificateNumber,
            status: .approved,
            adminNotes: adminNotes,
            totalWatchedHours: certificate.totalWatchedHours,
            finalScore: certificate.finalScore,
            instructorName: certificate.instructorName,
            credentialVerificationCode: certificate.credentialVerificationCode
        )
        
        // Move from pending to approved
        pendingCertificates.remove(at: index)
        approvedCertificates.append(updatedCertificate)
        
        // Update in all certificates
        if let allIndex = allCertificates.firstIndex(where: { $0.id == certificate.id }) {
            allCertificates[allIndex] = updatedCertificate
        }
        
        saveCertificates()
        
        print("✅ Certificate approved: \(certificate.certificateNumber)")
    }
    
    func rejectCertificate(_ certificate: SkillvergenceCertificate, reason: String) {
        guard let index = pendingCertificates.firstIndex(where: { $0.id == certificate.id }) else { return }
        
        var updatedCertificate = certificate
        updatedCertificate = SkillvergenceCertificate(
            id: certificate.id,
            userId: certificate.userId,
            userFullName: certificate.userFullName,
            userEmail: certificate.userEmail,
            courseId: certificate.courseId,
            courseTitle: certificate.courseTitle,
            certificateType: certificate.certificateType,
            skillLevel: certificate.skillLevel,
            completionDate: certificate.completionDate,
            issuedDate: nil,
            certificateNumber: certificate.certificateNumber,
            status: .rejected,
            adminNotes: reason,
            totalWatchedHours: certificate.totalWatchedHours,
            finalScore: certificate.finalScore,
            instructorName: certificate.instructorName,
            credentialVerificationCode: certificate.credentialVerificationCode
        )
        
        // Remove from pending and update in all certificates
        pendingCertificates.remove(at: index)
        if let allIndex = allCertificates.firstIndex(where: { $0.id == certificate.id }) {
            allCertificates[allIndex] = updatedCertificate
        }
        
        saveCertificates()
        
        print("❌ Certificate rejected: \(certificate.certificateNumber) - Reason: \(reason)")
    }
    
    // MARK: - Certificate Issuance & Email Delivery
    
    func issueCertificate(_ certificate: SkillvergenceCertificate) async {
        guard certificate.status == .approved else { return }
        
        isSendingEmail = true
        
        // Generate PDF certificate
        let pdfData = await generateCertificatePDF(certificate)
        
        // Update certificate status to issued
        var issuedCertificate = certificate
        issuedCertificate = SkillvergenceCertificate(
            id: certificate.id,
            userId: certificate.userId,
            userFullName: certificate.userFullName,
            userEmail: certificate.userEmail,
            courseId: certificate.courseId,
            courseTitle: certificate.courseTitle,
            certificateType: certificate.certificateType,
            skillLevel: certificate.skillLevel,
            completionDate: certificate.completionDate,
            issuedDate: Date(),
            certificateNumber: certificate.certificateNumber,
            status: .issued,
            adminNotes: certificate.adminNotes,
            totalWatchedHours: certificate.totalWatchedHours,
            finalScore: certificate.finalScore,
            instructorName: certificate.instructorName,
            credentialVerificationCode: certificate.credentialVerificationCode
        )
        
        // Move from approved to issued
        if let approvedIndex = approvedCertificates.firstIndex(where: { $0.id == certificate.id }) {
            approvedCertificates.remove(at: approvedIndex)
        }
        issuedCertificates.append(issuedCertificate)
        
        if let allIndex = allCertificates.firstIndex(where: { $0.id == certificate.id }) {
            allCertificates[allIndex] = issuedCertificate
        }
        
        saveCertificates()
        
        // Send email with certificate
        await sendCertificateEmail(issuedCertificate, pdfData: pdfData)
        
        isSendingEmail = false
        
        print("📧 Certificate issued and sent to \(certificate.userEmail)")
    }
    
    private func generateCertificatePDF(_ certificate: SkillvergenceCertificate) async -> Data {
        // This would generate a PDF from the SwiftUI certificate view
        // For now, return empty data as placeholder
        return Data()
    }
    
    private func sendCertificateEmail(_ certificate: SkillvergenceCertificate, pdfData: Data) async {
        let emailContent = generateCertificateEmailContent(certificate)
        
        // In a real implementation, this would use a service like:
        // - SendGrid
        // - AWS SES
        // - Firebase Functions with Nodemailer
        // - Custom email service
        
        print("📧 Sending certificate email to \(certificate.userEmail)")
        print("Subject: \(emailContent.subject)")
        print("Body: \(emailContent.body)")
        
        // Simulate email sending delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
    
    // MARK: - Email Content Generation
    
    private func generateCertificateEmailContent(_ certificate: SkillvergenceCertificate) -> (subject: String, body: String) {
        let subject = "🎓 Your Skillvergence Certificate: \(certificate.certificateType.displayName)"
        
        let body = """
        Dear \(certificate.userFullName),
        
        Congratulations! 🎉
        
        You have successfully completed the \(certificate.courseTitle) course and earned your **\(certificate.certificateType.displayName)** certificate.
        
        **Certificate Details:**
        • Certificate Number: \(certificate.certificateNumber)
        • Completion Date: \(DateFormatter.longDate.string(from: certificate.completionDate))
        • Training Hours: \(String(format: "%.1f", certificate.totalWatchedHours)) hours
        • Skill Level: \(certificate.skillLevel.displayName)
        • Verification Code: \(certificate.credentialVerificationCode)
        
        Your certificate is attached to this email as a PDF. You can also verify its authenticity at:
        https://skillvergence.com/verify/\(certificate.credentialVerificationCode)
        
        **What's Next?**
        • Add this certificate to your LinkedIn profile
        • Share your achievement with your network
        • Continue your learning journey with more advanced courses
        
        Thank you for choosing Skillvergence for your professional development. We're proud of your accomplishment!
        
        Best regards,
        The Skillvergence Team
        
        ---
        
        **About Your Certificate:**
        \(certificate.certificateType.certificateDescription)
        
        If you have any questions about your certificate, please contact us at support@skillvergence.com.
        """
        
        return (subject, body)
    }
    
    // MARK: - Data Persistence
    
    private func saveCertificates() {
        do {
            let data = try JSONEncoder().encode(allCertificates)
            userDefaults.set(data, forKey: certificatesKey)
        } catch {
            print("Error saving certificates: \(error)")
        }
    }
    
    private func loadCertificates() {
        guard let data = userDefaults.data(forKey: certificatesKey) else { return }
        
        do {
            let certificates = try JSONDecoder().decode([SkillvergenceCertificate].self, from: data)
            allCertificates = certificates
            
            // Organize by status
            pendingCertificates = certificates.filter { $0.status == .pendingApproval }
            approvedCertificates = certificates.filter { $0.status == .approved }
            issuedCertificates = certificates.filter { $0.status == .issued }
        } catch {
            print("Error loading certificates: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func certificatesForUser(_ userId: String) -> [SkillvergenceCertificate] {
        return allCertificates.filter { $0.userId == userId }
    }
    
    func certificatesByStatus(_ status: CertificateStatus) -> [SkillvergenceCertificate] {
        return allCertificates.filter { $0.status == status }
    }
}

// MARK: - Extensions

extension SkillvergenceCertificate {
    init(
        id: String,
        userId: String,
        userFullName: String,
        userEmail: String,
        courseId: String,
        courseTitle: String,
        certificateType: AdvancedCertificateType,
        skillLevel: AdvancedSkillLevel,
        completionDate: Date,
        issuedDate: Date?,
        certificateNumber: String,
        status: CertificateStatus,
        adminNotes: String?,
        totalWatchedHours: Double,
        finalScore: Double?,
        instructorName: String,
        credentialVerificationCode: String
    ) {
        self.id = id
        self.userId = userId
        self.userFullName = userFullName
        self.userEmail = userEmail
        self.courseId = courseId
        self.courseTitle = courseTitle
        self.certificateType = certificateType
        self.skillLevel = skillLevel
        self.completionDate = completionDate
        self.issuedDate = issuedDate
        self.certificateNumber = certificateNumber
        self.status = status
        self.adminNotes = adminNotes
        self.totalWatchedHours = totalWatchedHours
        self.finalScore = finalScore
        self.instructorName = instructorName
        self.credentialVerificationCode = credentialVerificationCode
    }
}

extension DateFormatter {
    static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}