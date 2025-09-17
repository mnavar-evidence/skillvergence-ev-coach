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
    let instagramHandle: String?

    static let dennisJohnson = Teacher(
        id: "teacher_dennis_johnson",
        fullName: "Mr. Dennis Johnson",
        email: "djohnson@fuhsd.net",
        school: "Fallbrook High School",
        department: "CTE Transportation Technology",
        classTitle: "CTE Pathway: Transportation Technology",
        instagramHandle: "@avotransportationhs"
    )
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
    @Published var currentTeacher: Teacher = .dennisJohnson
    @Published var students: [ClassStudent] = []
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

    init() {
        loadClassData()
    }

    // MARK: - Data Loading

    func loadClassData() {
        isLoading = true

        // Simulate loading student data for Dennis Johnson's class
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.students = self.generateSampleStudents()
            self.recentActivities = self.generateRecentActivities()
            self.calculateAnalytics()
            self.isLoading = false
        }
    }

    func refreshClassData() async {
        // Simulate API refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        loadClassData()
    }

    private func generateSampleStudents() -> [ClassStudent] {
        var students: [ClassStudent] = []

        // Generate 60 sample students for Dennis Johnson's class
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
        activeToday = students.filter { student in
            guard let lastActivity = student.lastActivityDate else { return false }
            return Calendar.current.isDateInToday(lastActivity)
        }.count

        // Mock pending certificates - in real app this would come from backend
        pendingCertificates = Int.random(in: 3...12)

        // Calculate average completion
        let totalProgress = students.reduce(0.0) { sum, student in
            let completionRate = Double(student.coursesCompleted.count) / 5.0 * 100.0
            return sum + min(completionRate, 100.0)
        }
        averageCompletion = totalProgress / Double(students.count)
    }

    // MARK: - Teacher Actions

    func exportClassProgress() {
        // Implementation for exporting class progress to CSV/PDF
        print("Exporting class progress for \(currentTeacher.fullName)")
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
}

// MARK: - Preview Data Extensions

extension TeacherViewModel {
    static var preview: TeacherViewModel {
        let viewModel = TeacherViewModel()
        return viewModel
    }
}