package com.skillvergence.mindsherpa.ui.profile

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
import com.skillvergence.mindsherpa.data.api.StudentProgressAPI
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import kotlinx.coroutines.launch

/**
 * Name Collection Activity for Android
 * Corresponds to NameCollectionView.swift in iOS
 */
class NameCollectionActivity : AppCompatActivity() {

    private lateinit var progressStore: ProgressStore
    private lateinit var studentProgressAPI: StudentProgressAPI
    private lateinit var firstNameEditText: EditText
    private lateinit var lastNameEditText: EditText
    private lateinit var emailEditText: EditText
    private lateinit var classCodeEditText: EditText
    private lateinit var continueButton: Button
    private lateinit var maybeLatButton: Button
    private lateinit var progressText: TextView
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_name_collection)

        progressStore = ProgressStore.getInstance(this)
        studentProgressAPI = StudentProgressAPI.getInstance(this)
        setupViews()
        setupListeners()
        updateProgressText()

        // Check if we came from JoinClassActivity with a class code
        val classCode = intent.getStringExtra("class_code")
        if (!classCode.isNullOrEmpty()) {
            classCodeEditText.setText(classCode)
        }
    }

    private fun setupViews() {
        firstNameEditText = findViewById(R.id.first_name_edit_text)
        lastNameEditText = findViewById(R.id.last_name_edit_text)
        emailEditText = findViewById(R.id.email_edit_text)
        classCodeEditText = findViewById(R.id.class_code_edit_text)
        continueButton = findViewById(R.id.continue_button)
        maybeLatButton = findViewById(R.id.maybe_later_button)
        progressText = findViewById(R.id.progress_text)
        progressBar = findViewById(R.id.progress_bar)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Tell us about yourself"
            setDisplayHomeAsUpEnabled(false)
        }

        // Initial state
        continueButton.isEnabled = false

        // Focus on first field
        firstNameEditText.requestFocus()
    }

    private fun setupListeners() {
        val textWatcher = object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                updateButtonState()
            }
        }

        firstNameEditText.addTextChangedListener(textWatcher)
        lastNameEditText.addTextChangedListener(textWatcher)
        emailEditText.addTextChangedListener(textWatcher)
        classCodeEditText.addTextChangedListener(textWatcher)

        continueButton.setOnClickListener {
            saveUserInfo()
        }

        maybeLatButton.setOnClickListener {
            finish()
        }
    }

    private fun updateButtonState() {
        val firstName = firstNameEditText.text.toString().trim()
        val lastName = lastNameEditText.text.toString().trim()
        val email = emailEditText.text.toString().trim()

        // Require at least first name
        continueButton.isEnabled = firstName.isNotEmpty()
    }

    private fun updateProgressText() {
        val totalXP = progressStore.getTotalXP()
        val currentStreak = progressStore.getCurrentStreak()

        progressText.text = when {
            totalXP >= 50 -> "You've completed your first video and earned $totalXP XP!"
            currentStreak >= 2 -> "You're on a $currentStreak-day learning streak!"
            else -> "You're making excellent progress!"
        }
    }

    private fun saveUserInfo() {
        val firstName = firstNameEditText.text.toString().trim()
        val lastName = lastNameEditText.text.toString().trim()
        val email = emailEditText.text.toString().trim()
        val classCode = classCodeEditText.text.toString().trim()

        if (firstName.isEmpty()) {
            showError("Please enter your first name")
            return
        }

        // Show loading state
        progressBar.visibility = View.VISIBLE
        continueButton.isEnabled = false
        disableAllInputs()

        // Save user info locally first
        progressStore.setUserFirstName(firstName)
        if (lastName.isNotEmpty()) {
            progressStore.setUserLastName(lastName)
        }
        if (email.isNotEmpty()) {
            progressStore.setUserEmail(email)
        }

        // If class code is provided, attempt to join class
        if (classCode.isNotEmpty()) {
            joinClassWithCode(classCode, firstName, lastName, email)
        } else {
            // No class code, just finish
            hideLoadingAndFinish()
        }
    }

    private fun joinClassWithCode(classCode: String, firstName: String, lastName: String, email: String) {
        lifecycleScope.launch {
            try {
                // Call StudentProgressAPI to join class
                val success = studentProgressAPI.joinClass(
                    classCode = classCode,
                    firstName = firstName,
                    lastName = lastName,
                    email = email.ifEmpty { null }
                )

                if (success) {
                    showSuccess("🎉 Successfully joined class!")

                    // Set basic access since they joined a class
                    progressStore.setHasClassAccess(true)

                    hideLoadingAndFinish()
                } else {
                    showError("❌ Failed to join class. Please check your class code.")
                    hideLoading()
                }
            } catch (e: Exception) {
                showError("❌ Network error. Please check your internet connection.")
                hideLoading()
            }
        }
    }

    private fun disableAllInputs() {
        firstNameEditText.isEnabled = false
        lastNameEditText.isEnabled = false
        emailEditText.isEnabled = false
        classCodeEditText.isEnabled = false
        maybeLatButton.isEnabled = false
    }

    private fun enableAllInputs() {
        firstNameEditText.isEnabled = true
        lastNameEditText.isEnabled = true
        emailEditText.isEnabled = true
        classCodeEditText.isEnabled = true
        maybeLatButton.isEnabled = true
    }

    private fun hideLoading() {
        progressBar.visibility = View.GONE
        continueButton.isEnabled = true
        enableAllInputs()
    }

    private fun hideLoadingAndFinish() {
        progressBar.visibility = View.GONE
        finish()
    }

    private fun showSuccess(message: String) {
        val rootView = findViewById<View>(android.R.id.content)
        Snackbar.make(rootView, message, Snackbar.LENGTH_LONG)
            .setBackgroundTint(getColor(android.R.color.holo_green_dark))
            .show()
    }

    private fun showError(message: String) {
        val rootView = findViewById<View>(android.R.id.content)
        Snackbar.make(rootView, message, Snackbar.LENGTH_LONG)
            .setBackgroundTint(getColor(android.R.color.holo_red_dark))
            .show()
    }
}