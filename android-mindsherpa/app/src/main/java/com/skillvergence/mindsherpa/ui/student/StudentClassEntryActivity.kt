package com.skillvergence.mindsherpa.ui.student

import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.StudentProgressAPI
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import com.skillvergence.mindsherpa.databinding.ActivityStudentClassEntryBinding
import kotlinx.coroutines.launch

/**
 * StudentClassEntryActivity - Allows students to join a class using class codes
 */
class StudentClassEntryActivity : AppCompatActivity() {

    private lateinit var binding: ActivityStudentClassEntryBinding
    private lateinit var studentAPI: StudentProgressAPI
    private lateinit var progressStore: ProgressStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityStudentClassEntryBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupDependencies()
        setupUI()
        observeData()
        registerDeviceIfNeeded()
    }

    private fun setupDependencies() {
        studentAPI = StudentProgressAPI.getInstance(this)
        progressStore = ProgressStore.getInstance(this)
    }

    private fun setupUI() {
        supportActionBar?.title = "Join Your Class"
        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        // Load existing student info if available
        loadExistingInfo()

        // Set up button click
        binding.btnJoinClass.setOnClickListener {
            joinClass()
        }

        binding.btnClearInfo.setOnClickListener {
            clearForm()
            studentAPI.clearStudentInfo()
        }
    }

    private fun observeData() {
        studentAPI.studentInfo.observe(this) { studentInfo ->
            if (studentInfo != null) {
                binding.tvStatusTitle.text = "✅ Linked to Class"

                // Show detailed class information if available
                val classDetails = studentInfo.classDetails
                val message = if (classDetails != null) {
                    """Student: ${studentAPI.getStudentDisplayName()}
Class: ${studentInfo.classCode}

Teacher: ${classDetails.teacherName}
School: ${classDetails.schoolName}
Program: ${classDetails.programName}
Email: ${classDetails.teacherEmail}"""
                } else {
                    "Student: ${studentAPI.getStudentDisplayName()}\nClass: ${studentInfo.classCode}"
                }

                binding.tvStatusMessage.text = message
                binding.btnJoinClass.text = "Update Information"
                binding.btnClearInfo.visibility = android.view.View.VISIBLE
            } else {
                binding.tvStatusTitle.text = "Join Your Class"
                binding.tvStatusMessage.text = "Enter your class code and student information to connect with your instructor"
                binding.btnJoinClass.text = "Join Class"
                binding.btnClearInfo.visibility = android.view.View.GONE
            }
        }

        studentAPI.isLoading.observe(this) { isLoading ->
            binding.btnJoinClass.isEnabled = !isLoading
            binding.progressBar.visibility = if (isLoading) android.view.View.VISIBLE else android.view.View.GONE
        }

        studentAPI.lastError.observe(this) { error ->
            if (!error.isNullOrEmpty()) {
                Toast.makeText(this, error, Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun loadExistingInfo() {
        val studentInfo = studentAPI.studentInfo.value
        if (studentInfo != null) {
            binding.etClassCode.setText(studentInfo.classCode ?: "")
            binding.etFirstName.setText(studentInfo.firstName ?: "")
            binding.etLastName.setText(studentInfo.lastName ?: "")
            binding.etEmail.setText(studentInfo.email ?: "")
        } else {
            // Load from UserDefaults or use existing user name
            val existingName = progressStore.getUserName()
            if (existingName.isNotEmpty()) {
                val nameParts = existingName.split(" ", limit = 2)
                if (nameParts.size >= 2) {
                    binding.etFirstName.setText(nameParts[0])
                    binding.etLastName.setText(nameParts[1])
                } else {
                    binding.etFirstName.setText(existingName)
                }
            }
        }
    }

    private fun clearForm() {
        binding.etClassCode.setText("")
        binding.etFirstName.setText("")
        binding.etLastName.setText("")
        binding.etEmail.setText("")
    }

    private fun registerDeviceIfNeeded() {
        lifecycleScope.launch {
            studentAPI.registerDevice()
        }
    }

    private fun joinClass() {
        val classCode = binding.etClassCode.text.toString().trim()
        val firstName = binding.etFirstName.text.toString().trim()
        val lastName = binding.etLastName.text.toString().trim()
        val email = binding.etEmail.text.toString().trim()

        // Validation
        if (classCode.isEmpty() || firstName.isEmpty() || lastName.isEmpty() || email.isEmpty()) {
            Toast.makeText(this, "Please fill in all required fields", Toast.LENGTH_SHORT).show()
            return
        }

        lifecycleScope.launch {
            val success = studentAPI.joinClass(
                classCode = classCode.uppercase(),
                firstName = firstName,
                lastName = lastName,
                email = email.ifEmpty { null }
            )

            if (success) {
                // Update the progress store user name
                progressStore.setUserName("$firstName $lastName")
                Toast.makeText(
                    this@StudentClassEntryActivity,
                    "Successfully joined class!",
                    Toast.LENGTH_SHORT
                ).show()
                finish()
            }
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        onBackPressed()
        return true
    }
}