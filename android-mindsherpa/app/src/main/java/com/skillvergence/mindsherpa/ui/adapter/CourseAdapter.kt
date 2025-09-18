package com.skillvergence.mindsherpa.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.chip.Chip
import com.google.android.material.textfield.TextInputLayout
import com.google.android.flexbox.FlexboxLayout
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Course

/**
 * Course Adapter for RecyclerView
 * Displays course list with AI footer
 */
class CourseAdapter(
    private val onCourseClick: (Course) -> Unit,
    private val onAIQuestionSubmit: (String) -> Unit = {},
    private val onQuickQuestionClick: (String) -> Unit = {}
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    private var coachNovaClickListener: (() -> Unit)? = null

    companion object {
        private const val VIEW_TYPE_COURSE = 0
        private const val VIEW_TYPE_AI_FOOTER = 1
    }

    private var courses = listOf<Course>()
    private var aiFooterViewHolder: AIFooterViewHolder? = null
    private val quickQuestions = listOf(
        "Compare alternator vs DC-DC",
        "How to test charging systems",
        "Safety when working with EVs",
        "Explain regenerative braking",
        "What is thermal runaway?"
    )

    fun updateCourses(newCourses: List<Course>) {
        courses = newCourses
        notifyDataSetChanged()
    }

    fun setCoachNovaClickListener(listener: () -> Unit) {
        coachNovaClickListener = listener
        // Update existing AI footer if it exists
        aiFooterViewHolder?.setCoachNovaClickListener(listener)
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            VIEW_TYPE_COURSE -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_course, parent, false)
                CourseViewHolder(view)
            }
            VIEW_TYPE_AI_FOOTER -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_ai_footer, parent, false)
                val holder = AIFooterViewHolder(view)
                aiFooterViewHolder = holder
                // Set Coach Nova click listener if available
                coachNovaClickListener?.let { listener ->
                    holder.setCoachNovaClickListener(listener)
                }
                holder
            }
            else -> throw IllegalArgumentException("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (holder) {
            is CourseViewHolder -> {
                val course = courses[position]
                holder.bind(course)
            }
            is AIFooterViewHolder -> {
                holder.bind()
            }
        }
    }

    override fun getItemCount() = courses.size + 1 // +1 for AI footer

    override fun getItemViewType(position: Int): Int {
        return if (position < courses.size) VIEW_TYPE_COURSE else VIEW_TYPE_AI_FOOTER
    }

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
        private val xpRewardText: TextView = itemView.findViewById(R.id.course_xp_reward)

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

            // XP Reward calculation (50 XP per video)
            val totalXP = videoCount * 50
            xpRewardText.text = "${totalXP} XP"

            // Debug logging
            println("📱 Course: ${course.title}, Videos: $videoCount, Duration: ${totalMinutes}min, XP: ${totalXP}")

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

    inner class AIFooterViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val questionInput: EditText = itemView.findViewById(R.id.question_input)
        private val questionInputLayout: TextInputLayout = itemView.findViewById(R.id.question_input_layout)
        private val quickQuestionsLayout: FlexboxLayout = itemView.findViewById(R.id.quick_questions_layout)
        private val aiResponseScroll: ScrollView = itemView.findViewById(R.id.ai_response_scroll)
        private val aiResponseText: TextView = itemView.findViewById(R.id.ai_response_text)
        private val aiLoadingLayout: LinearLayout = itemView.findViewById(R.id.ai_loading_layout)
        private val coachIcon: ImageView = itemView.findViewById(R.id.coach_icon)

        fun bind() {
            println("🤖 [AIFooterViewHolder] Binding AI footer")
            // Setup send button click
            questionInputLayout.setEndIconOnClickListener {
                val question = questionInput.text.toString()
                println("🤖 [AIFooterViewHolder] Send button clicked with question: '$question'")
                if (question.isNotBlank()) {
                    onAIQuestionSubmit(question)
                    questionInput.text?.clear()
                } else {
                    println("🤖 [AIFooterViewHolder] Question is blank, not submitting")
                }
            }

            // Setup Coach Nova tap gesture for hidden teacher access
            setupCoachNovaGesture()

            // Setup quick questions
            setupQuickQuestions()
        }

        private fun setupCoachNovaGesture() {
            // Set Coach Nova click listener from parent adapter
            coachNovaClickListener?.let { listener ->
                coachIcon.setOnClickListener { listener() }
            }
        }

        fun setCoachNovaClickListener(listener: () -> Unit) {
            coachIcon.setOnClickListener { listener() }
        }

        private fun setupQuickQuestions() {
            println("🤖 [AIFooterViewHolder] Setting up ${quickQuestions.size} quick questions")
            quickQuestionsLayout.removeAllViews()

            quickQuestions.forEach { question ->
                val chip = Chip(itemView.context)
                chip.text = question
                chip.isClickable = true
                chip.setOnClickListener {
                    println("🤖 [AIFooterViewHolder] Quick question clicked: '$question'")
                    onQuickQuestionClick(question)
                }
                quickQuestionsLayout.addView(chip)
                println("🤖 [AIFooterViewHolder] Added chip: '$question'")
            }
        }

        fun updateAIResponse(response: String) {
            aiResponseText.text = response
            aiResponseScroll.visibility = View.VISIBLE
        }

        fun showLoading(isLoading: Boolean) {
            aiLoadingLayout.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        fun showError(error: String) {
            aiResponseText.text = "Error: $error"
            aiResponseScroll.visibility = View.VISIBLE
        }
    }

    // Methods to update AI footer from fragment
    fun updateAIResponse(response: String) {
        aiFooterViewHolder?.updateAIResponse(response)
    }

    fun showAILoading(isLoading: Boolean) {
        aiFooterViewHolder?.showLoading(isLoading)
    }

    fun showAIError(error: String) {
        aiFooterViewHolder?.showError(error)
    }
}