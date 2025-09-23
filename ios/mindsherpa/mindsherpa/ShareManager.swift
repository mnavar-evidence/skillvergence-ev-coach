//
//  ShareManager.swift
//  mindsherpa
//
//  Created by Claude on 9/4/25.
//

import SwiftUI
import LinkPresentation

@MainActor
class ShareManager: NSObject, ObservableObject {
    static let shared = ShareManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Basic Text Sharing
    
    /// Share simple text content using iOS native share sheet
    func shareText(_ text: String, from sourceView: UIView? = nil) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // For iPad - set popover source
        if let popover = activityVC.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                // Fallback to center of screen
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popover.sourceView = window.rootViewController?.view
                    popover.sourceRect = CGRect(x: window.frame.midX, y: window.frame.midY, width: 0, height: 0)
                }
            }
        }
        
        // Present from top view controller
        if let topVC = getTopViewController() {
            topVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Course Progress Sharing
    
    func shareCourseCompletion(courseName: String, totalVideos: Int, totalHours: Double) {
        let text = """
        🎉 Just completed "\(courseName)" on WattWorks!
        
        📚 \(totalVideos) videos watched
        ⏱️ \(String(format: "%.1f", totalHours)) hours of learning
        🚗⚡ Ready to work on electric vehicles!
        
        #EVTraining #ElectricVehicles #ProfessionalDevelopment
        """
        
        shareText(text)
    }
    
    func shareVideoCompletion(videoTitle: String, courseName: String) {
        let text = """
        ✅ Just finished watching "\(videoTitle)" 
        
        📖 Part of the \(courseName) course on WattWorks
        🔧 Learning hands-on EV repair skills!
        
        #EVTraining #ElectricVehicles
        """
        
        shareText(text)
    }
    
    // MARK: - XP and Level Sharing
    
    func shareLevelAchievement(level: Int, xp: Int, levelName: String) {
        let text = """
        🚀 Level Up! Just reached Level \(level) - \(levelName)!
        
        ⭐ \(xp) total XP earned
        📈 Advancing my EV expertise on WattWorks
        
        #EVTraining #LevelUp #ElectricVehicles
        """
        
        shareText(text)
    }
    
    func shareLearningStreak(streakDays: Int) {
        let streakEmoji = streakDays >= 7 ? "🔥" : "⚡"
        let text = """
        \(streakEmoji) \(streakDays) day learning streak on WattWorks!
        
        📚 Consistently building my electric vehicle expertise
        🎯 Committed to professional growth
        
        #EVTraining #LearningStreak #Consistency
        """
        
        shareText(text)
    }
    
    // MARK: - Helper Methods
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

// MARK: - SwiftUI View Extension for Easy Sharing

extension View {
    func shareButton(text: String, systemImage: String = "square.and.arrow.up") -> some View {
        Button(action: {
            ShareManager.shared.shareText(text)
        }) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}