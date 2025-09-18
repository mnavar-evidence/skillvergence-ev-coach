package com.skillvergence.mindsherpa.ui.video

import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.lifecycleScope
import androidx.media3.ui.PlayerView
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import com.mux.player.MuxPlayer
import com.mux.player.media.MediaItems
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.MuxMigrationData
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
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
    private lateinit var backButton: ImageButton
    private lateinit var fullscreenButton: View

    // Landscape/Fullscreen UI Components
    private var overlayControls: LinearLayout? = null
    private var bottomOverlay: LinearLayout? = null

    // Fullscreen state
    private var isPortraitFullscreen = false
    private var isLandscape = false
    private val overlayHandler = Handler(Looper.getMainLooper())
    private var overlayRunnable: Runnable? = null

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

    // Progress management
    private lateinit var progressStore: ProgressStore
    private var hasSeekToSavedPosition = false

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

        // Initialize views, audio manager, and progress store
        initializeViews()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        progressStore = ProgressStore.getInstance(this)

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

        // Landscape/Fullscreen specific views (may be null in portrait)
        overlayControls = findViewById(R.id.overlay_controls)
        bottomOverlay = findViewById(R.id.bottom_overlay)

        // Check if we're in landscape mode
        isLandscape = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

        if (isLandscape) {
            enableLandscapeFullscreen()
            setupOverlayHiding()
        }
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

                                // Seek to saved position if available and not already done
                                if (!hasSeekToSavedPosition) {
                                    seekToSavedPosition()
                                    hasSeekToSavedPosition = true
                                }

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
                bindControllerFullscreenButton()
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

            // Add listener for fallback player
            fallbackPlayer.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    when (playbackState) {
                        Player.STATE_READY -> {
                            logToFile(this@VideoDetailActivity, "🎬 Fallback Player state: READY")
                            totalDurationSeconds = fallbackPlayer.duration / 1000

                            // Seek to saved position if available and not already done
                            if (!hasSeekToSavedPosition) {
                                seekToSavedPosition()
                                hasSeekToSavedPosition = true
                            }

                            startProgressTracking()
                        }
                        Player.STATE_ENDED -> logToFile(this@VideoDetailActivity, "🎬 Fallback Player state: ENDED")
                    }
                }

                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    logToFile(this@VideoDetailActivity, "❌ Fallback Player error: ${error.message}")
                }
            })

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
            bindControllerFullscreenButton()

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
            onBackPressedDispatcher.onBackPressed()
        }

        fullscreenButton.setOnClickListener { handleFullscreenButtonPressed() }

        // Set up overlay hiding for landscape mode
        if (isLandscape) {
            playerView.setOnClickListener {
                toggleOverlayVisibility()
            }
        }
    }

    private fun handleFullscreenButtonPressed() {
        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            enableLandscapeFullscreen()
        } else {
            togglePortraitFullscreen()
        }
    }

    private fun bindControllerFullscreenButton() {
        val listener = View.OnClickListener { handleFullscreenButtonPressed() }
        playerView.findViewById<View>(androidx.media3.ui.R.id.exo_fullscreen)?.setOnClickListener(listener)
        playerView.findViewById<View>(androidx.media3.ui.R.id.exo_minimal_fullscreen)?.setOnClickListener(listener)
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
        try {
            val progressRecord = progressStore.getVideoProgress(videoId)
            val savedPosition = progressRecord?.lastPositionSec?.toInt() ?: 0
            logToFile(this, "📱 Loading saved progress for video: $videoId - Position: ${savedPosition}s")

            // Update current time for initial UI display
            if (savedPosition > 0) {
                currentTimeSeconds = savedPosition.toLong()
                updateProgressUI()
                logToFile(this, "📱 Restored progress UI to: ${savedPosition}s")
            }
        } catch (e: Exception) {
            logToFile(this, "❌ Failed to load saved progress: ${e.message}")
        }
    }

    private fun seekToSavedPosition() {
        try {
            val progressRecord = progressStore.getVideoProgress(videoId)
            val savedPosition = progressRecord?.lastPositionSec?.toInt() ?: 0

            if (savedPosition > 5) { // Only seek if more than 5 seconds watched
                val seekPositionMs = savedPosition * 1000L

                // Handle both Mux Player and fallback ExoPlayer
                val player = if (::muxPlayer.isInitialized) {
                    muxPlayer
                } else {
                    fallbackExoPlayer
                }

                player?.seekTo(seekPositionMs)
                currentTimeSeconds = savedPosition.toLong()
                updateProgressUI()

                logToFile(this, "📱 Seeked to saved position: ${savedPosition}s (${(savedPosition/60).toInt()}:${String.format("%02d", (savedPosition%60).toInt())})")
            } else {
                logToFile(this, "📱 No significant progress to restore (${savedPosition}s)")
            }
        } catch (e: Exception) {
            logToFile(this, "❌ Failed to seek to saved position: ${e.message}")
        }
    }

    private fun saveProgress() {
        try {
            // Save progress using the correct ProgressStore method
            progressStore.updateVideoProgress(
                videoId = videoId,
                courseId = courseId,
                currentTime = currentTimeSeconds.toDouble(),
                duration = totalDurationSeconds.toDouble(),
                isPlaying = true
            )

            // Log progress occasionally for debugging
            if (currentTimeSeconds % 10 == 0L) { // Log every 10 seconds
                logToFile(this, "📱 Progress saved: ${currentTimeSeconds}s / ${totalDurationSeconds}s")
            }
        } catch (e: Exception) {
            logToFile(this, "❌ Failed to save progress: ${e.message}")
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

    // MARK: - Fullscreen and Orientation Handling

    private fun togglePortraitFullscreen() {
        if (isLandscape) {
            // In landscape, ignore portrait fullscreen toggle
            return
        }

        isPortraitFullscreen = !isPortraitFullscreen
        logToFile(this, "🎬 Portrait fullscreen: $isPortraitFullscreen")

        if (isPortraitFullscreen) {
            enablePortraitFullscreen()
        } else {
            disablePortraitFullscreen()
        }
    }

    private fun enablePortraitFullscreen() {
        logToFile(this, "🎬 Enabling portrait fullscreen - centering video")

        // Hide the header LinearLayout using the correct ID
        val headerLayout = findViewById<LinearLayout>(R.id.header_layout)
        headerLayout?.visibility = View.GONE

        // Hide the info ScrollView using the correct ID
        val infoScrollView = findViewById<ScrollView>(R.id.info_scroll_view)
        infoScrollView?.visibility = View.GONE

        // Make video container fill available space
        val videoContainer = playerView.parent as? FrameLayout
        videoContainer?.layoutParams?.height = ViewGroup.LayoutParams.MATCH_PARENT
        videoContainer?.requestLayout()

        // Keep screen on during video playback
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }


    private fun disablePortraitFullscreen() {
        logToFile(this, "🎬 Disabling portrait fullscreen - restoring normal view")

        // Show the header LinearLayout using the correct ID
        val headerLayout = findViewById<LinearLayout>(R.id.header_layout)
        headerLayout?.visibility = View.VISIBLE

        // Show the info ScrollView using the correct ID
        val infoScrollView = findViewById<ScrollView>(R.id.info_scroll_view)
        infoScrollView?.visibility = View.VISIBLE

        // Restore original video container height (220dp)
        val videoContainer = playerView.parent as? FrameLayout
        val heightInDp = 220
        val heightInPx = (heightInDp * resources.displayMetrics.density).toInt()
        videoContainer?.layoutParams?.height = heightInPx
        videoContainer?.requestLayout()

        // Allow screen to turn off normally
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun enableLandscapeFullscreen() {
        logToFile(this, "🎬 Enabling landscape fullscreen mode")

        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Hide system UI for immersive experience
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.systemBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
        }

        // Keep screen on during video playback
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun disableLandscapeFullscreen() {
        logToFile(this, "🎬 Disabling landscape fullscreen mode")

        // Show system UI
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.systemBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        }

        WindowCompat.setDecorFitsSystemWindows(window, true)

        // Allow screen to turn off normally
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun setupOverlayHiding() {
        if (!isLandscape) return

        // Start timer to hide overlays after 3 seconds
        scheduleOverlayHiding()
    }

    private fun toggleOverlayVisibility() {
        if (!isLandscape) return

        val isVisible = overlayControls?.visibility == View.VISIBLE
        val targetVisibility = if (isVisible) View.GONE else View.VISIBLE

        overlayControls?.visibility = targetVisibility
        bottomOverlay?.visibility = targetVisibility

        if (targetVisibility == View.VISIBLE) {
            scheduleOverlayHiding()
        } else {
            cancelOverlayHiding()
        }
    }

    private fun scheduleOverlayHiding() {
        cancelOverlayHiding()
        overlayRunnable = Runnable {
            overlayControls?.visibility = View.GONE
            bottomOverlay?.visibility = View.GONE
        }
        overlayHandler.postDelayed(overlayRunnable!!, 3000) // Hide after 3 seconds
    }

    private fun cancelOverlayHiding() {
        overlayRunnable?.let { overlayHandler.removeCallbacks(it) }
        overlayRunnable = null
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)

        val newIsLandscape = newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE
        logToFile(this, "🎬 Orientation changed: ${if (newIsLandscape) "LANDSCAPE" else "PORTRAIT"}")

        if (newIsLandscape != isLandscape) {
            isLandscape = newIsLandscape

            if (isLandscape) {
                // Apply fullscreen mode immediately
                enableLandscapeFullscreen()

                // Re-initialize landscape-specific views after layout change
                overlayHandler.post {
                    overlayControls = findViewById(R.id.overlay_controls)
                    bottomOverlay = findViewById(R.id.bottom_overlay)
                    setupOverlayHiding()

                    // Set up click listener for landscape player view
                    playerView.setOnClickListener {
                        toggleOverlayVisibility()
                    }

                    // Ensure fullscreen mode is still applied after layout finishes
                    enableLandscapeFullscreen()
                }
            } else {
                disableLandscapeFullscreen()
                cancelOverlayHiding()

                // Reset portrait fullscreen state when returning to portrait
                if (isPortraitFullscreen) {
                    disablePortraitFullscreen()
                    isPortraitFullscreen = false
                }
            }
        }
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

        // Reapply fullscreen mode if in landscape
        if (isLandscape) {
            enableLandscapeFullscreen()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && isLandscape) {
            // Ensure fullscreen mode is maintained when window regains focus
            enableLandscapeFullscreen()
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
        cancelOverlayHiding()

        // Release players (they handle audio focus automatically)
        if (::muxPlayer.isInitialized) {
            muxPlayer.release()
        }
        fallbackExoPlayer?.release()
    }
}
