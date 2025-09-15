package com.skillvergence.mindsherpa.ui.podcast

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.skillvergence.mindsherpa.R
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider

/**
 * Podcast Fragment - Matches iOS PodcastView
 * Displays podcast episodes from Railway backend
 */
class PodcastFragment : Fragment() {

    private lateinit var podcastViewModel: PodcastViewModel

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        podcastViewModel = ViewModelProvider(this)[PodcastViewModel::class.java]

        // Inflate the proper layout
        val rootView = inflater.inflate(R.layout.fragment_podcast, container, false)

        val contentTextView = rootView.findViewById<TextView>(R.id.podcast_content)

        podcastViewModel.text.observe(viewLifecycleOwner) {
            contentTextView.text = it
        }

        return rootView
    }
}