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
import androidx.media3.ui.PlayerView
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import com.mux.player.MuxPlayer
import com.mux.player.media.MediaItems
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
open class VideoDetailActivity : AppCompatActivity() {

    // UI Components
    private lateinit var playerView: PlayerView
    private lateinit var muxPlayer: MuxPlayer
    private var fallbackExoPlayer: ExoPlayer? = null
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

        // Initialize views and audio manager
        initializeViews()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

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
        logToFile(this, "🎬 Starting Mux Player setup...")
        logToFile(this, "🎬 Video ID: $videoId")
        logToFile(this, "🎬 Mux Playback ID: $muxPlaybackId")

        if (muxPlaybackId.isNotEmpty()) {
            try {
                // Force audio stream type to MUSIC for proper routing
                volumeControlStream = AudioManager.STREAM_MUSIC
                logToFile(this, "🎬 Set volume control stream to MUSIC")

                // Create Mux Player with proper configuration
                logToFile(this, "🎬 Creating Mux Player...")
                muxPlayer = MuxPlayer.Builder(context = this)
                    .enableLogcat(true)
                    .applyExoConfig {
                        setHandleAudioBecomingNoisy(true)
                        setAudioAttributes(
                            androidx.media3.common.AudioAttributes.Builder()
                                .setUsage(androidx.media3.common.C.USAGE_MEDIA)
                                .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
                                .build(),
                            true // Handle audio focus automatically
                        )
                        setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
                    }
                    .build()
                logToFile(this, "🎬 Mux Player created successfully")

                // Add player listener for state changes
                muxPlayer.addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        when (playbackState) {
                            Player.STATE_IDLE -> logToFile(this@VideoDetailActivity, "🎬 Player state: IDLE")
                            Player.STATE_BUFFERING -> logToFile(this@VideoDetailActivity, "🎬 Player state: BUFFERING")
                            Player.STATE_READY -> {
                                logToFile(this@VideoDetailActivity, "🎬 Player state: READY - Video loaded successfully!")
                                logToFile(this@VideoDetailActivity, "🎬 Duration: ${muxPlayer.duration}ms")
                                totalDurationSeconds = muxPlayer.duration / 1000

                                startProgressTracking()
                            }
                            Player.STATE_ENDED -> logToFile(this@VideoDetailActivity, "🎬 Player state: ENDED")
                        }
                    }

                    override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                        logToFile(this@VideoDetailActivity, "❌ Mux Player error: ${error.message}")
                        logToFile(this@VideoDetailActivity, "❌ Error code: ${error.errorCode}")
                        error.printStackTrace()
                    }

                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        logToFile(this@VideoDetailActivity, "🎬 Is playing: $isPlaying")
                        if (isPlaying) {
                            startProgressTracking()
                        } else {
                            stopProgressTracking()
                        }
                    }

                    override fun onAudioSessionIdChanged(audioSessionId: Int) {
                        logToFile(this@VideoDetailActivity, "🎵 Audio session ID changed: $audioSessionId")
                    }

                    override fun onVolumeChanged(volume: Float) {
                        logToFile(this@VideoDetailActivity, "🔊 Player volume changed: $volume")
                    }
                })

                // Create media item with Mux playback ID
                logToFile(this, "🎬 Creating media item with playback ID: $muxPlaybackId")
                val mediaItem = MediaItems.builderFromMuxPlaybackId(muxPlaybackId)
                    .build()
                logToFile(this, "🎬 Media item created successfully")

                // Set player volume to ensure audibility
                muxPlayer.volume = 1.0f

                // Set media item and prepare
                logToFile(this, "🎬 Setting media item and preparing...")
                muxPlayer.setMediaItem(mediaItem)
                muxPlayer.prepare()
                logToFile(this, "🎬 Player prepared")

                // Connect player to view
                logToFile(this, "🎬 Connecting player to view...")
                playerView.player = muxPlayer
                logToFile(this, "🎬 Player connected to view")

                // Don't start playback automatically - let user press play
                logToFile(this, "🎬 Player ready - waiting for user to press play")

                logToFile(this, "🎬 Mux Player setup completed for ID: $muxPlaybackId")

            } catch (e: Exception) {
                logToFile(this, "❌ Failed to setup Mux Player: ${e.message}")
                logToFile(this, "❌ Stack trace: ${e.stackTraceToString()}")
                e.printStackTrace()
            }
        } else {
            logToFile(this, "❌ No Mux playback ID available for video: $videoId")
            logToFile(this, "❌ Available data - Title: $videoTitle, Description: $videoDescription")

            // Fallback: Try to use basic ExoPlayer with HLS URL if available
            setupFallbackPlayer()
        }
    }

    private fun setupFallbackPlayer() {
        logToFile(this, "🎬 Setting up fallback ExoPlayer...")

        // Try to get the Mux HLS URL from the playback ID
        val muxHlsUrl = if (muxPlaybackId.isNotEmpty()) {
            "https://stream.mux.com/$muxPlaybackId.m3u8"
        } else {
            // If no Mux ID, this will fail - but we'll log it
            logToFile(this, "❌ Cannot create fallback - no Mux playback ID")
            return
        }

        try {
            // Configure audio attributes and let ExoPlayer handle focus
            val audioAttrs = androidx.media3.common.AudioAttributes.Builder()
                .setUsage(androidx.media3.common.C.USAGE_MEDIA)
                .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
                .build()

            // Create ExoPlayer with automatic audio focus handling
            val fallbackPlayer = ExoPlayer.Builder(this)
                .setAudioAttributes(audioAttrs, /* handleAudioFocus= */ true)
                .setHandleAudioBecomingNoisy(true)
                .setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
                .build()

            // Set player volume to ensure audibility
            fallbackPlayer.volume = 1.0f

            // Create media item from HLS URL
            val mediaItem = MediaItem.fromUri(muxHlsUrl)

            // Configure player
            fallbackPlayer.setMediaItem(mediaItem)
            fallbackPlayer.prepare()

            // Don't start playback automatically - let user press play
            logToFile(this, "🎬 Fallback player ready - waiting for user to press play")

            // Connect to view
            playerView.player = fallbackPlayer

            // Store reference for cleanup
            fallbackExoPlayer = fallbackPlayer

            logToFile(this, "🎬 Fallback ExoPlayer setup completed with URL: $muxHlsUrl")

        } catch (e: Exception) {
            logToFile(this, "❌ Fallback player setup failed: ${e.message}")
            e.printStackTrace()
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
        // Handle both Mux Player and fallback ExoPlayer
        val player = if (::muxPlayer.isInitialized) {
            muxPlayer
        } else {
            fallbackExoPlayer
        }

        if (player != null && player.duration > 0) {
            currentTimeSeconds = player.currentPosition / 1000
            totalDurationSeconds = player.duration / 1000

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


    override fun onPause() {
        super.onPause()
        if (::muxPlayer.isInitialized) {
            muxPlayer.pause()
        }
        fallbackExoPlayer?.pause()
        stopProgressTracking()
        saveProgress()
    }

    override fun onResume() {
        super.onResume()
        if (::muxPlayer.isInitialized || fallbackExoPlayer != null) {
            startProgressTracking()
        }
    }

    override fun onStop() {
        super.onStop()
        if (::muxPlayer.isInitialized) {
            muxPlayer.pause()
        }
        fallbackExoPlayer?.pause()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopProgressTracking()
        saveProgress()

        // Release players (they handle audio focus automatically)
        if (::muxPlayer.isInitialized) {
            muxPlayer.release()
        }
        fallbackExoPlayer?.release()
    }
}