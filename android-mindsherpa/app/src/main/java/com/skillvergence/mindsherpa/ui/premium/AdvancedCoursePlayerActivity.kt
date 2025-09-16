package com.skillvergence.mindsherpa.ui.premium

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.skillvergence.mindsherpa.ui.video.VideoDetailActivity

/**
 * Advanced Course Player Activity - Plays premium course content
 * Uses existing VideoDetailActivity for Mux video playback
 */
class AdvancedCoursePlayerActivity : VideoDetailActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // This inherits from VideoDetailActivity so it already handles Mux video playback
        // The intent extras will be processed by the parent class

        title = "Advanced Course"
    }
}