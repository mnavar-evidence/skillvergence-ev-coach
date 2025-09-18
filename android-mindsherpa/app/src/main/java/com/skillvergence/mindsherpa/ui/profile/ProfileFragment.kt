package com.skillvergence.mindsherpa.ui.profile

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
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
                // Show detailed class information: Teacher Name, School Name, Program Name, Teacher Email
                val classInfoBuilder = StringBuilder()
                classInfoBuilder.append("Class: ${classDetails.teacherName}\n")
                classInfoBuilder.append("School: ${classDetails.schoolName}\n")
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
            showChangeClassConfirmation()
        }

        // Teacher Access (entrance to teacher mode)
        view.findViewById<View>(R.id.teacher_access_item).setOnClickListener {
            val intent = Intent(requireContext(), TeacherCodeEntryActivity::class.java)
            startActivity(intent)
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

    private fun showComingSoon(feature: String) {
        Toast.makeText(requireContext(), "$feature coming soon!", Toast.LENGTH_SHORT).show()
    }

    companion object {
        fun newInstance() = ProfileFragment()
    }
}