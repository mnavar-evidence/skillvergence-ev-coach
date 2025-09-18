package com.skillvergence.mindsherpa.ui.codes

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.snackbar.Snackbar
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import com.skillvergence.mindsherpa.data.model.CodeRedemptionResult
import kotlinx.coroutines.launch

/**
 * Code Entry Activity for Android
 * Corresponds to CodeEntryView.swift in iOS
 */
class CodeEntryActivity : AppCompatActivity() {

    private lateinit var accessControlManager: AccessControlManager
    private lateinit var codeEditText: EditText
    private lateinit var validateButton: Button
    private lateinit var cancelButton: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var currentStatusText: TextView
    private lateinit var friendCodesText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_code_entry)

        accessControlManager = AccessControlManager.getInstance(this)
        setupViews()
        setupListeners()
        updateCurrentStatus()
    }

    private fun setupViews() {
        codeEditText = findViewById(R.id.access_code_edit_text)
        validateButton = findViewById(R.id.validate_code_button)
        cancelButton = findViewById(R.id.cancel_button)
        progressBar = findViewById(R.id.progress_bar)
        currentStatusText = findViewById(R.id.current_status_text)
        friendCodesText = findViewById(R.id.friend_codes_text)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Enter Access Code"
            setDisplayHomeAsUpEnabled(true)
        }

        // Initial state
        validateButton.isEnabled = false
        progressBar.visibility = View.GONE

        // Set code format help
        findViewById<TextView>(R.id.code_format_help).text = """
            Code Types:
            B - Basic Access (e.g., B12345)
            P - Premium Access (e.g., P67890)
            F - Friend Referral (e.g., F54321)
        """.trimIndent()
    }

    private fun setupListeners() {
        codeEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val code = s?.toString()?.trim() ?: ""
                validateButton.isEnabled = code.length >= 6
            }
        })

        validateButton.setOnClickListener {
            validateCode()
        }

        cancelButton.setOnClickListener {
            finish()
        }
    }

    private fun updateCurrentStatus() {
        accessControlManager.currentUserTier.observe(this) { tier ->
            if (tier.name != "FREE") {
                currentStatusText.visibility = View.VISIBLE
                currentStatusText.text = "✅ Current Access: ${tier.displayName}"
            } else {
                currentStatusText.visibility = View.GONE
            }
        }

        accessControlManager.earnedFriendCodes.observe(this) { codes ->
            if (codes.isNotEmpty()) {
                friendCodesText.visibility = View.VISIBLE
                friendCodesText.text = "You have ${codes.size} friend codes to share!"
            } else {
                friendCodesText.visibility = View.GONE
            }
        }
    }

    private fun validateCode() {
        val code = codeEditText.text.toString().trim()
        if (code.length < 6) {
            showError("Please enter a valid access code")
            return
        }

        // Show loading state
        progressBar.visibility = View.VISIBLE
        validateButton.isEnabled = false
        codeEditText.isEnabled = false

        lifecycleScope.launch {
            try {
                val result = accessControlManager.validateAndRedeemCode(code)

                showResult(result)

                if (result.isSuccess) {
                    codeEditText.text.clear()
                    // Generate friend codes based on level achievement
                    accessControlManager.checkAndGenerateFriendCodes()

                    // Close after successful redemption
                    finish()
                }
            } catch (e: Exception) {
                showError("Network error. Please try again.")
            } finally {
                // Hide loading state
                progressBar.visibility = View.GONE
                validateButton.isEnabled = true
                codeEditText.isEnabled = true
            }
        }
    }

    private fun showResult(result: CodeRedemptionResult) {
        val rootView = findViewById<View>(android.R.id.content)
        val snackbar = Snackbar.make(rootView, result.message, Snackbar.LENGTH_LONG)

        if (result.isSuccess) {
            snackbar.setBackgroundTint(getColor(android.R.color.holo_green_dark))
        } else {
            snackbar.setBackgroundTint(getColor(android.R.color.holo_red_dark))
        }

        snackbar.show()
    }

    private fun showError(message: String) {
        val rootView = findViewById<View>(android.R.id.content)
        Snackbar.make(rootView, message, Snackbar.LENGTH_LONG)
            .setBackgroundTint(getColor(android.R.color.holo_red_dark))
            .show()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}