package com.skillvergence.mindsherpa.ui.premium

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class PremiumViewModel : ViewModel() {

    private val _text = MutableLiveData<String>().apply {
        value = "Premium Advanced Courses\n\n🎓 Certificate Programs Available:\n\n• Advanced High Voltage Safety\n• Battery Management Systems Expert\n• DC Fast Charging Infrastructure\n• EV Diagnostics & Repair Professional\n• Vehicle-to-Grid Integration Systems\n\nUnlock professional certifications and advanced learning content."
    }
    val text: LiveData<String> = _text
}