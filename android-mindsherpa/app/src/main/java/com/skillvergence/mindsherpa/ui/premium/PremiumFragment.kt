package com.skillvergence.mindsherpa.ui.premium

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.SubscriptionManager
import com.skillvergence.mindsherpa.data.model.AdvancedCourse
import com.skillvergence.mindsherpa.data.model.AdvancedCourseData

/**
 * Premium Fragment - Matches iOS AdvancedCourseListView
 * Displays premium/advanced courses requiring subscription and prerequisites
 */
class PremiumFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var courseCountBadge: TextView
    private lateinit var adapter: AdvancedCourseAdapter

    private val advancedCourses = AdvancedCourseData.sampleAdvancedCourses

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val rootView = inflater.inflate(R.layout.fragment_premium, container, false)

        initializeViews(rootView)
        setupRecyclerView()

        return rootView
    }

    override fun onResume() {
        super.onResume()
        // Refresh adapter to update course unlock status
        if (::adapter.isInitialized) {
            adapter.notifyDataSetChanged()
        }
    }

    private fun initializeViews(rootView: View) {
        recyclerView = rootView.findViewById(R.id.advanced_courses_recycler)
        courseCountBadge = rootView.findViewById(R.id.course_count_badge)

        // Update course count
        courseCountBadge.text = "${advancedCourses.size} courses"
    }

    private fun setupRecyclerView() {
        adapter = AdvancedCourseAdapter(advancedCourses) { course ->
            handleCourseSelection(course)
        }

        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter
    }

    private fun handleCourseSelection(course: AdvancedCourse) {
        // Check if course is unlocked and purchased
        val isUnlocked = checkCourseUnlocked(course)
        val isPurchased = checkCoursePurchased(course)

        when {
            isPurchased && isUnlocked -> {
                // Both purchased and prerequisite complete - show module list
                openCourseModuleList(course)
            }
            isPurchased -> {
                // Purchased but prerequisite incomplete - show prerequisite message
                openCoursePrerequisiteView(course)
            }
            else -> {
                // Not purchased - show paywall
                openCoursePaywallView(course)
            }
        }
    }

    private fun checkCourseUnlocked(course: AdvancedCourse): Boolean {
        // For now, return true since we're not tracking prerequisite completion yet
        // This will allow purchased courses to show as "Ready"
        // TODO: Implement prerequisite tracking later
        return true
    }

    private fun checkCoursePurchased(course: AdvancedCourse): Boolean {
        // Check subscription manager for purchased status
        return SubscriptionManager.isCourseUnlocked(course.id)
    }

    private fun openCourseModuleList(course: AdvancedCourse) {
        val intent = CourseModuleListActivity.createIntent(
            context = requireContext(),
            courseId = course.id,
            courseTitle = course.title,
            courseDescription = course.description
        )
        startActivity(intent)
    }

    private fun openAdvancedCoursePlayer(course: AdvancedCourse) {
        val intent = Intent(context, AdvancedCoursePlayerActivity::class.java)
        intent.putExtra("course_id", course.id)
        intent.putExtra("course_title", course.title)
        intent.putExtra("course_description", course.description)
        intent.putExtra("mux_playback_id", course.muxPlaybackId)
        intent.putExtra("estimated_hours", course.estimatedHours)
        intent.putExtra("xp_reward", course.xpReward)
        startActivity(intent)
    }

    private fun openCoursePrerequisiteView(course: AdvancedCourse) {
        val intent = Intent(context, CoursePrerequisiteActivity::class.java)
        intent.putExtra("course_id", course.id)
        intent.putExtra("course_title", course.title)
        intent.putExtra("prerequisite_course_id", course.prerequisiteCourseId)
        startActivity(intent)
    }

    private fun openCoursePaywallView(course: AdvancedCourse) {
        val intent = Intent(context, CoursePaywallActivity::class.java)
        intent.putExtra("course_id", course.id)
        intent.putExtra("course_title", course.title)
        intent.putExtra("course_description", course.description)
        intent.putExtra("estimated_hours", course.estimatedHours)
        intent.putExtra("xp_reward", course.xpReward)
        intent.putExtra("certificate_type", course.certificateType.name)
        intent.putExtra("skill_level", course.skillLevel.name)
        startActivity(intent)
    }
}