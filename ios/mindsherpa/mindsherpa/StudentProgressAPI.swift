//
//  StudentProgressAPI.swift
//  mindsherpa
//
//  Created by Claude Code on 9/17/25.
//

import Foundation
import UIKit

class StudentProgressAPI: ObservableObject {
    static let shared = StudentProgressAPI()

    @Published var isDeviceRegistered = false
    @Published var studentInfo: StudentInfo?
    @Published var isLoading = false
    @Published var lastError: String?

    private let baseURL: String
    private var deviceId: String {
        return DeviceManager.shared.deviceId
    }

    private init() {
        // Use AppConfig for consistent URL management
        self.baseURL = AppConfig.currentBaseURL
        loadStudentInfo()
    }

    // MARK: - Models

    struct StudentInfo: Codable {
        let studentId: String
        let teacherId: String
        let schoolId: String
        let firstName: String?
        let lastName: String?
        let email: String?
        let classCode: String?
        let classDetails: ClassDetails?
    }

    struct ClassDetails: Codable {
        let teacherName: String
        let teacherEmail: String
        let schoolName: String
        let programName: String
        let classCode: String
    }

    struct DeviceRegistrationRequest: Codable {
        let deviceId: String
        let platform: String
        let appVersion: String
        let deviceName: String
    }

    struct ClassJoinRequest: Codable {
        let deviceId: String
        let classCode: String
        let firstName: String
        let lastName: String
        let email: String?
    }

    struct VideoProgressRequest: Codable {
        let videoId: String
        let deviceId: String
        let watchedSeconds: Double
        let totalDuration: Double
        let isCompleted: Bool
        let courseId: String
        let lastPosition: Double
    }

    struct ApiResponse<T: Codable>: Codable {
        let success: Bool
        let data: T?
        let error: String?
        let message: String?
    }

    struct ClassJoinResponse: Codable {
        let success: Bool
        let studentId: String
        let teacherId: String
        let schoolId: String
        let message: String
        let classDetails: ClassDetails?
    }

    struct VideoProgressResponse: Codable {
        let success: Bool
        let progress: VideoProgressData
        let message: String
    }

    struct VideoProgressData: Codable {
        let videoId: String
        let deviceId: String
        let watchedSeconds: Int
        let totalDuration: Int
        let progressPercentage: Int
        let isCompleted: Bool
        let lastWatchedAt: String
        let courseId: String
    }

    // MARK: - Device Registration

    @MainActor
    func registerDevice() async {
        isLoading = true
        lastError = nil

        let request = DeviceRegistrationRequest(
            deviceId: deviceId,
            platform: "ios",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            deviceName: UIDevice.current.name
        )

        do {
            let url = URL(string: "\(baseURL)/api/progress/register-device")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isDeviceRegistered = true
                print("✅ Device registered successfully")
            } else {
                lastError = "Failed to register device"
                print("❌ Device registration failed")
            }

        } catch {
            lastError = "Network error: \(error.localizedDescription)"
            print("❌ Device registration error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Class Joining

    @MainActor
    func joinClass(classCode: String, firstName: String, lastName: String, email: String? = nil) async -> Bool {
        isLoading = true
        lastError = nil

        let request = ClassJoinRequest(
            deviceId: deviceId,
            classCode: classCode,
            firstName: firstName,
            lastName: lastName,
            email: email
        )

        do {
            let url = URL(string: "\(baseURL)/api/progress/join-class")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let joinResponse = try JSONDecoder().decode(ClassJoinResponse.self, from: data)

                studentInfo = StudentInfo(
                    studentId: joinResponse.studentId,
                    teacherId: joinResponse.teacherId,
                    schoolId: joinResponse.schoolId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    classCode: classCode,
                    classDetails: joinResponse.classDetails
                )

                saveStudentInfo()
                isLoading = false

                // Update class access in ProgressStore
                ProgressStore.shared.updateClassAccess()

                print("✅ Successfully joined class: \(classCode)")
                return true
            } else {
                let httpResponse = response as? HTTPURLResponse
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)

                if httpResponse?.statusCode == 404 {
                    lastError = "This Class does not exist"
                } else {
                    lastError = errorData?["error"] ?? "Failed to join class"
                }
                print("❌ Class join failed: \(lastError ?? "Unknown error")")
            }

        } catch {
            lastError = "Network error: \(error.localizedDescription)"
            print("❌ Class join error: \(error)")
        }

        isLoading = false
        return false
    }

    // MARK: - Progress Sync

    func syncVideoProgress(videoId: String, courseId: String, watchedSeconds: Double, totalDuration: Double, isCompleted: Bool, lastPosition: Double) async {
        // Only sync if we have student info (device is linked to a student)
        guard studentInfo != nil else {
            print("📤 Skipping progress sync - no student linked")
            return
        }

        let request = VideoProgressRequest(
            videoId: videoId,
            deviceId: deviceId,
            watchedSeconds: watchedSeconds,
            totalDuration: totalDuration,
            isCompleted: isCompleted,
            courseId: courseId,
            lastPosition: lastPosition
        )

        do {
            let url = URL(string: "\(baseURL)/api/progress/video")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("📤 Video progress synced: \(videoId)")
            } else {
                print("❌ Failed to sync video progress")
            }

        } catch {
            print("❌ Progress sync error: \(error)")
        }
    }

    // MARK: - Student Info Persistence

    private func saveStudentInfo() {
        if let data = try? JSONEncoder().encode(studentInfo) {
            UserDefaults.standard.set(data, forKey: "StudentInfo")
        }
    }

    private func loadStudentInfo() {
        if let data = UserDefaults.standard.data(forKey: "StudentInfo"),
           let info = try? JSONDecoder().decode(StudentInfo.self, from: data) {
            studentInfo = info
        }
    }

    // MARK: - Helper Methods

    var isStudentLinked: Bool {
        return studentInfo != nil
    }

    var studentDisplayName: String {
        guard let info = studentInfo else { return "" }
        if let first = info.firstName, let last = info.lastName {
            return "\(first) \(last)"
        }
        return info.studentId
    }

    func clearStudentInfo() {
        studentInfo = nil
        UserDefaults.standard.removeObject(forKey: "StudentInfo")
    }
}
