package com.skillvergence.mindsherpa.ui.progress

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.XPLevel

/**
 * Level Progression Adapter - Shows XP level progression similar to iOS
 */
class LevelProgressionAdapter(
    private val currentLevel: XPLevel,
    private val totalXP: Int
) : RecyclerView.Adapter<LevelProgressionAdapter.LevelProgressionViewHolder>() {

    private val items = createLevelProgressionItems()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): LevelProgressionViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_level_progression, parent, false)
        return LevelProgressionViewHolder(view)
    }

    override fun onBindViewHolder(holder: LevelProgressionViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    private fun createLevelProgressionItems(): List<LevelProgressionItem> {
        return XPLevel.values().map { level ->
            val isCurrentOrPast = totalXP >= level.minXP
            val isCurrent = currentLevel == level
            val xpRange = if (level.maxXP != null) {
                "${level.minXP}-${level.maxXP} XP"
            } else {
                "${level.minXP}+ XP"
            }

            LevelProgressionItem(
                level = level,
                xpRange = xpRange,
                isCurrentOrPast = isCurrentOrPast,
                isCurrent = isCurrent
            )
        }
    }

    inner class LevelProgressionViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val levelIcon: ImageView = itemView.findViewById(R.id.level_icon)
        private val levelName: TextView = itemView.findViewById(R.id.level_name)
        private val levelXpRange: TextView = itemView.findViewById(R.id.level_xp_range)

        fun bind(item: LevelProgressionItem) {
            levelName.text = item.level.displayName
            levelXpRange.text = item.xpRange

            // Set icon and colors based on status
            val iconRes = when {
                item.isCurrent -> R.drawable.ic_star_24dp
                item.isCurrentOrPast -> R.drawable.ic_star_24dp
                else -> R.drawable.ic_star_24dp
            }
            levelIcon.setImageResource(iconRes)

            // Set colors
            val context = itemView.context
            val iconColor = when {
                item.isCurrent -> ContextCompat.getColor(context, R.color.orange_500)
                item.isCurrentOrPast -> ContextCompat.getColor(context, R.color.green_500)
                else -> ContextCompat.getColor(context, R.color.gray_400)
            }
            levelIcon.setColorFilter(iconColor)

            val textColor = when {
                item.isCurrent -> ContextCompat.getColor(context, R.color.primary_text)
                item.isCurrentOrPast -> ContextCompat.getColor(context, R.color.primary_text)
                else -> ContextCompat.getColor(context, R.color.secondary_text)
            }
            levelName.setTextColor(textColor)

            val textStyle = if (item.isCurrent) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL
            levelName.setTypeface(null, textStyle)
        }
    }
}