//
//  LevelSystem.swift
//  mindsherpa
//
//  Created by Claude on 9/7/25.
//

import Foundation

// MARK: - XP/Gamification System (Engagement & Fun)

enum XPLevel: String, CaseIterable, Codable {
    case bronze = "bronze"           // 0-999 XP
    case silver = "silver"           // 1000-2499 XP  
    case gold = "gold"               // 2500-4999 XP
    case platinum = "platinum"       // 5000-9999 XP
    case diamond = "diamond"         // 10000+ XP
    
    var displayName: String {
        switch self {
        case .bronze: return "Bronze Learner"
        case .silver: return "Silver Learner" 
        case .gold: return "Gold Learner"
        case .platinum: return "Platinum Learner"
        case .diamond: return "Diamond Learner"
        }
    }
    
    var minXP: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1000
        case .gold: return 2500
        case .platinum: return 5000
        case .diamond: return 10000
        }
    }
    
    var maxXP: Int? {
        switch self {
        case .bronze: return 999
        case .silver: return 2499
        case .gold: return 4999
        case .platinum: return 9999
        case .diamond: return nil // No upper limit
        }
    }
    
    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "star.circle.fill"
        case .diamond: return "diamond.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "purple"
        case .diamond: return "blue"
        }
    }
    
    static func levelForXP(_ xp: Int) -> XPLevel {
        if xp >= 10000 { return .diamond }
        else if xp >= 5000 { return .platinum }
        else if xp >= 2500 { return .gold }
        else if xp >= 1000 { return .silver }
        else { return .bronze }
    }
}

// MARK: - Professional Certification System (Career & Competency)

enum CertificationLevel: String, CaseIterable, Codable {
    case none = "none"
    case foundation = "foundation"               // 1 course completed
    case associate = "associate"                 // 2-3 courses completed
    case professional = "professional"           // 4 courses completed  
    case certified = "certified"                 // All 5 courses completed
    
    var displayName: String {
        switch self {
        case .none: return "Student"
        case .foundation: return "EV Foundation Certified"
        case .associate: return "EV Associate Technician"
        case .professional: return "EV Professional Technician"
        case .certified: return "EV Certified Master"
        }
    }
    
    var shortName: String {
        switch self {
        case .none: return "Student"
        case .foundation: return "Foundation"
        case .associate: return "Associate"
        case .professional: return "Professional"
        case .certified: return "Certified Master"
        }
    }
    
    var coursesRequired: Int {
        switch self {
        case .none: return 0
        case .foundation: return 1
        case .associate: return 2
        case .professional: return 4
        case .certified: return 5
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "person.crop.circle"
        case .foundation: return "checkmark.seal"
        case .associate: return "checkmark.seal.fill"
        case .professional: return "rosette"
        case .certified: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "gray"
        case .foundation: return "green"
        case .associate: return "blue"
        case .professional: return "orange"
        case .certified: return "gold"
        }
    }
    
    static func levelForCompletedCourses(_ completedCount: Int) -> CertificationLevel {
        if completedCount >= 5 { return .certified }
        else if completedCount >= 4 { return .professional }
        else if completedCount >= 2 { return .associate }
        else if completedCount >= 1 { return .foundation }
        else { return .none }
    }
}

// MARK: - Level System Extensions

extension ProgressStore {
    
    // XP/Gamification Methods
    func getCurrentXPLevel() -> XPLevel {
        let totalXP = getTotalXP()
        return XPLevel.levelForXP(totalXP)
    }
    
    func getXPProgressToNextLevel() -> (current: Int, needed: Int, percentage: Double) {
        let totalXP = getTotalXP()
        let currentLevel = XPLevel.levelForXP(totalXP)
        
        // If already at Diamond level, no next level
        guard currentLevel != .diamond else {
            return (current: totalXP, needed: totalXP, percentage: 1.0)
        }
        
        let currentLevelMinXP = currentLevel.minXP
        let nextLevel = XPLevel.allCases[XPLevel.allCases.firstIndex(of: currentLevel)! + 1]
        let nextLevelMinXP = nextLevel.minXP
        
        let currentProgressXP = totalXP - currentLevelMinXP
        let neededForNext = nextLevelMinXP - currentLevelMinXP
        let percentage = Double(currentProgressXP) / Double(neededForNext)
        
        return (current: currentProgressXP, needed: neededForNext, percentage: min(percentage, 1.0))
    }
    
    // Professional Certification Methods
    func getCurrentCertificationLevel() -> CertificationLevel {
        let completedCourses = getCompletedCoursesCount()
        return CertificationLevel.levelForCompletedCourses(completedCourses)
    }
    
    func getCompletedCoursesCount() -> Int {
        // Count courses with all videos completed using strict professional criteria
        let courseIds = ["1", "2", "3", "4", "5"] // Basic course IDs
        var completedCount = 0
        
        for courseId in courseIds {
            if isProfessionalCourseCompleted(courseId: courseId) {
                completedCount += 1
            }
        }
        
        return completedCount
    }
    
    // Professional certification comes from completing ADVANCED courses, not basic courses
    func isProfessionalCourseCompleted(courseId: String) -> Bool {
        // Check if the corresponding advanced course is completed
        // This should check advanced course completion via SubscriptionManager or similar
        // For now, return false since advanced course completion tracking needs to be implemented
        return false
    }
    
    // Get advanced course completion status for professional certification
    func getCourseCompletionDetails() -> [(courseId: String, completed: Bool, videosCompleted: Int, totalVideos: Int)] {
        let advancedCourseIds = ["adv_1", "adv_2", "adv_3", "adv_4", "adv_5"]
        let courseNames = ["1", "2", "3", "4", "5"] // For display mapping
        
        return zip(advancedCourseIds, courseNames).map { (advancedId, basicId) in
            // TODO: Check if advanced course is completed
            // This requires integration with advanced course completion tracking
            let isCompleted = false // Placeholder until advanced course tracking is implemented
            
            return (courseId: basicId, completed: isCompleted, videosCompleted: 0, totalVideos: 1)
        }
    }
}