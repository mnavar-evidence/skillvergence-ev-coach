package com.skillvergence.mindsherpa.ui.paywall

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import com.skillvergence.mindsherpa.ui.codes.CodeEntryActivity
import com.skillvergence.mindsherpa.ui.profile.NameCollectionActivity
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Paywall Activity for Android
 * Corresponds to PaywallView.swift in iOS
 */
class PaywallActivity : AppCompatActivity() {

    private lateinit var accessControlManager: AccessControlManager
    private lateinit var progressStore: ProgressStore
    private lateinit var xpProgressText: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var friendCodeButton: Button
    private lateinit var classJoinButton: Button
    private lateinit var individualPurchaseButton: Button
    private lateinit var maybeLatButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_paywall)

        accessControlManager = AccessControlManager.getInstance(this)
        progressStore = ProgressStore.getInstance(this)

        setupViews()
        setupListeners()
        updateProgressDisplay()
    }

    private fun setupViews() {
        xpProgressText = findViewById(R.id.xp_progress_text)
        progressBar = findViewById(R.id.xp_progress_bar)
        friendCodeButton = findViewById(R.id.friend_code_button)
        classJoinButton = findViewById(R.id.class_join_button)
        individualPurchaseButton = findViewById(R.id.individual_purchase_button)
        maybeLatButton = findViewById(R.id.maybe_later_button)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Unlock Basic Access"
            setDisplayHomeAsUpEnabled(false)
        }

        // Set access information
        findViewById<TextView>(R.id.organization_name).text = "Electric Vehicle Training Program"
        findViewById<TextView>(R.id.program_name).text = "Professional Skills Training"
        findViewById<TextView>(R.id.instructor_name).text = ""
        findViewById<TextView>(R.id.instructor_email).text = ""
    }

    private fun setupListeners() {
        friendCodeButton.setOnClickListener {
            val intent = Intent(this, CodeEntryActivity::class.java)
            intent.putExtra("code_type", "friend")
            startActivity(intent)
        }

        classJoinButton.setOnClickListener {
            showClassJoinDialog()
        }

        individualPurchaseButton.setOnClickListener {
            simulateIndividualPurchase()
        }

        maybeLatButton.setOnClickListener {
            finish()
        }
    }

    private fun showClassJoinDialog() {
        // For now, create a simple dialog to collect class join code
        val builder = androidx.appcompat.app.AlertDialog.Builder(this)
        val input = android.widget.EditText(this)
        input.hint = "Enter class code (e.g., JOHNSON123)"
        input.inputType = android.text.InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS

        builder.setTitle("Join a Class")
            .setMessage("Enter your teacher's class code to join their class and get basic access.")
            .setView(input)
            .setPositiveButton("Join Class") { _, _ ->
                val classCode = input.text.toString().trim().uppercase()
                if (classCode.isNotEmpty()) {
                    processClassJoinCode(classCode)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun processClassJoinCode(classCode: String) {
        lifecycleScope.launch {
            // Simulate class validation
            delay(1000)

            // For now, accept any code that looks like a class code
            if (classCode.length >= 4) {
                // Teacher name will be fetched from database via API
                val teacherName = "Loading teacher info..."

                // Store teacher assignment
                progressStore.setAssignedTeacher(teacherName, classCode)

                // Show name collection
                val intent = Intent(this@PaywallActivity, NameCollectionActivity::class.java)
                intent.putExtra("from_class_join", true)
                startActivity(intent)

                finish()
            } else {
                android.widget.Toast.makeText(this@PaywallActivity,
                    "Invalid class code. Please check with your teacher.",
                    android.widget.Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun updateProgressDisplay() {
        val totalXP = progressStore.getTotalXP()
        val threshold = 50

        xpProgressText.text = "You've earned $totalXP XP and unlocked your potential!"
        progressBar.progress = minOf(100, (totalXP * 100) / threshold)

        findViewById<TextView>(R.id.milestone_text).text = "🎯 You've reached the $threshold XP milestone!"
        findViewById<TextView>(R.id.xp_counter).text = "$totalXP / $threshold XP"
    }

    private fun simulateIndividualPurchase() {
        // Disable button and show loading
        individualPurchaseButton.isEnabled = false
        individualPurchaseButton.text = "Processing..."

        lifecycleScope.launch {
            // Simulate purchase process
            delay(2000)

            // In real app, this would be actual in-app billing
            // For now, just upgrade to basic paid
            // accessControlManager.currentUserTier = UserTier.BASIC_PAID

            // Show name collection after successful purchase
            val intent = Intent(this@PaywallActivity, NameCollectionActivity::class.java)
            intent.putExtra("from_purchase", true)
            startActivity(intent)

            // Generate friend codes
            accessControlManager.checkAndGenerateFriendCodes()

            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check if user has gained access through code entry
        if (accessControlManager.hasBasicAccess()) {
            finish()
        }
    }
}