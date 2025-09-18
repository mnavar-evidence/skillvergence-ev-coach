package com.skillvergence.mindsherpa.ui.teacher

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.skillvergence.mindsherpa.MainActivity
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.ClassCodeGenerationRequest
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import com.skillvergence.mindsherpa.data.model.AccessControlManager
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import kotlin.random.Random

/**
 * Teacher Settings Fragment
 * Shows teacher dashboard settings and preferences
 */
class TeacherSettingsFragment : Fragment() {

    private lateinit var accessControlManager: AccessControlManager
    private lateinit var currentClassCodeText: TextView
    private lateinit var copyCodeButton: ImageView
    private var currentClassCode: String? = null

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl("https://api.skillvergence.com/") // TODO: Move to config
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_teacher_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        accessControlManager = AccessControlManager.getInstance(requireContext())

        setupViews(view)
        setupClickListeners(view)
        loadCurrentClassCode()
    }

    private fun setupViews(view: View) {
        currentClassCodeText = view.findViewById(R.id.current_class_code)
        copyCodeButton = view.findViewById(R.id.copy_code_button)
    }

    private fun setupClickListeners(view: View) {
        // Exit teacher mode
        view.findViewById<View>(R.id.exit_teacher_mode_item).setOnClickListener {
            exitTeacherMode()
        }

        // Copy class code
        copyCodeButton.setOnClickListener {
            copyClassCodeToClipboard()
        }
    }

    private fun loadCurrentClassCode() {
        // Class code is static like email address - no API call needed
        // Dennis Johnson's class code from database
        currentClassCode = "T5T4Y9"
        updateClassCodeDisplay()
    }

    private fun updateClassCodeDisplay() {
        if (currentClassCode != null) {
            currentClassCodeText.text = currentClassCode
            currentClassCodeText.setTextColor(requireContext().getColor(android.R.color.black))
            copyCodeButton.visibility = View.VISIBLE
        } else {
            currentClassCodeText.text = "Loading class code..."
            currentClassCodeText.setTextColor(requireContext().getColor(android.R.color.darker_gray))
            copyCodeButton.visibility = View.GONE
        }
    }


    private fun saveClassCodeLocally(code: String) {
        val sharedPrefs = requireContext().getSharedPreferences("teacher_prefs", Context.MODE_PRIVATE)
        sharedPrefs.edit()
            .putString("class_code", code)
            .apply()
    }

    private fun copyClassCodeToClipboard() {
        currentClassCode?.let { code ->
            val clipboard = requireContext().getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("Class Code", code)
            clipboard.setPrimaryClip(clip)

            Toast.makeText(requireContext(),
                "Class code copied: $code",
                Toast.LENGTH_SHORT).show()
        }
    }

    private fun exitTeacherMode() {
        lifecycleScope.launch {
            accessControlManager.exitTeacherMode()

            // Return to student app
            val intent = Intent(requireContext(), MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            requireActivity().finish()
        }
    }

    companion object {
        fun newInstance() = TeacherSettingsFragment()
    }
}