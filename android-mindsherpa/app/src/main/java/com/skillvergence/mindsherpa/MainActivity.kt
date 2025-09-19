package com.skillvergence.mindsherpa

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.findNavController
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupActionBarWithNavController
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import com.skillvergence.mindsherpa.ui.teacher.TeacherDashboardActivity

class MainActivity : AppCompatActivity() {

    private lateinit var accessControlManager: AccessControlManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        accessControlManager = AccessControlManager.getInstance(this)

        // Check if teacher mode is enabled
        accessControlManager.isTeacherModeEnabled.observe(this) { isTeacherMode ->
            if (isTeacherMode) {
                // Navigate to teacher dashboard
                val intent = Intent(this, TeacherDashboardActivity::class.java)
                startActivity(intent)
                finish()
                return@observe
            }
        }

        setContentView(R.layout.activity_main)

        // Temporarily disable toolbar setup to resolve action bar conflict
        // val toolbar: MaterialToolbar = findViewById(R.id.toolbar)
        // setSupportActionBar(toolbar)

        val navView: BottomNavigationView = findViewById(R.id.nav_view)
        val navController = findNavController(R.id.nav_host_fragment_activity_main)

        // Set up navigation with bottom navigation view
        // Temporarily disable action bar configuration
        // val appBarConfiguration = AppBarConfiguration(
        //     setOf(
        //         R.id.navigation_video,
        //         R.id.navigation_podcast,
        //         R.id.navigation_premium,
        //         R.id.navigation_profile
        //     )
        // )
        // setupActionBarWithNavController(navController, appBarConfiguration)
        navView.setupWithNavController(navController)
    }

    override fun onResume() {
        super.onResume()
        // Check teacher mode status when returning to activity
        if (accessControlManager.isTeacherModeEnabled.value == true) {
            val intent = Intent(this, TeacherDashboardActivity::class.java)
            startActivity(intent)
            finish()
        }
    }
}