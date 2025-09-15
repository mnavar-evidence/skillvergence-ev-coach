package com.skillvergence.mindsherpa.ui.video

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Course
import com.skillvergence.mindsherpa.ui.adapter.CourseAdapter

/**
 * Video Fragment - Matches iOS VideoView
 * Displays video courses from Railway backend
 */
class VideoFragment : Fragment() {

    private lateinit var videoViewModel: VideoViewModel
    private lateinit var recyclerView: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var courseAdapter: CourseAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the proper layout
        val rootView = inflater.inflate(R.layout.fragment_video, container, false)

        // Initialize ViewModel
        videoViewModel = ViewModelProvider(this)[VideoViewModel::class.java]

        // Setup RecyclerView
        setupRecyclerView(rootView)

        // Observe data
        observeViewModel()

        // Load initial data
        videoViewModel.loadCourses()

        return rootView
    }

    private fun setupRecyclerView(rootView: View) {
        recyclerView = rootView.findViewById(R.id.courses_recycler_view)
        swipeRefresh = rootView.findViewById(R.id.swipe_refresh)

        courseAdapter = CourseAdapter { course ->
            // Handle course selection - will implement video player
            onCourseSelected(course)
        }

        recyclerView.layoutManager = LinearLayoutManager(requireContext())
        recyclerView.adapter = courseAdapter

        swipeRefresh.setOnRefreshListener {
            videoViewModel.refreshCourses()
        }
    }

    private fun observeViewModel() {
        videoViewModel.courses.observe(viewLifecycleOwner) { courses ->
            courseAdapter.updateCourses(courses)
            swipeRefresh.isRefreshing = false
        }

        videoViewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            swipeRefresh.isRefreshing = isLoading
        }

        videoViewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                // Show error message
                swipeRefresh.isRefreshing = false
                // TODO: Show proper error UI
            }
        }
    }

    private fun onCourseSelected(course: Course) {
        // Navigate to video player
        val intent = VideoPlayerActivity.createIntent(requireContext(), course)
        startActivity(intent)
        println("✅ Launching video player for: ${course.title}")
    }
}

// Adapter moved to separate file - com.skillvergence.mindsherpa.ui.adapter.CourseAdapter