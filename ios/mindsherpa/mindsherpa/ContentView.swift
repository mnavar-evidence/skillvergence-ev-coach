//
//  ContentView.swift
//  mindsherpa
//
//  Created by Murgesh Navar on 8/26/25.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var viewModel = EVCoachViewModel()
    @State private var selectedTab = 0
    
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
                    Text("Podcast View - Coming Soon")
                        .tag(1)
                    Text("Mind Map View - Coming Soon")
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
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
