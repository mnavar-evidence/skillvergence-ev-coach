//
//  TeacherAPIService.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import Foundation
import Combine

@MainActor
class TeacherAPIService: ObservableObject {
    static let shared = TeacherAPIService()

    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Use AppConfig for consistent URL management
        self.baseURL = AppConfig.apiURL
    }

    // MARK: - Teacher Authentication

    func validateTeacherCode(_ code: String, schoolId: String = "") async throws -> TeacherValidationResponse {
        let url = URL(string: "\(baseURL)/teacher/validate-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TeacherCodeRequest(code: code, schoolId: schoolId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeacherAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw TeacherAPIError.invalidCode
        } else if httpResponse.statusCode != 200 {
            throw TeacherAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(TeacherValidationResponse.self, from: data)
    }

    // MARK: - School Configuration

    func getSchoolConfig(schoolId: String) async throws -> SchoolConfigResponse {
        let url = URL(string: "\(baseURL)/teacher/school/\(schoolId)/config")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SchoolConfigResponse.self, from: data)
    }

    // MARK: - Student Management

    func getStudentRoster(schoolId: String, level: String? = nil, sortBy: String = "name", order: String = "asc") async throws -> StudentRosterResponse {
        var components = URLComponents(string: "\(baseURL)/teacher/school/\(schoolId)/students")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "order", value: order)
        ]

        if let level = level {
            queryItems.append(URLQueryItem(name: "level", value: level))
        }

        components.queryItems = queryItems

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(StudentRosterResponse.self, from: data)
    }

    func getStudentProgress(studentId: String) async throws -> StudentProgressResponse {
        let url = URL(string: "\(baseURL)/teacher/students/\(studentId)/progress")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StudentProgressResponse.self, from: data)
    }

    // MARK: - Certificate Management

    func getCertificates(schoolId: String, status: String = "all") async throws -> CertificatesResponse {
        let url = URL(string: "\(baseURL)/teacher/school/\(schoolId)/certificates?status=\(status)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CertificatesResponse.self, from: data)
    }

    func approveCertificate(certId: String, action: String, teacherId: String) async throws -> CertificateActionResponse {
        let url = URL(string: "\(baseURL)/teacher/certificates/\(certId)/approve")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CertificateActionRequest(action: action, teacherId: teacherId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CertificateActionResponse.self, from: data)
    }

    // MARK: - Code Management

    func getCodeUsage(schoolId: String) async throws -> CodeUsageResponse {
        let url = URL(string: "\(baseURL)/teacher/school/\(schoolId)/code-usage")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CodeUsageResponse.self, from: data)
    }

    func generateCodes(schoolId: String, type: String, count: Int) async throws -> CodeGenerationResponse {
        let url = URL(string: "\(baseURL)/teacher/school/\(schoolId)/generate-codes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CodeGenerationRequest(type: type, count: count)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CodeGenerationResponse.self, from: data)
    }
}

// MARK: - Data Models

struct TeacherCodeRequest: Codable {
    let code: String
    let schoolId: String
}

struct TeacherValidationResponse: Codable {
    let success: Bool
    let teacher: TeacherInfo?
    let error: String?

    // Computed property for backward compatibility
    var valid: Bool { success }
}

struct TeacherInfo: Codable {
    let id: String
    let name: String
    let email: String
    let school: String
    let schoolId: String
    let department: String?
    let program: String?
    let classCode: String?
}

struct SchoolInfo: Codable {
    let id: String
    let name: String
    let district: String
    let program: String
    let instructor: InstructorInfo
}

struct InstructorInfo: Codable {
    let id: String
    let name: String
    let email: String
    let department: String?
}

struct SchoolConfigResponse: Codable {
    let school: SchoolConfig
}

struct SchoolConfig: Codable {
    let id: String
    let name: String
    let district: String
    let program: String
    let instructor: InstructorInfo
    let xpThreshold: Int
    let bulkLicenses: Int
    let districtLicenses: Int
}

struct StudentRosterResponse: Codable {
    let students: [APIStudent]
    let summary: StudentSummary
}

struct APIStudent: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let courseLevel: String
    let totalXP: Int
    let currentLevel: Int
    let completedCourses: Int
    let lastActive: String
    let streak: Int
}

struct StudentSummary: Codable {
    let totalStudents: Int
    let activeToday: Int
    let avgXP: Int
    let totalCompletedCourses: Int
    let avgCompletionRate: Int
}

struct StudentProgressResponse: Codable {
    let student: APIStudent
    let courseProgress: [CourseProgress]
    let weeklyActivity: [WeeklyActivity]
    let achievements: [Achievement]
}

struct CourseProgress: Codable {
    let courseId: String
    let courseName: String
    let progress: Int
    let completedVideos: Int
    let totalVideos: Int
    let timeSpent: Int
}

struct WeeklyActivity: Codable {
    let week: String
    let xpEarned: Int
    let timeSpent: Int
}

struct Achievement: Codable {
    let title: String
    let earnedDate: String
}

struct CertificatesResponse: Codable {
    let certificates: [APICertificate]
    let summary: CertificateSummary
}

struct APICertificate: Codable, Identifiable {
    let id: String
    let studentId: String
    let studentName: String
    let courseTitle: String
    let completedDate: String
    let status: String
    let approvedBy: String?
    let approvedDate: String?
}

struct CertificateSummary: Codable {
    let total: Int
    let pending: Int
    let approved: Int
}

struct CertificateActionRequest: Codable {
    let action: String
    let teacherId: String
}

struct CertificateActionResponse: Codable {
    let success: Bool
    let certificate: APICertificate
}

struct CodeUsageResponse: Codable {
    let usage: CodeUsage
    let generatedCodes: GeneratedCodes
}

struct CodeUsage: Codable {
    let basicCodes: Int
    let premiumCodes: Int
    let friendCodes: Int
}

struct GeneratedCodes: Codable {
    let basic: [String]
    let premium: [String]
}

struct CodeGenerationRequest: Codable {
    let type: String
    let count: Int
}

struct CodeGenerationResponse: Codable {
    let success: Bool
    let codes: [String]
    let type: String
    let count: Int
    let generatedAt: String
}

// MARK: - Error Handling

enum TeacherAPIError: Error, LocalizedError {
    case invalidCode
    case invalidResponse
    case serverError(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid teacher access code"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError:
            return "Network connection error"
        }
    }
}