//
//  VideoRowViewTest.swift
//  mindsherpa
//
//  Created by Claude Code for debugging AsyncImage crash
//

import SwiftUI

// Minimal test data
struct TestVideo {
    let id: String = "test-1"
    let title: String = "Test Video Title"
    let duration: Int = 375 // 6:15
    let thumbnailUrl: String = "https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/1-1.jpg"
}

class TestViewModel: ObservableObject {
    // Minimal viewModel for testing
}

// Isolated VideoRowView test
struct VideoRowViewTest: View {
    let testVideo = TestVideo()
    @StateObject private var testViewModel = TestViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("VideoRowView AsyncImage Test")
                .font(.headline)
                .padding()
            
            // Test 1: Direct AsyncImage with static URL
            AsyncImage(url: URL(string: "https://skillvergence.mindsherpa.ai/assets/videos/thumbnails/1-1.jpg")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 50)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 50)
                case .failure:
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 80, height: 50)
                @unknown default:
                    Rectangle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 80, height: 50)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text("If this shows an image, AsyncImage works fine")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("AsyncImage Test")
    }
}

// Preview
struct VideoRowViewTest_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoRowViewTest()
        }
    }
}