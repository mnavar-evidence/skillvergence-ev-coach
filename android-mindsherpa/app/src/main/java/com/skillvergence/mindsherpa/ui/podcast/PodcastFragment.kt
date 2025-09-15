package com.skillvergence.mindsherpa.ui.podcast

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.skillvergence.mindsherpa.R

/**
 * Podcast Fragment - Matches iOS PodcastView
 * Displays podcast episodes grouped by course
 */
class PodcastFragment : Fragment() {

    private lateinit var podcastViewModel: PodcastViewModel
    private lateinit var loadingLayout: LinearLayout
    private lateinit var emptyLayout: LinearLayout
    private lateinit var contentLayout: LinearLayout

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        podcastViewModel = ViewModelProvider(this)[PodcastViewModel::class.java]

        val rootView = inflater.inflate(R.layout.fragment_podcast, container, false)

        // Initialize views
        loadingLayout = rootView.findViewById(R.id.loading_layout)
        emptyLayout = rootView.findViewById(R.id.empty_layout)
        contentLayout = rootView.findViewById(R.id.podcast_content_layout)

        setupObservers()

        return rootView
    }

    private fun setupObservers() {
        // For now, show empty state since we don't have podcast data yet
        // This matches iOS behavior when no podcasts are available
        showEmptyState()
    }

    private fun showLoading() {
        loadingLayout.visibility = View.VISIBLE
        emptyLayout.visibility = View.GONE
        contentLayout.visibility = View.GONE
    }

    private fun hideLoading() {
        loadingLayout.visibility = View.GONE
    }

    private fun setupPodcastContent() {
        // For now, show empty state since we don't have podcast data yet
        // This matches iOS behavior when no podcasts are available
        showEmptyState()
    }

    private fun showEmptyState() {
        emptyLayout.visibility = View.VISIBLE
        contentLayout.visibility = View.GONE
    }

    private fun showContent() {
        emptyLayout.visibility = View.GONE
        contentLayout.visibility = View.VISIBLE
    }
}