package com.skillvergence.mindsherpa.ui.profile

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.snackbar.Snackbar
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.StudentProgressAPI
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import kotlinx.coroutines.launch

/**
 * Join Class Activity
 * Simple screen for students to enter a class code and join a teacher's class
 */
class JoinClassActivity : AppCompatActivity() {

    private lateinit var progressStore: ProgressStore
    private lateinit var studentProgressAPI: StudentProgressAPI
    private lateinit var classCodeEditText: EditText
    private lateinit var joinButton: Button
    private lateinit var cancelButton: Button
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_join_class)

        progressStore = ProgressStore.getInstance(this)
        studentProgressAPI = StudentProgressAPI.getInstance(this)

        setupViews()
        setupListeners()
    }

    private fun setupViews() {
        classCodeEditText = findViewById(R.id.class_code_edit_text)
        joinButton = findViewById(R.id.join_button)
        cancelButton = findViewById(R.id.cancel_button)
        progressBar = findViewById(R.id.progress_bar)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Join Class"
            setDisplayHomeAsUpEnabled(true)
        }

        // Initial state
        joinButton.isEnabled = false
        progressBar.visibility = View.GONE

        // Focus on class code field
        classCodeEditText.requestFocus()
    }

    private fun setupListeners() {
        classCodeEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val code = s?.toString()?.trim() ?: ""
                joinButton.isEnabled = code.length >= 5
            }
        })

        joinButton.setOnClickListener {
            joinClass()
        }

        cancelButton.setOnClickListener {
            finish()
        }
    }

    private fun joinClass() {
        val classCode = classCodeEditText.text.toString().trim()
        if (classCode.length < 5) {
            showError("Please enter a valid class code")
            return
        }

        // Check if user has provided their information
        val firstName = progressStore.getUserFirstName()
        val lastName = progressStore.getUserLastName()
        val email = progressStore.getUserEmail()

        if (firstName.isEmpty()) {
            // If user hasn't provided their name, take them to name collection
            showNameCollectionDialog(classCode)
            return
        }

        // Show loading state
        progressBar.visibility = View.VISIBLE
        joinButton.isEnabled = false
        classCodeEditText.isEnabled = false
        cancelButton.isEnabled = false

        lifecycleScope.launch {
            try {
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

                    // Close after success
                    finish()
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

    private fun hideLoading() {
        progressBar.visibility = View.GONE
        joinButton.isEnabled = true
        classCodeEditText.isEnabled = true
        cancelButton.isEnabled = true
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

    private fun showNameCollectionDialog(classCode: String) {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("Setup Your Profile")
            .setMessage("To join a class, we need your name first. Would you like to set up your profile now?")
            .setPositiveButton("Set Up Profile") { _, _ ->
                // Launch NameCollectionActivity with the class code
                val intent = Intent(this, NameCollectionActivity::class.java)
                intent.putExtra("class_code", classCode)
                startActivity(intent)
                finish() // Close this activity since user will complete the flow in NameCollection
            }
            .setNegativeButton("Cancel") { _, _ ->
                // Do nothing, stay on this screen
            }
            .show()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}