// VideoPlayerKit.swift
import SwiftUI
import AVKit
import AVFoundation

// Validate assets before constructing the player.
// This turns "bad URL" into a clean .failed state, not a crash.
enum VideoLoadError: LocalizedError {
    case notFound, notPlayable, zeroDuration
    var errorDescription: String? {
        switch self {
        case .notFound: return "Video file not found"
        case .notPlayable: return "Video is not playable"
        case .zeroDuration: return "Video has no duration"
        }
    }
}

func loadPlayableItem(url: URL) async throws -> AVPlayerItem {
    let path = url.path(percentEncoded: false)
    guard FileManager.default.fileExists(atPath: path) || url.isFileURL == false else {
        throw VideoLoadError.notFound
    }
    let asset = AVURLAsset(url: url)
    let (isPlayable, duration) = try await asset.load(.isPlayable, .duration)
    guard isPlayable else { throw VideoLoadError.notPlayable }
    guard duration.seconds > 0 else { throw VideoLoadError.zeroDuration }
    return AVPlayerItem(asset: asset)
}

// Main-actor ViewModel so every @Published write is on main.
@MainActor
final class VideoVM: ObservableObject {
    enum State { case idle, loading, ready(AVPlayer), failed(Error) }
    @Published private(set) var state: State = .idle

    private var timeToken: Any?
    private var player: AVPlayer?

    deinit {
        if let t = timeToken { player?.removeTimeObserver(t) }
    }

    func load(from url: URL) {
        state = .loading
        Task { [weak self] in
            do {
                let item = try await loadPlayableItem(url: url)
                let player = AVPlayer(playerItem: item)
                // periodic observer (common leak if not removed)
                self?.timeToken = player.addPeriodicTimeObserver(
                    forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                    queue: .main
                ) { [weak self] _ in
                    // keep lightweight
                    guard self != nil else { return }
                }
                self?.player = player
                self?.state = .ready(player)
            } catch {
                self?.state = .failed(error)
            }
        }
    }
}