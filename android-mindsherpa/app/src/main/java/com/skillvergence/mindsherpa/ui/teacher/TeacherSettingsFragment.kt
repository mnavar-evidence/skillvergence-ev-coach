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
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.widget.SwitchCompat
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
    private lateinit var autoApproveSwitch: SwitchCompat
    private lateinit var completionPercentageSlider: SeekBar
    private lateinit var completionPercentageText: TextView
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
        autoApproveSwitch = view.findViewById(R.id.auto_approve_switch)
        completionPercentageSlider = view.findViewById(R.id.completion_percentage_slider)
        completionPercentageText = view.findViewById(R.id.completion_percentage_text)

        // Setup certificate settings
        setupCertificateSettings()
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

    private fun setupCertificateSettings() {
        // Load saved settings
        val sharedPrefs = requireContext().getSharedPreferences("teacher_prefs", Context.MODE_PRIVATE)
        val autoApprove = sharedPrefs.getBoolean("auto_approve_certificates", false)
        val completionThreshold = sharedPrefs.getInt("completion_threshold", 80)

        // Set initial values
        autoApproveSwitch.isChecked = autoApprove
        updateSliderValue(completionThreshold)

        // Setup listeners
        autoApproveSwitch.setOnCheckedChangeListener { _, isChecked ->
            sharedPrefs.edit()
                .putBoolean("auto_approve_certificates", isChecked)
                .apply()
        }

        completionPercentageSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    val percentage = progress + 50 // Range 50-100
                    updateCompletionText(percentage)
                }
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {}

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                val percentage = (seekBar?.progress ?: 30) + 50
                sharedPrefs.edit()
                    .putInt("completion_threshold", percentage)
                    .apply()
            }
        })
    }

    private fun updateSliderValue(percentage: Int) {
        val progress = percentage - 50 // Convert 50-100 range to 0-50 for SeekBar
        completionPercentageSlider.progress = progress.coerceIn(0, 50)
        updateCompletionText(percentage)
    }

    private fun updateCompletionText(percentage: Int) {
        completionPercentageText.text = "$percentage%"

        // Update the footer text as well
        val footerText = view?.findViewById<TextView>(R.id.completion_footer_text)
        footerText?.text = "Students must complete at least $percentage% of a course to be eligible for a certificate."
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