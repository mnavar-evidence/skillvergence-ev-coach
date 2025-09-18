package com.skillvergence.mindsherpa.ui.teacher

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Student

/**
 * Adapter for the student roster RecyclerView
 */
class StudentAdapter(
    private val onStudentClick: (Student) -> Unit
) : ListAdapter<Student, StudentAdapter.StudentViewHolder>(StudentDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): StudentViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_student, parent, false)
        return StudentViewHolder(view)
    }

    override fun onBindViewHolder(holder: StudentViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class StudentViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val avatarBackground: View = itemView.findViewById(R.id.avatar_background)
        private val studentInitial: TextView = itemView.findViewById(R.id.student_initial)
        private val studentName: TextView = itemView.findViewById(R.id.student_name)
        private val studentXP: TextView = itemView.findViewById(R.id.student_xp)
        private val studentLevel: TextView = itemView.findViewById(R.id.student_level)
        private val studentActivity: TextView = itemView.findViewById(R.id.student_activity)

        fun bind(student: Student) {
            studentInitial.text = student.initial
            studentName.text = student.fullName
            studentXP.text = student.formattedXP
            studentLevel.text = student.formattedLevel
            studentActivity.text = student.activityStatus

            // Set avatar color based on activity status
            val avatarColor = when {
                student.isActive -> Color.parseColor("#4CAF50") // Green
                student.needsAttention -> Color.parseColor("#FF9800") // Orange
                else -> Color.parseColor("#9E9E9E") // Gray
            }
            avatarBackground.setBackgroundColor(avatarColor)

            // Set activity text color
            if (student.lastActivity != null) {
                studentActivity.setTextColor(Color.parseColor("#666666"))
            } else {
                studentActivity.setTextColor(Color.parseColor("#F44336"))
            }

            itemView.setOnClickListener {
                onStudentClick(student)
            }
        }
    }

    class StudentDiffCallback : DiffUtil.ItemCallback<Student>() {
        override fun areItemsTheSame(oldItem: Student, newItem: Student): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Student, newItem: Student): Boolean {
            return oldItem == newItem
        }
    }
}