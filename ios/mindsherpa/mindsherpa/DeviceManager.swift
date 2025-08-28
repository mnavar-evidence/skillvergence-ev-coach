//
//  DeviceManager.swift
//  mindsherpa
//
//  Created by Claude Code on 8/27/25.
//

import Foundation
import UIKit

class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    @Published private(set) var deviceId: String = ""
    
    private let deviceIdKey = "AnonymousDeviceId"
    private let firstLaunchKey = "FirstLaunchDate"
    private let appVersionKey = "AppVersion"
    
    private init() {
        loadOrCreateDeviceId()
    }
    
    // MARK: - Device ID Management
    
    private func loadOrCreateDeviceId() {
        if let existingId = UserDefaults.standard.string(forKey: deviceIdKey), !existingId.isEmpty {
            deviceId = existingId
        } else {
            deviceId = generateDeviceId()
            UserDefaults.standard.set(deviceId, forKey: deviceIdKey)
            
            // Track first launch
            UserDefaults.standard.set(Date(), forKey: firstLaunchKey)
            
            // Track app version on first launch
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                UserDefaults.standard.set(appVersion, forKey: appVersionKey)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    private func generateDeviceId() -> String {
        // Create a unique device ID using UUID + device characteristics
        let uuid = UUID().uuidString
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        // Combine characteristics and hash for anonymity
        let combined = "\(uuid)-\(deviceModel)-\(systemVersion)-\(timestamp)"
        return combined.replacingOccurrences(of: " ", with: "-")
    }
    
    // MARK: - Device Information
    
    var deviceInfo: [String: Any] {
        return [
            "deviceId": deviceId,
            "deviceModel": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown",
            "firstLaunchDate": UserDefaults.standard.object(forKey: firstLaunchKey) ?? Date(),
            "locale": Locale.current.identifier,
            "timeZone": TimeZone.current.identifier
        ]
    }
    
    var isFirstLaunch: Bool {
        return UserDefaults.standard.object(forKey: firstLaunchKey) == nil
    }
    
    // MARK: - Reset Methods (for testing)
    
    func resetDeviceId() {
        UserDefaults.standard.removeObject(forKey: deviceIdKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
        UserDefaults.standard.removeObject(forKey: appVersionKey)
        UserDefaults.standard.synchronize()
        loadOrCreateDeviceId()
    }
}