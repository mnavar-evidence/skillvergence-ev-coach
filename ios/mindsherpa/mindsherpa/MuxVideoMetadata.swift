//
//  MuxVideoMetadata.swift
//  mindsherpa
//
//  Created by Claude on 9/15/25.
//

import Foundation
@preconcurrency import MuxPlayerSwift
import AVFoundation
@preconcurrency import AVKit

// MARK: - Mux Video Metadata Utility

struct MuxVideoMetadata {

    /// Fetches the real video duration from Mux for a given playback ID
    /// - Parameter muxPlaybackId: The Mux playback ID
    /// - Returns: Duration in seconds, or throws an error if unable to fetch
    @MainActor
    static func getVideoDuration(muxPlaybackId: String) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in

            // Create AVPlayerViewController with Mux playback ID (same approach as existing code)
            let muxPlayerViewController = AVPlayerViewController(playbackID: muxPlaybackId)
            guard let player = muxPlayerViewController.player else {
                continuation.resume(throwing: MuxVideoMetadataError.noData)
                return
            }

            // Create observer for when duration becomes available
            var durationObserver: NSKeyValueObservation?
            var hasResumed = false

            // Timeout after 30 seconds
            Task {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                if !hasResumed {
                    hasResumed = true
                    durationObserver?.invalidate()
                    continuation.resume(throwing: MuxVideoMetadataError.timeout)
                }
            }

            // Observe duration changes
            durationObserver = player.observe(\.currentItem?.duration, options: [.new]) { player, change in
                if let duration = change.newValue, let durationValue = duration {
                    let seconds = CMTimeGetSeconds(durationValue)

                    if seconds.isFinite && seconds > 0 && !hasResumed {

                        // Clean up
                        hasResumed = true
                        durationObserver?.invalidate()

                        // Resume with the duration
                        continuation.resume(returning: seconds)
                    }
                }
            }

            // Also check if duration is already available
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if let duration = player.currentItem?.duration, !hasResumed {
                    let seconds = CMTimeGetSeconds(duration)
                    if seconds.isFinite && seconds > 0 {

                        hasResumed = true
                        durationObserver?.invalidate()
                        continuation.resume(returning: seconds)
                    }
                }
            }
        }
    }

    /// Formats duration in seconds to a human-readable string
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string like "1h 23m" or "45m"
    static func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Error Types

enum MuxVideoMetadataError: Error, LocalizedError {
    case timeout
    case invalidPlaybackId
    case noData

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Timeout while fetching video duration"
        case .invalidPlaybackId:
            return "Invalid Mux playback ID"
        case .noData:
            return "No duration data available"
        }
    }
}