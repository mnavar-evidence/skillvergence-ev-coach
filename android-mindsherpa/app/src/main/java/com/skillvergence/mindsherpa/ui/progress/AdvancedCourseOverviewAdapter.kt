package com.skillvergence.mindsherpa.ui.progress

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R

/**
 * Advanced Course Overview Adapter - Shows advanced course catalog
 */
class AdvancedCourseOverviewAdapter(
    private val items: List<AdvancedCourseOverviewItem>
) : RecyclerView.Adapter<AdvancedCourseOverviewAdapter.AdvancedCourseOverviewViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AdvancedCourseOverviewViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_advanced_course_overview, parent, false)
        return AdvancedCourseOverviewViewHolder(view)
    }

    override fun onBindViewHolder(holder: AdvancedCourseOverviewViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    inner class AdvancedCourseOverviewViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val courseIcon: ImageView = itemView.findViewById(R.id.course_icon)
        private val courseTitle: TextView = itemView.findViewById(R.id.course_title)
        private val courseDetails: TextView = itemView.findViewById(R.id.course_details)

        fun bind(item: AdvancedCourseOverviewItem) {
            courseTitle.text = item.title
            courseDetails.text = "${item.modules} modules • ${item.duration}"

            // Set course number in icon background
            courseIcon.setImageResource(R.drawable.ic_star_24dp)
            val context = itemView.context
            courseIcon.setColorFilter(ContextCompat.getColor(context, R.color.blue_500))
        }
    }
}