//
//  StudentCertificateManager.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import Foundation
import SwiftUI

// MARK: - Student Certificate Manager

@MainActor
class StudentCertificateManager: ObservableObject {
    static let shared = StudentCertificateManager()

    @Published var myCertificates: [SkillvergenceCertificate] = []
    @Published var isGeneratingCertificate = false

    private let userDefaults = UserDefaults.standard
    private let certificatesKey = "my_certificates"

    private init() {
        loadCertificates()
    }

    // MARK: - Certificate Generation (Student Side)

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

        // Add to student's certificates (will be pending approval on backend)
        myCertificates.append(certificate)

        // Save to local storage
        saveCertificates()

        isGeneratingCertificate = false

        print("📜 Certificate generated for \(user.fullName): \(certificate.certificateNumber)")
    }

    private func calculateFinalScore(for progress: AdvancedCourseProgress) -> Double? {
        // Calculate score based on completion and engagement
        let completionRatio = progress.watchedSeconds / progress.totalDuration
        return min(100, completionRatio * 100)
    }

    // MARK: - View My Certificates

    func getMyCertificates() -> [SkillvergenceCertificate] {
        return myCertificates
    }

    func getCertificatesByStatus(_ status: CertificateStatus) -> [SkillvergenceCertificate] {
        return myCertificates.filter { $0.status == status }
    }

    func getPendingCertificates() -> [SkillvergenceCertificate] {
        return myCertificates.filter { $0.status == .pendingApproval }
    }

    func getIssuedCertificates() -> [SkillvergenceCertificate] {
        return myCertificates.filter { $0.status == .issued }
    }

    // MARK: - Certificate Status Updates (from backend)

    func updateCertificateStatus(_ certificateId: String, newStatus: CertificateStatus) {
        guard let index = myCertificates.firstIndex(where: { $0.id == certificateId }) else { return }

        var updatedCertificate = myCertificates[index]
        updatedCertificate = SkillvergenceCertificate(
            id: updatedCertificate.id,
            userId: updatedCertificate.userId,
            userFullName: updatedCertificate.userFullName,
            userEmail: updatedCertificate.userEmail,
            courseId: updatedCertificate.courseId,
            courseTitle: updatedCertificate.courseTitle,
            certificateType: updatedCertificate.certificateType,
            skillLevel: updatedCertificate.skillLevel,
            completionDate: updatedCertificate.completionDate,
            issuedDate: newStatus == .issued ? Date() : updatedCertificate.issuedDate,
            certificateNumber: updatedCertificate.certificateNumber,
            status: newStatus,
            adminNotes: updatedCertificate.adminNotes,
            totalWatchedHours: updatedCertificate.totalWatchedHours,
            finalScore: updatedCertificate.finalScore,
            instructorName: updatedCertificate.instructorName,
            credentialVerificationCode: updatedCertificate.credentialVerificationCode
        )

        myCertificates[index] = updatedCertificate
        saveCertificates()

        print("📋 Certificate status updated: \(certificateId) -> \(newStatus)")
    }

    // MARK: - Data Persistence

    private func saveCertificates() {
        do {
            let data = try JSONEncoder().encode(myCertificates)
            userDefaults.set(data, forKey: certificatesKey)
        } catch {
            print("Error saving certificates: \(error)")
        }
    }

    private func loadCertificates() {
        guard let data = userDefaults.data(forKey: certificatesKey) else { return }

        do {
            myCertificates = try JSONDecoder().decode([SkillvergenceCertificate].self, from: data)
        } catch {
            print("Error loading certificates: \(error)")
        }
    }

    // MARK: - Utility Methods

    func hasCertificateForCourse(_ courseId: String) -> Bool {
        return myCertificates.contains { $0.courseId == courseId }
    }

    func getCertificateForCourse(_ courseId: String) -> SkillvergenceCertificate? {
        return myCertificates.first { $0.courseId == courseId }
    }
}