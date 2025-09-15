package com.skillvergence.mindsherpa.ui.podcast

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class PodcastViewModel : ViewModel() {

    private val _text = MutableLiveData<String>().apply {
        value = "Podcast Section\n\nFeaturing:\n• EV Industry Expert Interviews\n• Technology Deep Dives\n• Market Analysis\n• Safety Best Practices"
    }
    val text: LiveData<String> = _text
}