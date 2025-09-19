package com.skillvergence.mindsherpa.ui.profile

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.persistence.ProgressStore
import com.skillvergence.mindsherpa.data.api.StudentProgressAPI
import com.skillvergence.mindsherpa.ui.teacher.TeacherCodeEntryActivity

/**
 * Profile Fragment for student app
 * Shows student profile, progress, settings, and subtle teacher access
 */
class ProfileFragment : Fragment() {

    private lateinit var progressStore: ProgressStore
    private lateinit var studentProgressAPI: StudentProgressAPI
    private lateinit var classCodeSection: LinearLayout
    private lateinit var classCodeDisplay: TextView
    private lateinit var studentEmailDisplay: TextView
    private lateinit var copyClassCodeButton: ImageView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_profile, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        progressStore = ProgressStore.getInstance(requireContext())
        studentProgressAPI = StudentProgressAPI.getInstance(requireContext())

        // Initialize class code views
        classCodeSection = view.findViewById(R.id.class_code_section)
        classCodeDisplay = view.findViewById(R.id.class_code_display)
        studentEmailDisplay = view.findViewById(R.id.student_email_display)
        copyClassCodeButton = view.findViewById(R.id.copy_class_code)

        // Observe student info changes to update profile automatically
        studentProgressAPI.studentInfo.observe(viewLifecycleOwner) {
            updateProfileInfo(view)
        }

        updateProfileInfo(view)
        setupClickListeners(view)
    }

    private fun updateProfileInfo(view: View) {
        // Update student name
        val studentNameText = view.findViewById<android.widget.TextView>(R.id.student_name)
        val fullName = progressStore.getUserFullName()
        if (fullName.isNotEmpty()) {
            studentNameText.text = fullName
        } else {
            studentNameText.text = "Student Profile"
        }

        // Show detailed class information if available
        val classInfoText = view.findViewById<android.widget.TextView>(R.id.class_info_text)

        studentProgressAPI.studentInfo.value?.let { studentInfo ->
            studentInfo.classDetails?.let { classDetails ->
                // Show detailed class information: Teacher Name, Organization Name, Program Name, Teacher Email
                val classInfoBuilder = StringBuilder()
                classInfoBuilder.append("Class: ${classDetails.teacherName}\n")
                classInfoBuilder.append("Organization: ${classDetails.schoolName}\n")
                classInfoBuilder.append("Program: ${classDetails.programName}\n")
                classInfoBuilder.append("Teacher: ${classDetails.teacherEmail}")

                classInfoText.text = classInfoBuilder.toString()
            } ?: run {
                // Fallback to basic class code if no class details
                classInfoText.text = "Class: ${studentInfo.classCode ?: "Not enrolled"}"
            }
        } ?: run {
            // No student info - not linked to any class
            classInfoText.text = "Not enrolled in a class"
        }

        // Update class code section visibility and content
        updateClassCodeSection()
    }

    private fun setupClickListeners(view: View) {
        // My Certificates
        view.findViewById<View>(R.id.my_certificates_item).setOnClickListener {
            // TODO: Navigate to certificates view
            showComingSoon("My Certificates")
        }

        // Notifications
        view.findViewById<View>(R.id.notifications_item).setOnClickListener {
            // TODO: Navigate to notifications settings
            showComingSoon("Notifications Settings")
        }

        // Join Class
        view.findViewById<View>(R.id.join_class_item).setOnClickListener {
            val intent = Intent(requireContext(), JoinClassActivity::class.java)
            startActivity(intent)
        }

        // Change Class
        view.findViewById<View>(R.id.change_class_item).setOnClickListener {
            val studentInfo = studentProgressAPI.studentInfo.value
            if (studentInfo != null) {
                showChangeClassConfirmation()
            } else {
                Toast.makeText(requireContext(),
                    "You are not enrolled in a class yet. Use 'Join Class' to enroll.",
                    Toast.LENGTH_SHORT).show()
            }
        }

        // Teacher Access (entrance to teacher mode)
        view.findViewById<View>(R.id.teacher_access_item).setOnClickListener {
            val intent = Intent(requireContext(), TeacherCodeEntryActivity::class.java)
            startActivity(intent)
        }

        // Copy class code
        copyClassCodeButton.setOnClickListener {
            copyClassCodeToClipboard()
        }
    }

    private fun showChangeClassConfirmation() {
        val studentInfo = studentProgressAPI.studentInfo.value
        val teacherName = studentInfo?.classDetails?.teacherName ?: "your teacher"

        val builder = androidx.appcompat.app.AlertDialog.Builder(requireContext())
        builder.setTitle("Change Class")
            .setMessage("Are you sure you want to leave $teacherName's class? You can join a new class afterwards.")
            .setPositiveButton("Change Class") { _, _ ->
                studentProgressAPI.clearStudentInfo()
                view?.let { updateProfileInfo(it) }
                Toast.makeText(requireContext(),
                    "Left class successfully. You can now join a new class.",
                    Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun updateClassCodeSection() {
        val studentInfo = studentProgressAPI.studentInfo.value
        if (studentInfo != null) {
            // Student is enrolled - show class code section
            classCodeSection.visibility = View.VISIBLE
            classCodeDisplay.text = studentInfo.classCode ?: "N/A"
            studentEmailDisplay.text = studentInfo.email ?: "No email registered"
        } else {
            // Student not enrolled - hide class code section
            classCodeSection.visibility = View.GONE
        }
    }

    private fun copyClassCodeToClipboard() {
        val studentInfo = studentProgressAPI.studentInfo.value
        val classCode = studentInfo?.classCode

        if (classCode != null) {
            val clipboard = requireContext().getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("Class Code", classCode)
            clipboard.setPrimaryClip(clip)
            Toast.makeText(requireContext(), "Class code copied to clipboard", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(requireContext(), "No class code available", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showComingSoon(feature: String) {
        Toast.makeText(requireContext(), "$feature coming soon!", Toast.LENGTH_SHORT).show()
    }

    companion object {
        fun newInstance() = ProfileFragment()
    }
}