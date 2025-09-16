package com.skillvergence.mindsherpa.ui.premium

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.SubscriptionManager
import com.skillvergence.mindsherpa.data.model.AdvancedCourse

/**
 * RecyclerView Adapter for Advanced Courses
 * Matches iOS AdvancedCourseCard functionality
 */
class AdvancedCourseAdapter(
    private val courses: List<AdvancedCourse>,
    private val onCourseClick: (AdvancedCourse) -> Unit
) : RecyclerView.Adapter<AdvancedCourseAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val courseTitle: TextView = view.findViewById(R.id.course_title)
        val prerequisiteText: TextView = view.findViewById(R.id.prerequisite_text)
        val courseDescription: TextView = view.findViewById(R.id.course_description)
        val courseDuration: TextView = view.findViewById(R.id.course_duration)
        val skillLevel: TextView = view.findViewById(R.id.skill_level)
        val statusIcon: ImageView = view.findViewById(R.id.status_icon)
        val statusText: TextView = view.findViewById(R.id.status_text)
        val xpReward: TextView = view.findViewById(R.id.xp_reward)
        val certificateIcon: ImageView = view.findViewById(R.id.certificate_icon)
        val premiumCrown: ImageView = view.findViewById(R.id.premium_crown)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_advanced_course, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val course = courses[position]

        // Basic course info
        holder.courseTitle.text = course.title
        holder.prerequisiteText.text = "Prerequisite: Complete ${getPrerequisiteCourseName(course.prerequisiteCourseId)}"
        holder.courseDescription.text = course.description
        holder.courseDuration.text = course.formattedDuration
        holder.skillLevel.text = course.skillLevel.displayName
        holder.xpReward.text = "${course.xpReward} XP"

        // Course status - check subscription manager and prerequisites
        val isPurchased = SubscriptionManager.isCourseUnlocked(course.id)
        val isUnlocked = course.isUnlocked // For now, this always returns true

        when {
            isPurchased && isUnlocked -> {
                // Ready to play
                holder.statusIcon.setImageResource(R.drawable.ic_play_circle_24dp)
                holder.statusText.text = "Ready"
                holder.statusText.setTextColor(Color.parseColor("#4CAF50")) // Green
                holder.statusIcon.setColorFilter(Color.parseColor("#4CAF50"))
                holder.itemView.alpha = 1.0f
                holder.premiumCrown.visibility = View.GONE
            }
            isPurchased -> {
                // Purchased but prerequisite needed
                holder.statusIcon.setImageResource(R.drawable.ic_check_circle_24dp)
                holder.statusText.text = "Owned"
                holder.statusText.setTextColor(Color.parseColor("#2196F3")) // Blue
                holder.statusIcon.setColorFilter(Color.parseColor("#2196F3"))
                holder.itemView.alpha = 1.0f
                holder.premiumCrown.visibility = View.GONE
            }
            else -> {
                // Not purchased
                holder.statusIcon.setImageResource(R.drawable.ic_lock_24dp)
                holder.statusText.text = "Locked"
                holder.statusText.setTextColor(Color.parseColor("#757575")) // Gray
                holder.statusIcon.setColorFilter(Color.parseColor("#757575"))
                holder.itemView.alpha = 0.6f
                holder.premiumCrown.visibility = View.VISIBLE
            }
        }

        // Set certificate icon based on type
        holder.certificateIcon.setImageResource(getCertificateIcon(course.certificateType.name))

        // Click listener
        holder.itemView.setOnClickListener {
            onCourseClick(course)
        }
    }

    override fun getItemCount() = courses.size

    private fun getPrerequisiteCourseName(courseId: String): String {
        val courseNumber = courseId.replace("course_", "")
        return when (courseNumber) {
            "1" -> "Basic Course - High Voltage Safety Foundation"
            "2" -> "Basic Course - Electrical Fundamentals"
            "3" -> "Basic Course - EV System Components"
            "4" -> "Basic Course - EV Charging Systems"
            "5" -> "Basic Course - Advanced EV Systems"
            else -> "Basic Course $courseNumber"
        }
    }

    private fun getCertificateIcon(certificateType: String): Int {
        return when (certificateType) {
            "EV_FUNDAMENTALS_ADVANCED" -> R.drawable.ic_star_24dp
            "BATTERY_SYSTEMS_EXPERT" -> R.drawable.ic_star_24dp
            "CHARGING_INFRASTRUCTURE_SPECIALIST" -> R.drawable.ic_star_24dp
            "EV_MAINTENANCE_PROFESSIONAL" -> R.drawable.ic_star_24dp
            "SMART_GRID_INTEGRATION" -> R.drawable.ic_star_24dp
            else -> R.drawable.ic_star_24dp
        }
    }
}

// Extension function for Double formatting
private fun Double.format(digits: Int) = "%.${digits}f".format(this)