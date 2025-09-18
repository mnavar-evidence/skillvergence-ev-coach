//
//  AccessControlManager.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import SwiftUI
import Combine

// MARK: - Access Control Manager

@MainActor
class AccessControlManager: ObservableObject {
    static let shared = AccessControlManager()

    @Published var isTeacherModeEnabled = false
    @Published var currentUserTier: UserTier = .free
    @Published var usedCodes: Set<String> = []
    @Published var earnedFriendCodes: [String] = []

    private let userDefaults = UserDefaults.standard
    private let schoolConfig = SchoolConfiguration.fallbrookHigh

    private init() {
        loadAccessData()
    }

    // MARK: - Teacher Mode Access

    func attemptTeacherModeAccess() {
        // Show teacher code entry view instead of direct access
        showTeacherCodeEntry = true
    }

    @Published var showTeacherCodeEntry = false
    @Published var teacherData: TeacherInfo?

    func validateTeacherCode(_ code: String) async -> Bool {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await TeacherAPIService.shared.validateTeacherCode(normalizedCode)

            if response.valid {
                isTeacherModeEnabled = true
                showTeacherCodeEntry = false
                teacherData = response.teacher
                print("🎓 Teacher mode activated with code: \(normalizedCode)")
                if let teacher = response.teacher {
                    print("🎓 Teacher info: \(teacher.name), Class Code: \(teacher.classCode ?? "N/A")")
                }
                return true
            } else {
                print("❌ Invalid teacher code: \(normalizedCode)")
                return false
            }
        } catch {
            print("❌ Teacher code validation error: \(error)")
            return false
        }
    }

    func exitTeacherMode() {
        isTeacherModeEnabled = false
        print("🎓 Teacher mode deactivated")
    }

    // MARK: - Code Validation

    func validateAndRedeemCode(_ code: String) -> CodeRedemptionResult {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if code was already used
        if usedCodes.contains(normalizedCode) {
            return .alreadyUsed
        }

        // Validate code format and type
        guard let codeType = CodeType.fromString(normalizedCode) else {
            return .invalid
        }

        // Validate code exists in our system (in real app, this would be backend call)
        guard isValidCode(normalizedCode, type: codeType) else {
            return .invalid
        }

        // Apply the code benefits
        switch codeType {
        case .classAccess:
            // Class Access codes give basic access to continue beyond 50 XP
            currentUserTier = .basicPaid
            usedCodes.insert(normalizedCode)
            saveAccessData()
            return .successBasic

        case .premium:
            currentUserTier = .premium
            usedCodes.insert(normalizedCode)
            saveAccessData()
            return .successPremium

        case .friend:
            // Friend codes give basic access (Class Access equivalent)
            currentUserTier = .basicPaid
            usedCodes.insert(normalizedCode)
            saveAccessData()
            return .successFriend

        case .individual:
            // Individual purchase codes give basic access (Class Access equivalent)
            currentUserTier = .basicPaid
            usedCodes.insert(normalizedCode)
            saveAccessData()
            return .successIndividual
        }
    }

    private func isValidCode(_ code: String, type: CodeType) -> Bool {
        // In real app, this would validate against backend
        // For now, simulate validation based on format
        return code.count == 6 &&
               code.hasPrefix(type.prefix) &&
               code.dropFirst().allSatisfy { $0.isNumber }
    }

    // MARK: - XP Threshold Check

    func shouldShowPaywall() -> Bool {
        let currentXP = ProgressStore.shared.getTotalXP()
        return currentXP >= schoolConfig.xpThreshold &&
               currentUserTier == .free
    }

    func hasBasicAccess() -> Bool {
        return currentUserTier != .free
    }

    func hasPremiumAccess() -> Bool {
        return currentUserTier == .premium
    }

    // MARK: - Friend Code Generation

    func checkAndGenerateFriendCodes() {
        let currentLevel = ProgressStore.shared.getCurrentLevel()
        let newCodesCount = friendCodesForLevel(currentLevel)
        let currentCodesCount = earnedFriendCodes.count

        if newCodesCount > currentCodesCount {
            let additionalCodes = newCodesCount - currentCodesCount
            for _ in 0..<additionalCodes {
                let friendCode = generateFriendCode()
                earnedFriendCodes.append(friendCode)
            }
            saveAccessData()
            print("🎉 Generated \(additionalCodes) new friend codes for reaching level \(currentLevel)")
        }
    }

    private func friendCodesForLevel(_ level: Int) -> Int {
        // Bronze: 1, Silver: 2, Gold: 4, Platinum: 8, Diamond: 16
        switch level {
        case 1: return 1  // Bronze
        case 2: return 2  // Silver
        case 3: return 4  // Gold
        case 4: return 8  // Platinum
        case 5...Int.max: return 16  // Diamond+
        default: return 0
        }
    }

    private func generateFriendCode() -> String {
        let number = Int.random(in: 10000...99999)
        return "F\(number)"
    }

    // MARK: - Data Persistence

    private func saveAccessData() {
        userDefaults.set(currentUserTier.rawValue, forKey: "user_tier")
        userDefaults.set(Array(usedCodes), forKey: "used_codes")
        userDefaults.set(earnedFriendCodes, forKey: "earned_friend_codes")
    }

    private func loadAccessData() {
        if let tierString = userDefaults.string(forKey: "user_tier"),
           let tier = UserTier(rawValue: tierString) {
            currentUserTier = tier
        }

        if let codes = userDefaults.array(forKey: "used_codes") as? [String] {
            usedCodes = Set(codes)
        }

        if let friendCodes = userDefaults.array(forKey: "earned_friend_codes") as? [String] {
            earnedFriendCodes = friendCodes
        }
    }
}

// MARK: - Data Models

enum UserTier: String, CaseIterable {
    case free = "free"
    case basicPaid = "basic_paid"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basicPaid: return "Basic"
        case .premium: return "Premium"
        }
    }

    var color: Color {
        switch self {
        case .free: return .gray
        case .basicPaid: return .blue
        case .premium: return .purple
        }
    }
}

enum CodeType: String, CaseIterable {
    case classAccess = "C"  // Changed from basic to class access
    case premium = "P"
    case friend = "F"
    case individual = "I"   // Individual purchaser codes

    var prefix: String { rawValue }

    var displayName: String {
        switch self {
        case .classAccess: return "Class Access"
        case .premium: return "Premium Access"
        case .friend: return "Friend Referral"
        case .individual: return "Individual Purchase"
        }
    }

    static func fromString(_ code: String) -> CodeType? {
        guard !code.isEmpty else { return nil }
        let firstChar = String(code.prefix(1))
        return CodeType(rawValue: firstChar)
    }
}

enum CodeRedemptionResult {
    case successBasic
    case successPremium
    case successFriend
    case successIndividual
    case invalid
    case alreadyUsed

    var message: String {
        switch self {
        case .successBasic:
            return "🎉 Basic access unlocked! You now have full access to all courses."
        case .successPremium:
            return "🌟 Premium access unlocked! You now have access to premium content and certifications."
        case .successFriend:
            return "👥 Friend code redeemed! You now have basic access thanks to your friend."
        case .successIndividual:
            return "💳 Individual access unlocked! You now have full access to all basic courses."
        case .invalid:
            return "❌ Invalid code. Please check the code and try again."
        case .alreadyUsed:
            return "⚠️ This code has already been used."
        }
    }

    var isSuccess: Bool {
        switch self {
        case .successBasic, .successPremium, .successFriend, .successIndividual:
            return true
        case .invalid, .alreadyUsed:
            return false
        }
    }
}

struct SchoolConfiguration {
    let schoolName: String
    let program: String
    let instructor: String
    let email: String
    let xpThreshold: Int
    let bulkLicenseCount: Int

    // School configurations will be loaded from database via API
}

extension SchoolConfiguration {
    static let fallbrookHigh = SchoolConfiguration(
        schoolName: "Fallbrook High School",
        program: "CTE Transportation Technology",
        instructor: "Mr. Dennis Johnson",
        email: "djohnson@fuhsd.net",
        xpThreshold: 50,
        bulkLicenseCount: 250
    )
}

// MARK: - Teacher Code Management

extension AccessControlManager {

    // Teacher-only functions for code management
    func generateBasicCodes(count: Int) -> [String] {
        guard isTeacherModeEnabled else { return [] }

        var codes: [String] = []
        for _ in 0..<count {
            let number = Int.random(in: 10000...99999)
            codes.append("B\(number)")
        }
        return codes
    }

    func generatePremiumCodes(count: Int) -> [String] {
        guard isTeacherModeEnabled else { return [] }

        var codes: [String] = []
        for _ in 0..<count {
            let number = Int.random(in: 10000...99999)
            codes.append("P\(number)")
        }
        return codes
    }

    func getCodeUsageAnalytics() -> CodeUsageAnalytics {
        guard isTeacherModeEnabled else {
            return CodeUsageAnalytics(basicCodesUsed: 0, premiumCodesUsed: 0)
        }

        let basicCodesUsed = usedCodes.filter { $0.hasPrefix("B") }.count
        let premiumCodesUsed = usedCodes.filter { $0.hasPrefix("P") }.count

        return CodeUsageAnalytics(
            basicCodesUsed: basicCodesUsed,
            premiumCodesUsed: premiumCodesUsed
        )
    }
}

struct CodeUsageAnalytics {
    let basicCodesUsed: Int
    let premiumCodesUsed: Int
}

// MARK: - Preview Extensions

extension AccessControlManager {
    static var preview: AccessControlManager {
        let manager = AccessControlManager()
        manager.currentUserTier = .basicPaid
        manager.earnedFriendCodes = ["F12345", "F67890"]
        return manager
    }
}
