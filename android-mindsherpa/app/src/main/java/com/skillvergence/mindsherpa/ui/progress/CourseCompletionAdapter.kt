package com.skillvergence.mindsherpa.ui.progress

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.CourseCompletionDetail

/**
 * Course Completion Adapter - Shows individual course completion status
 */
class CourseCompletionAdapter(
    private val items: List<CourseCompletionDetail>
) : RecyclerView.Adapter<CourseCompletionAdapter.CourseCompletionViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CourseCompletionViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_course_completion, parent, false)
        return CourseCompletionViewHolder(view)
    }

    override fun onBindViewHolder(holder: CourseCompletionViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    inner class CourseCompletionViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val courseIcon: ImageView = itemView.findViewById(R.id.course_icon)
        private val courseName: TextView = itemView.findViewById(R.id.course_name)
        private val courseProgress: TextView = itemView.findViewById(R.id.course_progress)
        private val progressPercentage: TextView = itemView.findViewById(R.id.progress_percentage)

        fun bind(item: CourseCompletionDetail) {
            val courseNumber = item.courseId.toIntOrNull() ?: 1
            courseName.text = getCourseName(item.courseId)
            courseProgress.text = "${item.videosCompleted}/${item.totalVideos} videos completed"

            // Set icon and colors based on completion status
            val iconRes = R.drawable.ic_star_24dp
            courseIcon.setImageResource(iconRes)

            val context = itemView.context
            val iconColor = if (item.completed) {
                ContextCompat.getColor(context, R.color.green_500)
            } else {
                ContextCompat.getColor(context, R.color.gray_400)
            }
            courseIcon.setColorFilter(iconColor)

            val textColor = if (item.completed) {
                ContextCompat.getColor(context, android.R.color.primary_text_light)
            } else {
                ContextCompat.getColor(context, android.R.color.secondary_text_light)
            }
            courseName.setTextColor(textColor)

            val textStyle = if (item.completed) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL
            courseName.setTypeface(null, textStyle)

            // Show percentage for incomplete courses with progress
            if (!item.completed && item.videosCompleted > 0) {
                val percentage = (item.videosCompleted.toDouble() / item.totalVideos.toDouble() * 100).toInt()
                progressPercentage.visibility = View.VISIBLE
                progressPercentage.text = "$percentage%"
                progressPercentage.setTextColor(ContextCompat.getColor(context, R.color.blue_500))
            } else {
                progressPercentage.visibility = View.GONE
            }
        }

        private fun getCourseName(courseId: String): String {
            // Professional certification shows ADVANCED course names, not basic course names
            return when (courseId) {
                "1" -> "1.0 High Voltage Vehicle Safety (Advanced)"
                "2" -> "2.0 Electrical Level 1 - Medium Heavy Duty (Advanced)"
                "3" -> "3.0 Electrical Level 2 - Medium Heavy Duty (Advanced)"
                "4" -> "4.0 Electric Vehicle Supply Equipment (Advanced)"
                "5" -> "5.0 Introduction to Electric Vehicles (Advanced)"
                else -> "Advanced Course $courseId"
            }
        }
    }
}