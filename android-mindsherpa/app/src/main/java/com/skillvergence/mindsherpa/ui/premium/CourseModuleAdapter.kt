package com.skillvergence.mindsherpa.ui.premium

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R

/**
 * Generic RecyclerView Adapter for Course Modules
 * Works with all course types (1.0, 2.0, 3.0, 4.0, 5.0)
 */
class CourseModuleAdapter(
    private val modules: List<CourseModule>,
    private val onModuleClick: (CourseModule) -> Unit
) : RecyclerView.Adapter<CourseModuleAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val moduleTitle: TextView = view.findViewById(R.id.module_title)
        val moduleDescription: TextView = view.findViewById(R.id.module_description)
        val moduleDuration: TextView = view.findViewById(R.id.module_duration)
        val moduleXp: TextView = view.findViewById(R.id.module_xp)
        val playButton: ImageView = view.findViewById(R.id.play_button)
        val moduleNumber: TextView = view.findViewById(R.id.module_number)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_course_module, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val module = modules[position]

        // Extract module number from ID (e.g., "1-1" -> "1.1", "5-3" -> "5.3")
        val moduleNumber = module.id.replace("-", ".")

        holder.moduleNumber.text = moduleNumber
        holder.moduleTitle.text = module.title
        holder.moduleDescription.text = module.description
        holder.moduleDuration.text = module.formattedDuration
        holder.moduleXp.text = "${module.xpReward} XP"

        // Set play button icon
        holder.playButton.setImageResource(R.drawable.ic_play_circle_24dp)

        // Click listener for entire item
        holder.itemView.setOnClickListener {
            onModuleClick(module)
        }

        // Click listener for play button
        holder.playButton.setOnClickListener {
            onModuleClick(module)
        }
    }

    override fun getItemCount() = modules.size
}