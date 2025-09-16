//
//  CourseModuleViews.swift
//  mindsherpa
//
//  Created by Claude on 9/15/25.
//

import SwiftUI

// MARK: - Generic Module List View
struct GenericModuleListView<T: CourseModule>: View {
    let course: AdvancedCourse
    let modules: [T]
    @Binding var selectedModule: T?
    let onAppear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(modules.count) modules")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }

                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.05))

                // Module list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modules) { module in
                            CourseModuleCard(module: module) {
                                selectedModule = module
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                onAppear()
            }
        }
    }
}

// MARK: - Helper Function for Duration Fetching
@MainActor
func fetchRealDurationsForModules<T: CourseModule>(_ modules: [T], completion: @escaping ([T]) -> Void) {

    for (index, module) in modules.enumerated() {
        Task {
            do {
                let duration = try await MuxVideoMetadata.getVideoDuration(muxPlaybackId: module.muxPlaybackId)
                let durationMinutes = max(1, Int(duration / 60))


                // Create updated modules array on main actor
                await MainActor.run {
                    var updatedModules = modules
                    updatedModules[index].estimatedMinutes = durationMinutes
                    completion(updatedModules)
                }
            } catch {
            }
        }
    }
}