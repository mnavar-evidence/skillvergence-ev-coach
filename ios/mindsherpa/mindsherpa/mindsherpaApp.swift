//
//  mindsherpaApp.swift
//  mindsherpa
//
//  Created by Murgesh Navar on 8/26/25.
//

import SwiftUI

@main
struct mindsherpaApp: App {
    init() {
        // Load dynamic configuration and test connectivity
        Task {
            await AppConfig.loadDynamicConfiguration()
            let isConnected = await AppConfig.testConnectivity()
            print("🌐 Network connectivity: \(isConnected ? "✅ Connected" : "❌ Failed")")
        }
        
        // Print app configuration on startup
        AppConfig.printConfiguration()
        
        // Initialize device manager
        _ = DeviceManager.shared
        
        // Initialize analytics
        AnalyticsManager.shared.track(.appLaunched)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
