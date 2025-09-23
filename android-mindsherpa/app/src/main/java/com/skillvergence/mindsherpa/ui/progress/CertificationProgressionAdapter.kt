package com.skillvergence.mindsherpa.ui.progress

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.CertificationLevel

/**
 * Certification Progression Adapter - Shows certification level progression
 */
class CertificationProgressionAdapter(
    private val currentLevel: CertificationLevel,
    private val completedCourses: Int
) : RecyclerView.Adapter<CertificationProgressionAdapter.CertificationProgressionViewHolder>() {

    private val items = createCertificationProgressionItems()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CertificationProgressionViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_certification_progression, parent, false)
        return CertificationProgressionViewHolder(view)
    }

    override fun onBindViewHolder(holder: CertificationProgressionViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    private fun createCertificationProgressionItems(): List<CertificationProgressionItem> {
        return CertificationLevel.values().map { level ->
            val isCurrentOrPast = completedCourses >= level.coursesRequired
            val isCurrent = currentLevel == level
            val requirements = when (level) {
                CertificationLevel.NONE -> "Start learning"
                CertificationLevel.FOUNDATION -> "1 course"
                CertificationLevel.ASSOCIATE -> "2 courses"
                CertificationLevel.PROFESSIONAL -> "4 courses"
                CertificationLevel.CERTIFIED -> "5 courses"
            }

            CertificationProgressionItem(
                level = level,
                requirements = requirements,
                isCurrentOrPast = isCurrentOrPast,
                isCurrent = isCurrent,
                completedCourses = completedCourses
            )
        }
    }

    inner class CertificationProgressionViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val certificationIcon: ImageView = itemView.findViewById(R.id.certification_icon)
        private val certificationName: TextView = itemView.findViewById(R.id.certification_name)
        private val certificationRequirements: TextView = itemView.findViewById(R.id.certification_requirements)
        private val progressIndicator: TextView = itemView.findViewById(R.id.progress_indicator)

        fun bind(item: CertificationProgressionItem) {
            certificationName.text = item.level.displayName
            certificationRequirements.text = item.requirements

            // Set icon and colors based on status
            val iconRes = when {
                item.isCurrent -> R.drawable.ic_star_24dp
                item.isCurrentOrPast -> R.drawable.ic_star_24dp
                else -> R.drawable.ic_star_24dp
            }
            certificationIcon.setImageResource(iconRes)

            // Set colors
            val context = itemView.context
            val iconColor = when {
                item.isCurrent -> ContextCompat.getColor(context, R.color.orange_500)
                item.isCurrentOrPast -> ContextCompat.getColor(context, R.color.green_500)
                else -> ContextCompat.getColor(context, R.color.gray_400)
            }
            certificationIcon.setColorFilter(iconColor)

            val textColor = when {
                item.isCurrent -> ContextCompat.getColor(context, R.color.primary_text)
                item.isCurrentOrPast -> ContextCompat.getColor(context, R.color.primary_text)
                else -> ContextCompat.getColor(context, R.color.secondary_text)
            }
            certificationName.setTextColor(textColor)

            val textStyle = if (item.isCurrent) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL
            certificationName.setTypeface(null, textStyle)

            // Show progress indicator for current level
            if (item.isCurrent && item.level != CertificationLevel.NONE) {
                progressIndicator.visibility = View.VISIBLE
                progressIndicator.text = "${item.completedCourses}/${item.level.coursesRequired}"
                progressIndicator.setTextColor(ContextCompat.getColor(context, R.color.orange_500))
            } else {
                progressIndicator.visibility = View.GONE
            }
        }
    }
}