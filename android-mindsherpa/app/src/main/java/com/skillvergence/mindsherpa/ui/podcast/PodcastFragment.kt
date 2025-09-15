package com.skillvergence.mindsherpa.ui.podcast

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.widget.NestedScrollView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.card.MaterialCardView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Podcast
import com.skillvergence.mindsherpa.ui.video.VideoDetailActivity

/**
 * Podcast Fragment - Matches iOS PodcastView
 * Displays podcast episodes grouped by course
 */
class PodcastFragment : Fragment() {

    private lateinit var podcastViewModel: PodcastViewModel
    private lateinit var loadingLayout: LinearLayout
    private lateinit var emptyLayout: LinearLayout
    private lateinit var contentScrollView: NestedScrollView
    private lateinit var podcastContentLayout: LinearLayout

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
        contentScrollView = rootView.findViewById(R.id.content_scroll_view)
        podcastContentLayout = rootView.findViewById(R.id.podcast_content_layout)

        setupObservers()

        return rootView
    }

    private fun setupObservers() {
        // Observe loading state
        podcastViewModel.loadingState.observe(viewLifecycleOwner) { isLoading ->
            if (isLoading) {
                showLoading()
            } else {
                hideLoading()
            }
        }

        // Observe podcasts grouped by course
        podcastViewModel.podcastsByCourse.observe(viewLifecycleOwner) { podcastsByCourse ->
            if (podcastsByCourse.isNotEmpty()) {
                setupPodcastContent(podcastsByCourse)
                showContent()
            } else {
                showEmptyState()
            }
        }

        // Observe error messages
        podcastViewModel.errorMessage.observe(viewLifecycleOwner) { errorMessage ->
            if (errorMessage != null) {
                // For now, show empty state on error
                // TODO: Show proper error UI
                showEmptyState()
            }
        }
    }

    private fun showLoading() {
        loadingLayout.visibility = View.VISIBLE
        emptyLayout.visibility = View.GONE
        contentScrollView.visibility = View.GONE
    }

    private fun hideLoading() {
        loadingLayout.visibility = View.GONE
    }

    private fun setupPodcastContent(podcastsByCourse: Map<String, List<Podcast>>) {
        podcastContentLayout.removeAllViews()

        // Add header with statistics
        addPodcastHeader()

        // Add each course section
        val sortedCourses = podcastsByCourse.keys.sortedBy { it.toIntOrNull() ?: Int.MAX_VALUE }

        for (courseId in sortedCourses) {
            val podcasts = podcastsByCourse[courseId] ?: continue
            if (podcasts.isNotEmpty()) {
                addCourseSection(courseId, podcasts)
            }
        }
    }

    private fun addPodcastHeader() {
        val headerView = layoutInflater.inflate(R.layout.podcast_header, podcastContentLayout, false)

        val totalPodcasts = headerView.findViewById<TextView>(R.id.total_podcasts)
        val totalDuration = headerView.findViewById<TextView>(R.id.total_duration)

        totalPodcasts.text = "${podcastViewModel.getTotalPodcastCount()} Episodes"
        totalDuration.text = "Total: ${podcastViewModel.getFormattedTotalDuration()}"

        podcastContentLayout.addView(headerView)
    }

    private fun addCourseSection(courseId: String, podcasts: List<Podcast>) {
        val courseSectionView = layoutInflater.inflate(R.layout.podcast_course_section, podcastContentLayout, false)

        val courseTitle = courseSectionView.findViewById<TextView>(R.id.course_title)
        val episodeCount = courseSectionView.findViewById<TextView>(R.id.episode_count)
        val podcastRecyclerView = courseSectionView.findViewById<RecyclerView>(R.id.podcast_recycler_view)

        courseTitle.text = podcastViewModel.getCourseTitle(courseId)
        episodeCount.text = "${podcasts.size} episodes"

        // Setup RecyclerView for this course's podcasts
        podcastRecyclerView.layoutManager = LinearLayoutManager(context)
        podcastRecyclerView.adapter = PodcastAdapter(podcasts) { podcast ->
            onPodcastSelected(podcast)
        }

        podcastContentLayout.addView(courseSectionView)
    }

    private fun onPodcastSelected(podcast: Podcast) {
        podcastViewModel.selectPodcast(podcast)

        // Launch audio player activity (using VideoDetailActivity for now since it supports Mux)
        val intent = VideoDetailActivity.createIntent(
            context = requireContext(),
            videoId = podcast.id,
            videoTitle = podcast.title,
            videoDescription = podcast.description,
            videoDuration = podcast.duration,
            courseId = podcast.courseId ?: "",
            muxPlaybackId = podcast.getMuxPlaybackId()
        )
        startActivity(intent)
    }

    private fun showEmptyState() {
        emptyLayout.visibility = View.VISIBLE
        contentScrollView.visibility = View.GONE
    }

    private fun showContent() {
        emptyLayout.visibility = View.GONE
        contentScrollView.visibility = View.VISIBLE
    }
}