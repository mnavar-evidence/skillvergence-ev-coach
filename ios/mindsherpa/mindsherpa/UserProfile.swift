//
//  UserProfile.swift
//  mindsherpa
//
//  Created by Claude on 9/16/25.
//

import Foundation

// MARK: - User Profile Models

struct UserProfile: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    let profileImage: String?

    // Computed properties for display
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }

    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? (components.last?.first?.uppercased() ?? "") : ""
        return firstInitial + lastInitial
    }

    init(id: String, fullName: String, email: String, profileImage: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.profileImage = profileImage
    }
}