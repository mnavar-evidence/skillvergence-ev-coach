package com.skillvergence.mindsherpa.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Course

/**
 * Course Adapter for RecyclerView
 * Displays course list similar to iOS course cards
 */
class CourseAdapter(
    private val onCourseClick: (Course) -> Unit
) : RecyclerView.Adapter<CourseAdapter.CourseViewHolder>() {

    private var courses = listOf<Course>()

    fun updateCourses(newCourses: List<Course>) {
        courses = newCourses
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CourseViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_course, parent, false)
        return CourseViewHolder(view)
    }

    override fun onBindViewHolder(holder: CourseViewHolder, position: Int) {
        val course = courses[position]
        holder.bind(course)
    }

    override fun getItemCount() = courses.size

    inner class CourseViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val courseIcon: ImageView = itemView.findViewById(R.id.course_icon)
        private val titleText: TextView = itemView.findViewById(R.id.course_title)
        private val categoryText: TextView = itemView.findViewById(R.id.course_category)
        private val durationText: TextView = itemView.findViewById(R.id.course_duration)
        private val descriptionText: TextView = itemView.findViewById(R.id.course_description)
        private val progressText: TextView = itemView.findViewById(R.id.progress_text)
        private val progressBar: android.widget.ProgressBar = itemView.findViewById(R.id.progress_bar)
        private val progressPercentage: TextView = itemView.findViewById(R.id.progress_percentage)
        private val skillLevelText: TextView = itemView.findViewById(R.id.course_skill_level)
        private val videoCountText: TextView = itemView.findViewById(R.id.video_count)

        fun bind(course: Course) {
            // Course title and basic info
            titleText.text = course.title
            descriptionText.text = course.description

            // Duration formatting (convert seconds to minutes)
            val totalMinutes = course.duration / 60
            durationText.text = "${totalMinutes} min"

            // Course icon based on content type
            setCourseIcon(course.title)

            // Category (simplified from title)
            categoryText.text = getCourseCategory(course.title)

            // Video count
            val videoCount = course.videos?.size ?: 0
            videoCountText.text = "$videoCount videos"

            // Progress (mock data for now - in real app this would come from user progress)
            val mockProgress = getMockProgress(course.id, videoCount)
            progressText.text = "${mockProgress.completedVideos} of $videoCount videos"
            progressBar.progress = mockProgress.percentage
            progressPercentage.text = "${mockProgress.percentage}% watched"

            // Skill level
            skillLevelText.text = course.skillLevel.displayName

            // Debug logging
            println("📱 Course: ${course.title}, Videos: $videoCount, Duration: ${totalMinutes}min")

            itemView.setOnClickListener {
                onCourseClick(course)
            }
        }

        private fun setCourseIcon(title: String) {
            val iconRes = when {
                title.contains("High Voltage Safety", ignoreCase = true) -> R.drawable.ic_high_voltage_safety_24dp
                title.contains("Electrical Fundamentals", ignoreCase = true) -> R.drawable.ic_electrical_fundamentals_24dp
                title.contains("EV System Components", ignoreCase = true) -> R.drawable.ic_ev_system_components_24dp
                title.contains("EV Charging", ignoreCase = true) -> R.drawable.ic_ev_charging_systems_24dp
                title.contains("Advanced EV", ignoreCase = true) -> R.drawable.ic_advanced_ev_systems_24dp
                else -> R.drawable.ic_high_voltage_safety_24dp // Default fallback
            }
            courseIcon.setImageResource(iconRes)
        }

        private fun getCourseCategory(title: String): String {
            return when {
                title.contains("Safety", ignoreCase = true) -> "Electrical Safety"
                title.contains("Electrical", ignoreCase = true) -> "Electrical Fundamentals"
                title.contains("System", ignoreCase = true) -> "EV Technician"
                title.contains("Charging", ignoreCase = true) -> "EV Systems"
                title.contains("Advanced", ignoreCase = true) -> "Advanced Systems"
                else -> "General"
            }
        }

        private fun getMockProgress(courseId: String, videoCount: Int): CourseProgress {
            // TODO: Replace with real progress data from user progress API
            // For now, show 0% progress for all courses to use real video counts
            return CourseProgress(0, videoCount, 0)
        }
    }

    data class CourseProgress(
        val completedVideos: Int,
        val totalVideos: Int,
        val percentage: Int
    )
}