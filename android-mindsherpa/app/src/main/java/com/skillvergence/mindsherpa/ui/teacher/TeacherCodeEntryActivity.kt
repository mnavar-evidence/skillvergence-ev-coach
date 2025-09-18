package com.skillvergence.mindsherpa.ui.teacher

import android.content.Intent
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
import kotlinx.coroutines.launch

/**
 * Teacher Code Entry Activity for Android
 * Corresponds to TeacherCodeEntryView.swift in iOS
 */
class TeacherCodeEntryActivity : AppCompatActivity() {

    private lateinit var accessControlManager: AccessControlManager
    private lateinit var codeEditText: EditText
    private lateinit var validateButton: Button
    private lateinit var cancelButton: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var helpText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_teacher_code_entry)

        accessControlManager = AccessControlManager.getInstance(this)
        setupViews()
        setupListeners()
    }

    private fun setupViews() {
        codeEditText = findViewById(R.id.teacher_code_edit_text)
        validateButton = findViewById(R.id.validate_code_button)
        cancelButton = findViewById(R.id.cancel_button)
        progressBar = findViewById(R.id.progress_bar)
        helpText = findViewById(R.id.help_text)

        // Setup toolbar
        supportActionBar?.apply {
            title = "Teacher Access"
            setDisplayHomeAsUpEnabled(true)
        }

        // Initial state
        validateButton.isEnabled = false
        progressBar.visibility = View.GONE

        // Set help text
        helpText.text = """
            Teacher Access Information:
            • Teacher codes start with 'T' followed by 5 digits
            • Contact your school administrator for access
            • Fallbrook High School: Contact IT department
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

    private fun validateCode() {
        val code = codeEditText.text.toString().trim()
        if (code.length < 6) {
            showError("Please enter a valid teacher code")
            return
        }

        // Show loading state
        progressBar.visibility = View.VISIBLE
        validateButton.isEnabled = false
        codeEditText.isEnabled = false

        lifecycleScope.launch {
            try {
                val isValid = accessControlManager.validateTeacherCode(code)

                if (isValid) {
                    // Success - navigate to teacher dashboard
                    val intent = Intent(this@TeacherCodeEntryActivity, TeacherDashboardActivity::class.java)
                    startActivity(intent)
                    finish()
                } else {
                    // Invalid code
                    showError("Invalid teacher code. Please check with your administrator.")
                    codeEditText.text.clear()
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

    private fun showError(message: String) {
        val rootView = findViewById<View>(android.R.id.content)
        Snackbar.make(rootView, message, Snackbar.LENGTH_LONG).show()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}