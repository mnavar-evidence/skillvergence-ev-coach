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
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section: Coach & Progress
                CoachHeaderView(viewModel: viewModel)
                
                // Media Tabs
                MediaTabsView(selectedTab: $selectedTab)
                
                // Content Area
                TabView(selection: $selectedTab) {
                    VideoView(viewModel: viewModel)
                        .tag(0)
                    PodcastView(viewModel: viewModel)
                        .tag(1)
                    Text("Mind Map View - Coming Soon")
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedTab) { newTab in
                    let tabNames = ["Video", "Podcast", "Mind-Map"]
                    let tabName = tabNames[safe: newTab] ?? "Unknown"
                    analyticsManager.track(.tabSwitched(from: previousTab, to: newTab, tabName: tabName))
                    previousTab = newTab
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadCourses()
        }
        .onTapGesture {
            // Global keyboard dismissal
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
