package com.skillvergence.mindsherpa.utils

import android.content.Context
import androidx.media3.common.Player
import com.mux.player.MuxPlayer
import com.mux.player.media.MediaItems
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Utility to fetch video metadata from Mux without displaying video player
 * Gets real video duration for course modules
 */
object MuxVideoMetadata {

    /**
     * Get video duration from Mux playback ID
     * Returns duration in seconds, or null if failed
     */
    suspend fun getVideoDuration(context: Context, muxPlaybackId: String): Int? {
        return suspendCancellableCoroutine { continuation ->
            try {
                // Create a lightweight MuxPlayer just for metadata
                val metadataPlayer = MuxPlayer.Builder(context = context)
                    .enableLogcat(false) // Disable logging for metadata fetching
                    .build()

                var hasResumed = false

                // Add listener for when metadata is loaded
                metadataPlayer.addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        if (playbackState == Player.STATE_READY && !hasResumed) {
                            hasResumed = true
                            val durationMs = metadataPlayer.duration
                            val durationSeconds = if (durationMs > 0) (durationMs / 1000).toInt() else null

                            // Clean up player
                            metadataPlayer.release()

                            // Resume coroutine with result
                            continuation.resume(durationSeconds)
                        }
                    }

                    override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                        if (!hasResumed) {
                            hasResumed = true
                            metadataPlayer.release()
                            continuation.resume(null)
                        }
                    }
                })

                // Set up cancellation
                continuation.invokeOnCancellation {
                    metadataPlayer.release()
                }

                // Load media item to get metadata
                val mediaItem = MediaItems.builderFromMuxPlaybackId(muxPlaybackId).build()
                metadataPlayer.setMediaItem(mediaItem)
                metadataPlayer.prepare()

                // Don't call play() - we just want metadata

            } catch (e: Exception) {
                continuation.resume(null)
            }
        }
    }

    /**
     * Format seconds to MM:SS format
     */
    fun formatDuration(seconds: Int): String {
        val minutes = seconds / 60
        val remainingSeconds = seconds % 60
        return String.format("%d:%02d", minutes, remainingSeconds)
    }

    /**
     * Format seconds to "X min" format for course lists
     */
    fun formatDurationMinutes(seconds: Int): String {
        val minutes = (seconds + 30) / 60 // Round to nearest minute
        return "$minutes min"
    }
}