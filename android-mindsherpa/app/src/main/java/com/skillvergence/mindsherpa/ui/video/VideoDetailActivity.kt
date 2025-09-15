package com.skillvergence.mindsherpa.ui.video

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.ui.PlayerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.MuxMigrationData
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Video Detail Activity with Mux Player
 * Matches iOS UnifiedVideoPlayer functionality
 * Handles both basic and advanced course videos with Mux streaming
 */
class VideoDetailActivity : AppCompatActivity() {

    // UI Components
    private lateinit var playerView: PlayerView
    private lateinit var exoPlayer: ExoPlayer
    private lateinit var videoTitle: TextView
    private lateinit var videoDescription: TextView
    private lateinit var videoDuration: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var progressText: TextView
    private lateinit var backButton: TextView
    private lateinit var fullscreenButton: View

    // Video data
    private var videoId: String = ""
    private var courseId: String = ""
    private var muxPlaybackId: String = ""

    // Progress tracking
    private var currentTimeSeconds: Long = 0
    private var totalDurationSeconds: Long = 0
    private val progressHandler = Handler(Looper.getMainLooper())
    private var progressRunnable: Runnable? = null

    // Audio management
    private lateinit var audioManager: AudioManager

    companion object {
        private const val EXTRA_VIDEO_ID = "video_id"
        private const val EXTRA_VIDEO_TITLE = "video_title"
        private const val EXTRA_VIDEO_DESCRIPTION = "video_description"
        private const val EXTRA_VIDEO_DURATION = "video_duration"
        private const val EXTRA_COURSE_ID = "course_id"
        private const val EXTRA_MUX_PLAYBACK_ID = "mux_playback_id"

        fun createIntent(
            context: Context,
            videoId: String,
            videoTitle: String,
            videoDescription: String,
            videoDuration: Int,
            courseId: String,
            muxPlaybackId: String? = null
        ): Intent {
            return Intent(context, VideoDetailActivity::class.java).apply {
                putExtra(EXTRA_VIDEO_ID, videoId)
                putExtra(EXTRA_VIDEO_TITLE, videoTitle)
                putExtra(EXTRA_VIDEO_DESCRIPTION, videoDescription)
                putExtra(EXTRA_VIDEO_DURATION, videoDuration)
                putExtra(EXTRA_COURSE_ID, courseId)
                putExtra(EXTRA_MUX_PLAYBACK_ID, muxPlaybackId)
            }
        }

        private fun logToFile(context: Context, message: String) {
            try {
                val logFile = File(context.externalCacheDir, "mindsherpa_debug.log")
                val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                FileWriter(logFile, true).use { writer ->
                    writer.write("[$timestamp] $message\n")
                }
                println(message) // Also print to console
            } catch (e: Exception) {
                println("Failed to write log: $message")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_detail)

        // Initialize views
        initializeViews()

        // Get video data from intent
        extractIntentData()

        // Set up video player
        setupVideoPlayer()

        // Set up UI
        setupUI()

        // Set up click listeners
        setupClickListeners()
    }

    private fun initializeViews() {
        playerView = findViewById(R.id.player_view)
        videoTitle = findViewById(R.id.video_title)
        videoDescription = findViewById(R.id.video_description)
        videoDuration = findViewById(R.id.video_duration)
        progressBar = findViewById(R.id.video_progress_bar)
        progressText = findViewById(R.id.progress_text)
        backButton = findViewById(R.id.back_button)
        fullscreenButton = findViewById(R.id.fullscreen_button)
    }


    private fun extractIntentData() {
        videoId = intent.getStringExtra(EXTRA_VIDEO_ID) ?: ""
        courseId = intent.getStringExtra(EXTRA_COURSE_ID) ?: ""
        val title = intent.getStringExtra(EXTRA_VIDEO_TITLE) ?: ""
        val description = intent.getStringExtra(EXTRA_VIDEO_DESCRIPTION) ?: ""
        val duration = intent.getIntExtra(EXTRA_VIDEO_DURATION, 0)

        // Get muxPlaybackId from intent or fall back to migration data
        muxPlaybackId = intent.getStringExtra(EXTRA_MUX_PLAYBACK_ID)
            ?: MuxMigrationData.getMuxPlaybackId(videoId)
            ?: ""

        totalDurationSeconds = duration.toLong()

        logToFile(this, "🎬 Video Detail - Video: $videoId")
        logToFile(this, "🎬 Video Detail - Title: $title")
        logToFile(this, "🎬 Video Detail - Mux ID: $muxPlaybackId")
        logToFile(this, "🎬 Video Detail - Duration: ${duration}s")

        // Set UI data
        videoTitle.text = title
        videoDescription.text = description
        videoDuration.text = formatTime(duration)
    }

    private fun setupVideoPlayer() {
        if (muxPlaybackId.isNotEmpty()) {
            try {
                // Create ExoPlayer instance with audio attributes
                // Let ExoPlayer handle audio focus automatically (like iOS AVPlayerViewController)
                exoPlayer = ExoPlayer.Builder(this)
                    .setAudioAttributes(
                        androidx.media3.common.AudioAttributes.Builder()
                            .setUsage(androidx.media3.common.C.USAGE_MEDIA)
                            .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
                            .build(),
                        true // Let ExoPlayer handle audio focus automatically
                    )
                    .build()

                // Create Mux HLS URL from playback ID
                val muxUrl = "https://stream.mux.com/$muxPlaybackId.m3u8"

                // Create media item
                val mediaItem = MediaItem.fromUri(muxUrl)

                // Configure player
                exoPlayer.apply {
                    setMediaItem(mediaItem)
                    prepare()
                    // Start playback automatically (like iOS) - ExoPlayer will handle audio focus
                    playWhenReady = true

                    // Set up player listeners
                    addListener(object : Player.Listener {
                        override fun onPlaybackStateChanged(playbackState: Int) {
                            when (playbackState) {
                                Player.STATE_READY -> {
                                    logToFile(this@VideoDetailActivity, "🎬 Mux Player ready")
                                    totalDurationSeconds = (duration) / 1000
                                    startProgressTracking()
                                    testAudioStream() // Test audio format
                                }
                                Player.STATE_ENDED -> {
                                    logToFile(this@VideoDetailActivity, "🎬 Video playback ended")
                                    onVideoCompleted()
                                }
                            }
                        }

                        override fun onIsPlayingChanged(isPlaying: Boolean) {
                            if (isPlaying) {
                                startProgressTracking()
                            } else {
                                stopProgressTracking()
                            }
                        }

                        override fun onAudioSessionIdChanged(audioSessionId: Int) {
                            logToFile(this@VideoDetailActivity, "🎵 Audio session ID: $audioSessionId")
                        }

                        override fun onVolumeChanged(volume: Float) {
                            logToFile(this@VideoDetailActivity, "🔊 Volume changed: $volume")
                        }
                    })
                }

                // Connect player to view
                playerView.player = exoPlayer

                logToFile(this, "🎬 Mux Player setup completed for ID: $muxPlaybackId")

            } catch (e: Exception) {
                logToFile(this, "❌ Failed to setup Mux Player: ${e.message}")
                e.printStackTrace()
            }
        } else {
            logToFile(this, "❌ No Mux playback ID available for video: $videoId")
        }
    }


    private fun setupUI() {
        // Set initial progress
        updateProgressUI()

        // Load saved progress if available
        loadSavedProgress()
    }

    private fun setupClickListeners() {
        backButton.setOnClickListener {
            finish()
        }

        fullscreenButton.setOnClickListener {
            // TODO: Implement fullscreen mode
            logToFile(this, "🎬 Fullscreen requested")
        }
    }

    private fun startProgressTracking() {
        stopProgressTracking()

        progressRunnable = object : Runnable {
            override fun run() {
                updateProgress()
                progressHandler.postDelayed(this, 1000) // Update every second
            }
        }
        progressRunnable?.let { progressHandler.post(it) }
    }

    private fun stopProgressTracking() {
        progressRunnable?.let { progressHandler.removeCallbacks(it) }
        progressRunnable = null
    }

    private fun updateProgress() {
        if (::exoPlayer.isInitialized && exoPlayer.duration > 0) {
            currentTimeSeconds = exoPlayer.currentPosition / 1000
            totalDurationSeconds = exoPlayer.duration / 1000

            updateProgressUI()
            saveProgress()

            // Check for completion (90% watched)
            if (totalDurationSeconds > 0 && currentTimeSeconds.toDouble() / totalDurationSeconds >= 0.9) {
                onVideoCompleted()
            }
        }
    }

    private fun updateProgressUI() {
        if (totalDurationSeconds > 0) {
            val progressPercent = (currentTimeSeconds.toDouble() / totalDurationSeconds * 100).toInt()
            progressBar.progress = progressPercent
            progressText.text = "${formatTime(currentTimeSeconds.toInt())} / ${formatTime(totalDurationSeconds.toInt())}"
        }
    }

    private fun loadSavedProgress() {
        // TODO: Load saved progress from local storage or API
        // For now, just log
        logToFile(this, "📱 Loading saved progress for video: $videoId")
    }

    private fun saveProgress() {
        // TODO: Save progress to local storage and/or API
        // For now, just log occasionally
        if (currentTimeSeconds % 10 == 0L) { // Log every 10 seconds
            logToFile(this, "📱 Progress: ${currentTimeSeconds}s / ${totalDurationSeconds}s")
        }
    }

    private fun onVideoCompleted() {
        logToFile(this, "🎓 Video completed: $videoId")
        // TODO: Mark video as completed, award XP, update progress
        // TODO: Generate certificate if applicable
    }

    private fun formatTime(seconds: Int): String {
        val minutes = seconds / 60
        val remainingSeconds = seconds % 60
        return String.format("%d:%02d", minutes, remainingSeconds)
    }

    private fun formatTime(seconds: Long): String {
        return formatTime(seconds.toInt())
    }

    private fun configureAudioForVideoPlayback() {
        // Simplified audio configuration - let the system handle routing
        // (like iOS AVAudioSession.setCategory(.playback) without forcing speakerphone)
        try {
            audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            // Check if music volume is muted and log info
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

            logToFile(this, "🎵 Audio ready for video playback - Volume: $currentVolume/$maxVolume")

        } catch (e: Exception) {
            logToFile(this, "❌ Failed to check audio configuration: ${e.message}")
        }
    }

    private fun testAudioStream() {
        // Test if the Mux HLS stream actually contains audio
        val muxUrl = "https://stream.mux.com/$muxPlaybackId.m3u8"
        logToFile(this, "🎵 Testing audio stream: $muxUrl")

        // Check ExoPlayer audio renderer status
        exoPlayer.audioFormat?.let { format ->
            logToFile(this, "🎵 Audio format: ${format.sampleMimeType}, channels: ${format.channelCount}")
        } ?: logToFile(this, "❌ No audio format detected")

        // Check if audio is enabled and volume
        logToFile(this, "🔊 ExoPlayer volume: ${exoPlayer.volume}")
        logToFile(this, "🔊 Audio device volume: ${audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)}/${audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)}")
    }

    override fun onPause() {
        super.onPause()
        if (::exoPlayer.isInitialized) {
            exoPlayer.pause()
        }
        stopProgressTracking()
        saveProgress()
    }

    override fun onResume() {
        super.onResume()
        if (::exoPlayer.isInitialized) {
            startProgressTracking()
        }
    }

    override fun onStop() {
        super.onStop()
        if (::exoPlayer.isInitialized) {
            exoPlayer.pause()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopProgressTracking()
        saveProgress()

        // Release player - ExoPlayer will handle audio focus automatically
        if (::exoPlayer.isInitialized) {
            exoPlayer.release()
        }
    }
}