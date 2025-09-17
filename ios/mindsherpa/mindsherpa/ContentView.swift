//
//  ContentView.swift
//  mindsherpa
//
//  Created by Murgesh Navar on 8/26/25.
//

import SwiftUI
import AVKit

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ContentView: View {
    @StateObject private var viewModel = EVCoachViewModel()
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @StateObject private var accessControl = AccessControlManager.shared
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        // Show teacher dashboard if teacher mode is enabled
        if accessControl.isTeacherModeEnabled {
            TeacherDashboardView()
        } else {
            NavigationStack {
                VStack(spacing: 0) {
                    // Top Section: Coach & Progress
                    CoachHeaderView(viewModel: viewModel)
                
                // Top Navigation Bar - Certificates hidden for TestFlight
                // HStack {
                //     Spacer()
                //
                //     NavigationLink(destination: MyCertificatesView()) {
                //         Image(systemName: "graduationcap")
                //             .font(.title2)
                //             .foregroundColor(.blue)
                //             .padding(.trailing)
                //     }
                // }
                // .padding(.horizontal)
                // .padding(.bottom, 8)
                
                // Media Tabs
                MediaTabsView(selectedTab: $selectedTab)
                
                // Content Area
                TabView(selection: $selectedTab) {
                    VideoView(viewModel: viewModel)
                        .tag(0)
                    PodcastView(viewModel: viewModel)
                        .tag(1)
                    AdvancedCourseListView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedTab) { oldValue, newValue in
                    let tabNames = ["Video", "Podcast", "Premium"]
                    let tabName = tabNames[safe: newValue] ?? "Unknown"
                    analyticsManager.track(.tabSwitched(from: oldValue, to: newValue, tabName: tabName))
                    previousTab = newValue
                }
                
                Spacer()
            }
                .background(Color(UIColor.systemBackground))
                .navigationBarHidden(true)
            }
            .onAppear {
                viewModel.loadCourses()
            }
        }
    }
}
