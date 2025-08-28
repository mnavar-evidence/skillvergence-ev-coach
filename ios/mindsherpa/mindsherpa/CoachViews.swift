//
//  CoachViews.swift
//  mindsherpa
//
//  Created by Murgesh Navar on 8/26/25.
//

import SwiftUI


struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MediaTabsView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Video", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Podcast", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Mind-Map", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? Color.accentColor : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}



struct CoachHeaderView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Coach Nova
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coach Nova • personalized")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Simple first, with shop analogies.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Fast Track Button
                Button {
                    // Action for fast track
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Fast-Track 20m")
                            .font(.caption.weight(.medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .symbolRenderingMode(.hierarchical)
            }
            
            // Progress Metrics
            HStack(spacing: 12) {
                MetricView(title: "Streak", value: "3d", icon: "flame.fill")
                MetricView(title: "Time", value: "15m", icon: "clock.fill")
                MetricView(title: "Confidence", value: "72%", icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 4)
    }
}

struct VideoView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView("Loading courses...")
                            .controlSize(.large)
                        Text("Preparing your EV training content...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                } else if viewModel.courses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                            .symbolRenderingMode(.hierarchical)
                        Text("Unable to Load Courses")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("Check your connection and try again")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Retry") {
                            viewModel.loadCourses()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.courses, id: \.id) { course in
                            Button {
                                viewModel.selectedCourse = course
                            } label: {
                                CourseCardView(course: course, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // AI Interaction with proper spacing
                AIInteractionView(viewModel: viewModel)
                    .padding(.top, 20)
                
                // Bottom safe area padding
                Color.clear
                    .frame(height: 50)
                
                // Modern navigation handled by navigationDestination
            }
            .padding()
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.selectedCourse != nil },
            set: { if !$0 { viewModel.selectedCourse = nil } }
        )) {
            if let course = viewModel.selectedCourse {
                CourseDetailView(course: course, viewModel: viewModel)
            }
        }
    }
}

struct CourseCardView: View {
    let course: Course
    @ObservedObject var viewModel: EVCoachViewModel
    
    // Cache expensive calculations
    private let formattedDuration: String
    private let completionPercentage: Double
    private let completedVideoCount: Int
    
    init(course: Course, viewModel: EVCoachViewModel) {
        self.course = course
        self.viewModel = viewModel
        
        // Pre-calculate expensive values
        self.formattedDuration = Self.formatHours(course.estimatedHours)
        self.completionPercentage = course.completionPercentage(with: viewModel.videoProgress)
        self.completedVideoCount = course.videos.filter { video in
            viewModel.videoProgress[video.id]?.isCompleted ?? false
        }.count
    }
    
    private static func formatHours(_ hours: Double) -> String {
        if hours < 1.0 {
            let minutes = Int(hours * 60)
            return "\(minutes) min"
        } else if hours == 1.0 {
            return "1 hour"
        } else {
            let roundedHours = hours.rounded()
            return "\(Int(roundedHours)) hours"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: course.category.icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(course.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                    
                    if completionPercentage > 0 {
                        Text("\(Int(completionPercentage))%")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Text(course.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Progress bar if course has progress
            if completionPercentage > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(completedVideoCount) of \(course.videos.count) videos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    MediaProgressIndicator(
                        progress: completionPercentage / 100.0,
                        isCompleted: completionPercentage >= 100,
                        mediaType: .course,
                        size: .medium
                    )
                }
            }
            
            HStack {
                Label(course.skillLevel.displayName, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                    Text("\(course.videos.count) videos")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
}

// Keep the rest of your views unchanged...

struct AIInteractionView: View {
    @ObservedObject var viewModel: EVCoachViewModel
    @State private var questionText = ""
    @FocusState private var isTextFieldFocused: Bool

    let quickQuestions = [
        "Compare alternator vs DC-DC",
        "Explain DC fast charging",
        "What PPE do I need?",
        "How does regen braking work?"
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Quick Question Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickQuestions, id: \.self) { question in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { 
                                questionText = question
                                isTextFieldFocused = true // Focus the text field for editing
                            }
                        } label: {
                            Text(question).font(.caption).foregroundStyle(.primary)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                }
                .padding(.horizontal)
            }

            // Question Input
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                    TextField("Ask about this content...", text: $questionText)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            sendQuestion()
                        }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)

               
                
                //Button {
                  //  viewModel.askAI(question: questionText)
                    //questionText = ""
                //} label: {
                  //  Image(systemName: questionText.isEmpty ? "paperplane" : "paperplane.fill").font(.caption)
                //}
                //.buttonStyle(.borderedProminent)
                //.controlSize(.small)
                //.disabled(questionText.isEmpty || viewModel.isAILoading)
                
                Button {
                    sendQuestion()
                } label: {
                    Image(systemName: questionText.isEmpty ? "paperplane" : "paperplane.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(questionText.isEmpty || viewModel.isAILoading)
                .symbolRenderingMode(.hierarchical)
            }
            .padding(.horizontal)

            // AI response
           // if !viewModel.aiResponse.isEmpty {
             //   VStack(alignment: .leading, spacing: 8) {
             //       HStack {
              //          Image(systemName: "brain.head.profile").foregroundStyle(.blue).font(.caption)
              //          Text("Coach Nova").font(.caption).fontWeight(.medium).foregroundStyle(.primary)
              //          Spacer()
              //          Button("Clear") { viewModel.clearAIResponse() }
              //              .font(.caption2).foregroundStyle(.secondary)
              //      }
              //      Text(viewModel.aiResponse)
              //          .font(.subheadline)
              //          .foregroundStyle(.primary)
              //          .padding(12)
              //          .background(.regularMaterial)
              //          .clipShape(RoundedRectangle(cornerRadius: 8))
              //  }
              //  .padding(.horizontal)
              //  .padding(.top, 8)
           // }
            
            // Show AI response
            if !viewModel.aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Coach Nova")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text(viewModel.aiResponse)
                        .font(.subheadline)
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Show loading state
            if viewModel.isAILoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Coach Nova is thinking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .onTapGesture {
            // Dismiss keyboard when tapping outside text field
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Methods
    
    private func sendQuestion() {
        guard !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Dismiss keyboard first
        isTextFieldFocused = false
        
        // Send to AI
        viewModel.askAI(question: questionText)
        questionText = ""
    }
}
