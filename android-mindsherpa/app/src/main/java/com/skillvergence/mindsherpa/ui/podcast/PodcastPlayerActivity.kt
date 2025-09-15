package com.skillvergence.mindsherpa.ui.podcast

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.SeekBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bumptech.glide.Glide
import com.google.android.material.card.MaterialCardView
import com.mux.player.MuxPlayer
import com.mux.player.media.MediaItems
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.MuxMigrationData
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Dedicated Podcast Player Activity - Audio-only playback
 * Matches iOS podcast player UI with clean audio-focused design
 */
class PodcastPlayerActivity : AppCompatActivity() {

    // UI Components
    private lateinit var podcastThumbnail: ImageView
    private lateinit var podcastTitle: TextView
    private lateinit var podcastDescription: TextView
    private lateinit var episodeInfo: TextView
    private lateinit var currentTimeText: TextView
    private lateinit var totalTimeText: TextView
    private lateinit var seekBar: SeekBar
    private lateinit var playPauseButton: ImageButton
    private lateinit var skipBackwardButton: ImageButton
    private lateinit var skipForwardButton: ImageButton
    private lateinit var backButton: ImageButton
    private lateinit var loadingIndicator: ProgressBar

    // Audio Player
    private var muxPlayer: MuxPlayer? = null
    private var fallbackExoPlayer: ExoPlayer? = null
    private var currentPlayer: Player? = null
    private var currentTimeSeconds: Long = 0
    private var totalDurationSeconds: Long = 0
    private var isPlaying: Boolean = false
    private var isUserSeeking: Boolean = false

    // Progress tracking
    private val progressHandler = Handler(Looper.getMainLooper())
    private var progressRunnable: Runnable? = null

    // Audio management
    private lateinit var audioManager: AudioManager

    // Podcast data
    private var podcastId: String = ""
    private var podcastTitle_: String = ""
    private var podcastDescription_: String = ""
    private var muxPlaybackId: String = ""
    private var thumbnailUrl: String = ""
    private var episodeNumber: Int? = null
    private var courseTitle: String = ""

    companion object {
        private const val EXTRA_PODCAST_ID = "podcast_id"
        private const val EXTRA_PODCAST_TITLE = "podcast_title"
        private const val EXTRA_PODCAST_DESCRIPTION = "podcast_description"
        private const val EXTRA_MUX_PLAYBACK_ID = "mux_playback_id"
        private const val EXTRA_THUMBNAIL_URL = "thumbnail_url"
        private const val EXTRA_EPISODE_NUMBER = "episode_number"
        private const val EXTRA_COURSE_TITLE = "course_title"

        fun createIntent(
            context: Context,
            podcastId: String,
            podcastTitle: String,
            podcastDescription: String,
            muxPlaybackId: String?,
            thumbnailUrl: String,
            episodeNumber: Int?,
            courseTitle: String
        ): Intent {
            return Intent(context, PodcastPlayerActivity::class.java).apply {
                putExtra(EXTRA_PODCAST_ID, podcastId)
                putExtra(EXTRA_PODCAST_TITLE, podcastTitle)
                putExtra(EXTRA_PODCAST_DESCRIPTION, podcastDescription)
                putExtra(EXTRA_MUX_PLAYBACK_ID, muxPlaybackId)
                putExtra(EXTRA_THUMBNAIL_URL, thumbnailUrl)
                putExtra(EXTRA_EPISODE_NUMBER, episodeNumber)
                putExtra(EXTRA_COURSE_TITLE, courseTitle)
            }
        }

        private fun logToFile(context: Context, message: String) {
            try {
                val logFile = File(context.externalCacheDir, "mindsherpa_debug.log")
                val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                FileWriter(logFile, true).use { writer ->
                    writer.write("[$timestamp] [PODCAST] $message\n")
                }
                println("[PODCAST] $message")
            } catch (e: Exception) {
                println("[PODCAST] Failed to write log: $message")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_podcast_player)

        // Initialize audio manager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // Initialize views
        initializeViews()

        // Extract intent data
        extractIntentData()

        // Setup UI
        setupUI()

        // Setup click listeners
        setupClickListeners()

        // Initialize audio player
        setupAudioPlayer()
    }

    private fun initializeViews() {
        podcastThumbnail = findViewById(R.id.podcast_thumbnail)
        podcastTitle = findViewById(R.id.podcast_title)
        podcastDescription = findViewById(R.id.podcast_description)
        episodeInfo = findViewById(R.id.episode_info)
        currentTimeText = findViewById(R.id.current_time)
        totalTimeText = findViewById(R.id.total_time)
        seekBar = findViewById(R.id.seek_bar)
        playPauseButton = findViewById(R.id.play_pause_button)
        skipBackwardButton = findViewById(R.id.skip_backward_button)
        skipForwardButton = findViewById(R.id.skip_forward_button)
        backButton = findViewById(R.id.back_button)
        loadingIndicator = findViewById(R.id.loading_indicator)
    }

    private fun extractIntentData() {
        podcastId = intent.getStringExtra(EXTRA_PODCAST_ID) ?: ""
        podcastTitle_ = intent.getStringExtra(EXTRA_PODCAST_TITLE) ?: ""
        podcastDescription_ = intent.getStringExtra(EXTRA_PODCAST_DESCRIPTION) ?: ""
        muxPlaybackId = intent.getStringExtra(EXTRA_MUX_PLAYBACK_ID) ?: ""
        thumbnailUrl = intent.getStringExtra(EXTRA_THUMBNAIL_URL) ?: ""
        episodeNumber = intent.getIntExtra(EXTRA_EPISODE_NUMBER, -1).takeIf { it != -1 }
        courseTitle = intent.getStringExtra(EXTRA_COURSE_TITLE) ?: ""

        logToFile(this, "🎵 Loading podcast: $podcastTitle_")
        logToFile(this, "🎵 Mux ID: $muxPlaybackId")
        logToFile(this, "🎵 Episode: $episodeNumber")
    }

    private fun setupUI() {
        // Set podcast info
        podcastTitle.text = podcastTitle_
        podcastDescription.text = podcastDescription_

        // Set episode info
        val episodeText = buildString {
            if (courseTitle.isNotEmpty()) {
                append(courseTitle)
            }
            episodeNumber?.let { number ->
                if (isNotEmpty()) append(" • ")
                append("Episode $number")
            }
        }

        if (episodeText.isNotEmpty()) {
            episodeInfo.text = episodeText
            episodeInfo.visibility = View.VISIBLE
        } else {
            episodeInfo.visibility = View.GONE
        }

        // Load podcast thumbnail
        Glide.with(this)
            .load(thumbnailUrl)
            .placeholder(R.drawable.ic_headphones_24dp)
            .error(R.drawable.ic_headphones_24dp)
            .into(podcastThumbnail)

        // Initialize time displays
        currentTimeText.text = "0:00"
        totalTimeText.text = "0:00"

        // Setup seek bar
        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    val newPosition = (progress / 100.0 * totalDurationSeconds).toLong()
                    currentTimeText.text = formatTime(newPosition.toInt())
                }
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {
                isUserSeeking = true
            }

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                isUserSeeking = false
                val player = currentPlayer ?: muxPlayer ?: fallbackExoPlayer
                player?.let {
                    val newPosition = (seekBar!!.progress / 100.0 * totalDurationSeconds * 1000).toLong()
                    it.seekTo(newPosition)
                    logToFile(this@PodcastPlayerActivity, "🎵 Seeked to: ${formatTime((newPosition / 1000).toInt())}")
                }
            }
        })
    }

    private fun setupClickListeners() {
        backButton.setOnClickListener {
            finish()
        }

        playPauseButton.setOnClickListener {
            togglePlayPause()
        }

        skipBackwardButton.setOnClickListener {
            skipBackward()
        }

        skipForwardButton.setOnClickListener {
            skipForward()
        }
    }

    private fun setupAudioPlayer() {
        showLoading(true)

        if (muxPlaybackId.isEmpty()) {
            logToFile(this, "❌ No Mux playback ID available")
            showError("No audio stream available")
            return
        }

        try {
            logToFile(this, "🎵 Setting up Mux Player for audio-only playback...")

            // Configure for audio-only playback
            volumeControlStream = AudioManager.STREAM_MUSIC

            // Request audio focus for media playback
            val audioFocusResult = audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )

            if (audioFocusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                logToFile(this, "⚠️ Audio focus not granted")
            }

            // Create Mux Player optimized for audio
            muxPlayer = MuxPlayer.Builder(context = this)
                .enableLogcat(true)
                .applyExoConfig {
                    setHandleAudioBecomingNoisy(true)
                    setAudioAttributes(
                        androidx.media3.common.AudioAttributes.Builder()
                            .setUsage(androidx.media3.common.C.USAGE_MEDIA)
                            .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MUSIC)
                            .build(),
                        true
                    )
                    setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
                }
                .build()

            currentPlayer = muxPlayer

            // Add player listener
            muxPlayer?.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    when (playbackState) {
                        Player.STATE_IDLE -> {
                            logToFile(this@PodcastPlayerActivity, "🎵 Player state: IDLE")
                            showLoading(false)
                        }
                        Player.STATE_BUFFERING -> {
                            logToFile(this@PodcastPlayerActivity, "🎵 Player state: BUFFERING")
                            showLoading(true)
                        }
                        Player.STATE_READY -> {
                            logToFile(this@PodcastPlayerActivity, "🎵 Player state: READY")
                            showLoading(false)
                            totalDurationSeconds = (muxPlayer?.duration ?: 0) / 1000
                            totalTimeText.text = formatTime(totalDurationSeconds.toInt())

                            // Ensure proper audio routing for podcast playback
                            ensureAudioRoutingForPodcast()

                            startProgressTracking()
                        }
                        Player.STATE_ENDED -> {
                            logToFile(this@PodcastPlayerActivity, "🎵 Player state: ENDED")
                            showLoading(false)
                            onPodcastCompleted()
                        }
                    }
                }

                override fun onIsPlayingChanged(isPlayingNow: Boolean) {
                    isPlaying = isPlayingNow
                    updatePlayPauseButton()
                    logToFile(this@PodcastPlayerActivity, "🎵 Is playing: $isPlayingNow")

                    if (isPlayingNow) {
                        startProgressTracking()
                    } else {
                        stopProgressTracking()
                    }
                }

                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    logToFile(this@PodcastPlayerActivity, "❌ Mux Player error: ${error.message}")
                    logToFile(this@PodcastPlayerActivity, "🔄 Attempting fallback to ExoPlayer...")

                    // Try fallback to basic ExoPlayer
                    tryFallbackExoPlayer()
                }
            })

            // Create media item
            val mediaItem = MediaItems.builderFromMuxPlaybackId(muxPlaybackId).build()
            muxPlayer?.setMediaItem(mediaItem)
            muxPlayer?.prepare()

            logToFile(this, "🎵 Mux Player setup completed")

        } catch (e: Exception) {
            logToFile(this, "❌ Failed to setup audio player: ${e.message}")
            logToFile(this, "🔄 Attempting fallback to ExoPlayer...")
            tryFallbackExoPlayer()
        }
    }

    private fun tryFallbackExoPlayer() {
        try {
            logToFile(this, "🔄 Setting up fallback ExoPlayer for audio-only playback...")

            // Release Mux Player if it exists
            muxPlayer?.release()
            muxPlayer = null

            // Create HLS URL from Mux playback ID
            val hlsUrl = "https://stream.mux.com/$muxPlaybackId.m3u8"
            logToFile(this, "🔄 Using HLS URL: $hlsUrl")

            // Create ExoPlayer with audio-focused configuration
            fallbackExoPlayer = ExoPlayer.Builder(this)
                .setAudioAttributes(
                    androidx.media3.common.AudioAttributes.Builder()
                        .setUsage(androidx.media3.common.C.USAGE_MEDIA)
                        .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MUSIC)
                        .build(),
                    true
                )
                .setHandleAudioBecomingNoisy(true)
                .setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
                .build()

            currentPlayer = fallbackExoPlayer

            // Add listener for ExoPlayer
            fallbackExoPlayer?.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    when (playbackState) {
                        Player.STATE_IDLE -> {
                            logToFile(this@PodcastPlayerActivity, "🔄 ExoPlayer state: IDLE")
                            showLoading(false)
                        }
                        Player.STATE_BUFFERING -> {
                            logToFile(this@PodcastPlayerActivity, "🔄 ExoPlayer state: BUFFERING")
                            showLoading(true)
                        }
                        Player.STATE_READY -> {
                            logToFile(this@PodcastPlayerActivity, "🔄 ExoPlayer state: READY")
                            showLoading(false)
                            totalDurationSeconds = (fallbackExoPlayer?.duration ?: 0) / 1000
                            totalTimeText.text = formatTime(totalDurationSeconds.toInt())

                            // Enhanced audio routing for ExoPlayer
                            ensureAudioRoutingForPodcast()
                            startProgressTracking()
                        }
                        Player.STATE_ENDED -> {
                            logToFile(this@PodcastPlayerActivity, "🔄 ExoPlayer state: ENDED")
                            showLoading(false)
                            onPodcastCompleted()
                        }
                    }
                }

                override fun onIsPlayingChanged(isPlayingNow: Boolean) {
                    isPlaying = isPlayingNow
                    updatePlayPauseButton()
                    logToFile(this@PodcastPlayerActivity, "🔄 ExoPlayer is playing: $isPlayingNow")

                    if (isPlayingNow) {
                        startProgressTracking()
                    } else {
                        stopProgressTracking()
                    }
                }

                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    logToFile(this@PodcastPlayerActivity, "❌ ExoPlayer error: ${error.message}")
                    showError("Audio playback failed: ${error.message}")
                    showLoading(false)
                }
            })

            // Create media item and prepare
            val mediaItem = MediaItem.fromUri(hlsUrl)
            fallbackExoPlayer?.setMediaItem(mediaItem)
            fallbackExoPlayer?.prepare()

            logToFile(this, "🔄 Fallback ExoPlayer setup completed")

        } catch (e: Exception) {
            logToFile(this, "❌ Fallback ExoPlayer setup failed: ${e.message}")
            showError("Failed to initialize audio player")
            showLoading(false)
        }
    }

    private fun ensureAudioRoutingForPodcast() {
        try {
            logToFile(this, "🎵 Ensuring audio routing for podcast playback...")

            // Force normal audio mode (not speakerphone, not earpiece)
            audioManager.mode = AudioManager.MODE_NORMAL
            audioManager.isSpeakerphoneOn = false

            // Debug current audio state
            logToFile(this, "🔊 Audio Manager State:")
            logToFile(this, "🔊   - Mode: ${audioManager.mode}")
            logToFile(this, "🔊   - Ringer mode: ${audioManager.ringerMode}")
            logToFile(this, "🔊   - Is music active: ${audioManager.isMusicActive}")
            logToFile(this, "🔊   - Is wired headset on: ${audioManager.isWiredHeadsetOn}")
            logToFile(this, "🔊   - Is bluetooth A2DP on: ${audioManager.isBluetoothA2dpOn}")

            // Check and set reasonable volume level
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

            logToFile(this, "🔊 Music volume: $currentVolume/$maxVolume")

            if (currentVolume < 3 && maxVolume > 3) {
                val newVolume = maxVolume / 3
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, newVolume, AudioManager.FLAG_SHOW_UI)
                logToFile(this, "🔊 Boosted podcast volume from $currentVolume to $newVolume")
            }

            // Force audio to route through speakers/headphones (not earpiece)
            try {
                // This forces audio routing away from earpiece
                audioManager.setMode(AudioManager.MODE_NORMAL)
                audioManager.isSpeakerphoneOn = false

                logToFile(this, "🎵 Forced normal audio routing")
            } catch (e: Exception) {
                logToFile(this, "⚠️ Could not set audio mode: ${e.message}")
            }

            // Additional debug for audio focus
            debugAudioFocusState()

            logToFile(this, "🎵 Audio routing configuration completed")

        } catch (e: Exception) {
            logToFile(this, "❌ Error configuring audio routing: ${e.message}")
        }
    }

    private fun debugAudioFocusState() {
        try {
            // Check if we have audio focus
            val hasAudioFocus = audioManager.isMusicActive
            logToFile(this, "🎵 Has audio focus (music active): $hasAudioFocus")

            // Check player audio session
            if (muxPlayer != null) {
                // For Mux Player, we need to access the underlying ExoPlayer
                try {
                    // Try to get audio session ID from Mux Player
                    logToFile(this, "🎵 Using Mux Player for audio session debugging")
                    logToFile(this, "🎵 Mux Player volume: ${muxPlayer!!.volume}")

                    // Note: Audio session ID might not be directly accessible on MuxPlayer
                    // This is mainly for debugging, so we'll skip it if not available
                    logToFile(this, "🎵 Mux Player state: Ready and configured")

                } catch (e: Exception) {
                    logToFile(this, "⚠️ Could not access Mux Player audio session: ${e.message}")
                }
            } else if (fallbackExoPlayer != null) {
                // For ExoPlayer, we can access audioSessionId directly
                try {
                    val audioSessionId = fallbackExoPlayer!!.audioSessionId
                    logToFile(this, "🎵 ExoPlayer audio session ID: $audioSessionId")
                    logToFile(this, "🎵 ExoPlayer volume: ${fallbackExoPlayer!!.volume}")

                    if (audioSessionId == android.media.AudioManager.AUDIO_SESSION_ID_GENERATE) {
                        logToFile(this, "⚠️ Audio session ID not yet generated")
                    }
                } catch (e: Exception) {
                    logToFile(this, "⚠️ Could not access ExoPlayer audio session: ${e.message}")
                }
            }

        } catch (e: Exception) {
            logToFile(this, "❌ Error debugging audio focus: ${e.message}")
        }
    }

    private fun togglePlayPause() {
        val player = currentPlayer ?: muxPlayer ?: fallbackExoPlayer
        player?.let {
            if (isPlaying) {
                it.pause()
                logToFile(this, "⏸️ Podcast paused")
            } else {
                it.play()
                logToFile(this, "▶️ Podcast resumed")
            }
        }
    }

    private fun skipBackward() {
        val player = currentPlayer ?: muxPlayer ?: fallbackExoPlayer
        player?.let {
            val newPosition = maxOf(0, it.currentPosition - 15000) // 15 seconds back
            it.seekTo(newPosition)
            logToFile(this, "⏪ Skipped backward 15 seconds")
        }
    }

    private fun skipForward() {
        val player = currentPlayer ?: muxPlayer ?: fallbackExoPlayer
        player?.let {
            val newPosition = minOf(it.duration, it.currentPosition + 15000) // 15 seconds forward
            it.seekTo(newPosition)
            logToFile(this, "⏩ Skipped forward 15 seconds")
        }
    }

    private fun updatePlayPauseButton() {
        playPauseButton.setImageResource(
            if (isPlaying) R.drawable.ic_pause_24dp else R.drawable.ic_play_circle_24dp
        )
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
        val player = currentPlayer ?: muxPlayer ?: fallbackExoPlayer
        player?.let {
            if (!isUserSeeking && it.duration > 0) {
                currentTimeSeconds = it.currentPosition / 1000
                totalDurationSeconds = it.duration / 1000

                // Update UI
                currentTimeText.text = formatTime(currentTimeSeconds.toInt())
                totalTimeText.text = formatTime(totalDurationSeconds.toInt())

                val progressPercent = ((currentTimeSeconds.toDouble() / totalDurationSeconds) * 100).toInt()
                seekBar.progress = progressPercent
            }
        }
    }

    private fun onPodcastCompleted() {
        logToFile(this, "🎓 Podcast completed: $podcastTitle_")
        // TODO: Mark podcast as completed, save progress
        updatePlayPauseButton()
    }

    private fun showLoading(show: Boolean) {
        loadingIndicator.visibility = if (show) View.VISIBLE else View.GONE
        playPauseButton.isEnabled = !show
        skipBackwardButton.isEnabled = !show
        skipForwardButton.isEnabled = !show
        seekBar.isEnabled = !show
    }

    private fun showError(message: String) {
        // TODO: Show error UI
        logToFile(this, "❌ Error: $message")
    }

    private fun formatTime(seconds: Int): String {
        val minutes = seconds / 60
        val remainingSeconds = seconds % 60
        return String.format("%d:%02d", minutes, remainingSeconds)
    }

    override fun onPause() {
        super.onPause()
        // Keep playing in background - don't pause the player
        stopProgressTracking()
    }

    override fun onResume() {
        super.onResume()
        startProgressTracking()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopProgressTracking()

        // Release audio focus
        audioManager.abandonAudioFocus(null)

        // Release all players
        muxPlayer?.release()
        muxPlayer = null
        fallbackExoPlayer?.release()
        fallbackExoPlayer = null
        currentPlayer = null
    }
}