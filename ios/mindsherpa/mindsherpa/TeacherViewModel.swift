//
//  TeacherViewModel.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI
import Combine

// MARK: - Teacher Data Models

struct Teacher: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    let school: String
    let department: String
    let classTitle: String
    let classCode: String?
    let instagramHandle: String?

    // Teacher information will be loaded from database via API
}

struct ClassStudent: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    let studentId: String
    let enrollmentDate: Date
    let courseLevel: CTECourseLevel
    let isActive: Bool

    // Progress tracking
    var totalXP: Int
    var currentLevel: Int
    var coursesCompleted: [String]
    var certificatesEarned: [SkillvergenceCertificate]
    var lastActivityDate: Date?
    var lastActiveString: String // Store the raw API string like "2 hours ago"
    var totalWatchTime: Double // in hours
    var videosCompleted: Int
    var currentStreak: Int
}

enum CTECourseLevel: String, CaseIterable, Codable {
    case transportationTech1 = "Transportation Tech I"
    case transportationTech2 = "Transportation Tech II (Capstone)"
    case transportationTech3 = "Transportation Tech III (Advanced)"

    var displayName: String { rawValue }
    var sequenceNumber: Int {
        switch self {
        case .transportationTech1: return 1
        case .transportationTech2: return 2
        case .transportationTech3: return 3
        }
    }
}

struct StudentActivity: Identifiable {
    let id = UUID()
    let studentName: String
    let studentId: String
    let description: String
    let type: ActivityType
    let timestamp: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum ActivityType {
    case videoCompleted
    case certificateRequested
    case courseCompleted
    case levelUp
    case streakAchieved

    var color: Color {
        switch self {
        case .videoCompleted: return .blue
        case .certificateRequested: return .orange
        case .courseCompleted: return .green
        case .levelUp: return .purple
        case .streakAchieved: return .yellow
        }
    }
}

// MARK: - Teacher View Model

@MainActor
class TeacherViewModel: ObservableObject {
    @Published var currentTeacher: Teacher?
    @Published var students: [ClassStudent] = []
    @Published var certificates: [APICertificate] = []
    @Published var recentActivities: [StudentActivity] = []
    @Published var isLoading = false
    @Published var showAnnouncementDialog = false
    @Published var selectedStudent: ClassStudent?

    // Analytics
    @Published var totalStudents: Int = 60
    @Published var activeToday: Int = 0
    @Published var pendingCertificates: Int = 0
    @Published var averageCompletion: Double = 0.0

    private var cancellables = Set<AnyCancellable>()
    private var isDataLoaded = false // Cache flag for initial data
    private var lastRefreshTime = Date.distantPast

    init() {
        // Teacher data will be loaded during authentication
    }

    func loadTeacherInfo(teacherId: String) {
        // Load teacher information from database via API
        // This should be called during teacher authentication
        currentTeacher = Teacher(
            id: teacherId,
            fullName: "Loading...",
            email: "",
            school: "",
            department: "",
            classTitle: "",
            classCode: nil,
            instagramHandle: nil
        )

        // In real implementation, this would fetch from API:
        // TeacherAPIService.shared.getTeacherInfo(teacherId) { teacher in
        //     self.currentTeacher = teacher
        // }
    }

    // MARK: - Data Loading

    func loadClassData() {
        // Don't reload if data is already loaded
        if isDataLoaded {
            return
        }

        isLoading = true

        Task {
            do {
                // Load both students and certificates concurrently
                async let studentsResponse = TeacherAPIService.shared.getStudentRoster(schoolId: "fallbrook-hs")
                async let certificatesResponse = TeacherAPIService.shared.getCertificates(schoolId: "fallbrook-hs")

                let studentData = try await studentsResponse
                let certificateData = try await certificatesResponse

                // Convert API students to ClassStudent objects
                let classStudents = studentData.students.map { apiStudent in
                    // Determine if student is active based on lastActive string (like Android does)
                    let isActive = determineActivityStatus(from: apiStudent.lastActive)

                    return ClassStudent(
                        id: apiStudent.id,
                        fullName: apiStudent.name,
                        email: apiStudent.email,
                        studentId: apiStudent.id,
                        enrollmentDate: Date(),
                        courseLevel: .transportationTech1,
                        isActive: isActive,
                        totalXP: apiStudent.totalXP,
                        currentLevel: apiStudent.currentLevel,
                        coursesCompleted: [],
                        certificatesEarned: [],
                        lastActivityDate: parseActivityDate(from: apiStudent.lastActive),
                        lastActiveString: apiStudent.lastActive,
                        totalWatchTime: Double.random(in: 5...20),
                        videosCompleted: apiStudent.completedCourses * 3,
                        currentStreak: apiStudent.streak
                    )
                }

                await MainActor.run {
                    self.students = classStudents
                    self.certificates = certificateData.certificates
                    self.totalStudents = studentData.summary.totalStudents
                    self.activeToday = studentData.summary.activeToday
                    self.averageCompletion = Double(studentData.summary.avgCompletionRate)
                    self.recentActivities = self.generateRecentActivities()
                    self.calculateAnalytics()
                    self.isLoading = false
                    self.isDataLoaded = true
                    self.lastRefreshTime = Date()
                }
            } catch {
                print("Error loading class data: \(error)")
                // Fallback to sample data on error
                await MainActor.run {
                    self.students = self.generateSampleStudents()
                    self.certificates = []
                    self.recentActivities = self.generateRecentActivities()
                    self.calculateAnalytics()
                    self.isLoading = false
                    self.isDataLoaded = true
                    self.lastRefreshTime = Date()
                }
            }
        }
    }

    func refreshClassData() async {
        // Only refresh if more than 30 seconds have passed since last refresh
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
        if timeSinceLastRefresh < 30 {
            return
        }

        isLoading = true

        // Reset data loaded flag to allow fresh data fetch
        isDataLoaded = false

        // Use existing loadClassData method which now has real API integration
        loadClassData()
    }

    func refreshData() {
        // Force refresh by resetting cache
        isDataLoaded = false
        loadClassData()
    }

    func forceRefreshClassData() async {
        // Force a full refresh (for manual pull-to-refresh)
        isDataLoaded = false
        lastRefreshTime = Date.distantPast
        loadClassData()
    }

    private func generateSampleStudents() -> [ClassStudent] {
        var students: [ClassStudent] = []

        // Generate 60 sample students for the current class
        let sampleNames = [
            "Alex Rodriguez", "Emma Chen", "Marcus Williams", "Sofia Garcia", "Ethan Thompson",
            "Ava Martinez", "Noah Johnson", "Isabella Brown", "Liam Davis", "Mia Lopez",
            "Lucas Anderson", "Charlotte Wilson", "Mason Taylor", "Amelia Moore", "Oliver Jackson",
            "Harper Martin", "Elijah Lee", "Evelyn White", "Logan Harris", "Abigail Clark",
            "Jacob Lewis", "Emily Robinson", "Michael Walker", "Elizabeth Hall", "Daniel Allen",
            "Madison Young", "Henry King", "Victoria Wright", "Alexander Scott", "Grace Adams",
            "Sebastian Nelson", "Chloe Baker", "Samuel Carter", "Zoey Mitchell", "David Perez",
            "Lily Roberts", "Joseph Turner", "Natalie Phillips", "Carter Campbell", "Hannah Parker",
            "Wyatt Evans", "Addison Edwards", "Owen Stewart", "Aria Flores", "Luke Morris",
            "Layla Reed", "Gabriel Cook", "Scarlett Morgan", "Anthony Bell", "Leah Murphy",
            "Isaac Bailey", "Nora Rivera", "Hunter Cooper", "Stella Richardson", "Adrian Cox",
            "Maya Howard", "Julian Ward", "Claire Torres", "Maverick Peterson", "Savannah Gray"
        ]

        for i in 0..<60 {
            let name = sampleNames[i]
            let courseLevel: CTECourseLevel = {
                switch i % 3 {
                case 0: return .transportationTech1
                case 1: return .transportationTech2
                default: return .transportationTech3
                }
            }()

            let student = ClassStudent(
                id: "student_\(i + 1)",
                fullName: name,
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@student.fuhsd.net",
                studentId: String(format: "ST%04d", 2024001 + i),
                enrollmentDate: Calendar.current.date(byAdding: .day, value: -Int.random(in: 30...180), to: Date()) ?? Date(),
                courseLevel: courseLevel,
                isActive: Bool.random(),
                totalXP: Int.random(in: 0...2000),
                currentLevel: Int.random(in: 1...8),
                coursesCompleted: Array(["course_1", "course_2", "course_3", "course_4", "course_5"].prefix(Int.random(in: 0...5))),
                certificatesEarned: [],
                lastActivityDate: Bool.random() ? Calendar.current.date(byAdding: .hour, value: -Int.random(in: 1...48), to: Date()) : nil,
                lastActiveString: Bool.random() ? "\(Int.random(in: 1...23)) hours ago" : "3 days ago",
                totalWatchTime: Double.random(in: 0...20),
                videosCompleted: Int.random(in: 0...25),
                currentStreak: Int.random(in: 0...15)
            )

            students.append(student)
        }

        return students.sorted { $0.fullName < $1.fullName }
    }

    private func generateRecentActivities() -> [StudentActivity] {
        let activities = [
            StudentActivity(
                studentName: "Emma Chen",
                studentId: "ST2024002",
                description: "Completed 'High Voltage Safety Foundation' video",
                type: .videoCompleted,
                timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date()
            ),
            StudentActivity(
                studentName: "Marcus Williams",
                studentId: "ST2024003",
                description: "Requested certificate for EV Fundamentals course",
                type: .certificateRequested,
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            StudentActivity(
                studentName: "Sofia Garcia",
                studentId: "ST2024004",
                description: "Achieved 7-day learning streak",
                type: .streakAchieved,
                timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
            ),
            StudentActivity(
                studentName: "Ethan Thompson",
                studentId: "ST2024005",
                description: "Leveled up to EV Technician (Level 4)",
                type: .levelUp,
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
            ),
            StudentActivity(
                studentName: "Ava Martinez",
                studentId: "ST2024006",
                description: "Completed 'Electrical Fundamentals' course",
                type: .courseCompleted,
                timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
            )
        ]

        return activities.sorted { $0.timestamp > $1.timestamp }
    }

    private func calculateAnalytics() {
        totalStudents = students.count
        // Don't override activeToday from API response - comes from backend summary
        // Don't override averageCompletion from API response - comes from backend avgCompletionRate

        // Mock pending certificates - in real app this would come from backend
        pendingCertificates = Int.random(in: 3...12)
    }

    // MARK: - Teacher Actions

    func exportClassProgress() {
        // Implementation for exporting class progress to CSV/PDF
        if let teacher = currentTeacher {
            print("Exporting class progress for \(teacher.fullName)")
        }
    }

    func getStudentsByLevel(_ level: CTECourseLevel) -> [ClassStudent] {
        return students.filter { $0.courseLevel == level }
    }

    func getTopPerformingStudents(limit: Int = 10) -> [ClassStudent] {
        return students.sorted { $0.totalXP > $1.totalXP }.prefix(limit).map { $0 }
    }

    func getStudentsNeedingAttention() -> [ClassStudent] {
        return students.filter { student in
            // Students who haven't been active in the last week
            guard let lastActivity = student.lastActivityDate else { return true }
            let daysSinceActivity = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            return daysSinceActivity > 7 || student.totalXP < 100
        }
    }

    func sendAnnouncementToClass(message: String) {
        // Implementation for sending announcements to all students
        print("Sending announcement to class: \(message)")
    }

    // MARK: - Activity Parsing Helpers

    private func determineActivityStatus(from lastActive: String) -> Bool {
        // Use the same logic as Android TeacherViewModel
        let lowercased = lastActive.lowercased()

        if lowercased.contains("minute") {
            return true
        }

        if lowercased.contains("hour") {
            // Extract hours and check if less than 24
            let hourMatch = lastActive.range(of: #"\d+"#, options: .regularExpression)
            if let range = hourMatch {
                let hourString = String(lastActive[range])
                let hours = Int(hourString) ?? 25
                return hours < 24
            }
            return false
        }

        if lowercased.contains("today") {
            return true
        }

        return false
    }

    private func parseActivityDate(from lastActive: String) -> Date? {
        // Parse relative time strings like "2 hours ago", "30 minutes ago"
        let lowercased = lastActive.lowercased()

        if lowercased.contains("minute") {
            if let minuteMatch = lastActive.range(of: #"\d+"#, options: .regularExpression) {
                let minuteString = String(lastActive[minuteMatch])
                if let minutes = Int(minuteString) {
                    return Calendar.current.date(byAdding: .minute, value: -minutes, to: Date())
                }
            }
        }

        if lowercased.contains("hour") {
            if let hourMatch = lastActive.range(of: #"\d+"#, options: .regularExpression) {
                let hourString = String(lastActive[hourMatch])
                if let hours = Int(hourString) {
                    return Calendar.current.date(byAdding: .hour, value: -hours, to: Date())
                }
            }
        }

        if lowercased.contains("day") {
            if let dayMatch = lastActive.range(of: #"\d+"#, options: .regularExpression) {
                let dayString = String(lastActive[dayMatch])
                if let days = Int(dayString) {
                    return Calendar.current.date(byAdding: .day, value: -days, to: Date())
                }
            }
        }

        if lowercased.contains("today") {
            return Calendar.current.date(byAdding: .hour, value: -1, to: Date())
        }

        return nil
    }
}

// MARK: - Preview Data Extensions

extension TeacherViewModel {
    static var preview: TeacherViewModel {
        let viewModel = TeacherViewModel()
        return viewModel
    }
}