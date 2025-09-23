package com.skillvergence.mindsherpa.ui.teacher

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import android.view.Menu
import android.view.MenuItem
import android.view.WindowManager
import android.widget.LinearLayout
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.updatePadding
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.skillvergence.mindsherpa.MainActivity
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import kotlinx.coroutines.launch

/**
 * Teacher Dashboard Activity for Android
 * Corresponds to TeacherDashboardView.swift in iOS
 */
class TeacherDashboardActivity : AppCompatActivity() {

    private val teacherViewModel: TeacherViewModel by viewModels()
    private lateinit var accessControlManager: AccessControlManager
    private lateinit var bottomNavigation: BottomNavigationView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle status bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            WindowInsetsControllerCompat(window, window.decorView).apply {
                window.statusBarColor = ContextCompat.getColor(this@TeacherDashboardActivity, R.color.purple_500)
            }
        }

        setContentView(R.layout.activity_teacher_dashboard)

        accessControlManager = AccessControlManager.getInstance(this)
        setupWindowInsets()
        setupToolbar()
        setupBottomNavigation()
        loadInitialFragment()

        // Load class data
        teacherViewModel.loadClassData()
    }

    private fun setupToolbar() {
        val toolbar = findViewById<androidx.appcompat.widget.Toolbar>(R.id.toolbar)
        // Configure toolbar directly without setting as support action bar
        toolbar?.apply {
            title = "Teacher Dashboard"
        }
    }

    private fun setupBottomNavigation() {
        bottomNavigation = findViewById(R.id.teacher_bottom_navigation)
        bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.teacher_nav_overview -> {
                    loadFragment(TeacherOverviewFragment())
                    true
                }
                R.id.teacher_nav_students -> {
                    loadFragment(TeacherStudentsFragment())
                    true
                }
                R.id.teacher_nav_certificates -> {
                    loadFragment(TeacherCertificatesFragment())
                    true
                }
                R.id.teacher_nav_progress -> {
                    loadFragment(TeacherProgressFragment())
                    true
                }
                R.id.teacher_nav_settings -> {
                    loadFragment(TeacherSettingsFragment())
                    true
                }
                else -> false
            }
        }
    }

    private fun setupWindowInsets() {
        val rootView = findViewById<LinearLayout>(R.id.root_layout)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { view, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.updatePadding(top = systemBars.top)
            insets
        }
    }

    private fun loadInitialFragment() {
        loadFragment(TeacherOverviewFragment())
        bottomNavigation.selectedItemId = R.id.teacher_nav_overview
    }

    private fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.teacher_fragment_container, fragment)
            .commit()
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.teacher_dashboard_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_exit_teacher_mode -> {
                exitTeacherMode()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun exitTeacherMode() {
        lifecycleScope.launch {
            accessControlManager.exitTeacherMode()

            // Return to student app
            val intent = Intent(this@TeacherDashboardActivity, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            finish()
        }
    }
}