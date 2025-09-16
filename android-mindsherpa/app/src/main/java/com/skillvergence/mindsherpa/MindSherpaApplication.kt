package com.skillvergence.mindsherpa

import android.app.Application
import com.skillvergence.mindsherpa.data.SubscriptionManager

/**
 * MindSherpa Application - Initializes app-wide services
 */
class MindSherpaApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize subscription manager
        SubscriptionManager.initialize(this)
    }
}