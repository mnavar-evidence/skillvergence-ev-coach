package com.skillvergence.mindsherpa.ui.teacher

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Teacher Progress Fragment
 * Shows class-wide progress analytics and charts
 */
class TeacherProgressFragment : Fragment() {

    private lateinit var totalStudentsText: TextView
    private lateinit var activeTodayText: TextView
    private lateinit var avgXpText: TextView
    private lateinit var courseProgressRecycler: RecyclerView
    private lateinit var podcastEngagementRecycler: RecyclerView
    private lateinit var topPerformersRecycler: RecyclerView
    private lateinit var recentActivityRecycler: RecyclerView

    private lateinit var courseProgressAdapter: CourseProgressAdapter
    private lateinit var podcastEngagementAdapter: PodcastEngagementAdapter
    private lateinit var topPerformersAdapter: TopPerformersAdapter
    private lateinit var recentActivityAdapter: RecentActivityAdapter

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl("http://192.168.86.46:3000/api/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_teacher_progress, container, false)

        setupViews(view)
        setupRecyclerViews()
        loadProgressData()

        return view
    }

    private fun setupViews(view: View) {
        totalStudentsText = view.findViewById(R.id.total_students)
        activeTodayText = view.findViewById(R.id.active_today)
        avgXpText = view.findViewById(R.id.avg_xp)
        courseProgressRecycler = view.findViewById(R.id.course_progress_recycler)
        podcastEngagementRecycler = view.findViewById(R.id.podcast_engagement_recycler)
        topPerformersRecycler = view.findViewById(R.id.top_performers_recycler)
        recentActivityRecycler = view.findViewById(R.id.recent_activity_recycler)
    }

    private fun setupRecyclerViews() {
        courseProgressAdapter = CourseProgressAdapter()
        courseProgressRecycler.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = courseProgressAdapter
        }

        podcastEngagementAdapter = PodcastEngagementAdapter()
        podcastEngagementRecycler.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = podcastEngagementAdapter
        }

        topPerformersAdapter = TopPerformersAdapter()
        topPerformersRecycler.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = topPerformersAdapter
        }

        recentActivityAdapter = RecentActivityAdapter()
        recentActivityRecycler.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = recentActivityAdapter
        }
    }

    private fun loadProgressData() {
        lifecycleScope.launch {
            try {
                // Load student roster for summary stats
                val schoolId = "fallbrook-hs"
                val studentsResponse = teacherApiService.getStudentRoster(schoolId)

                if (studentsResponse.isSuccessful && studentsResponse.body() != null) {
                    val roster = studentsResponse.body()!!

                    // Update engagement summary stats
                    totalStudentsText.text = roster.students.size.toString()
                    activeTodayText.text = roster.summary.activeToday.toString()
                    avgXpText.text = roster.summary.avgXP.toString()

                    // Setup basic course engagement data (focus on activity, not completion)
                    val basicCourseData = listOf(
                        CourseProgressItem("High Voltage Safety Foundation", 12, 15, 80),
                        CourseProgressItem("Electrical Fundamentals", 10, 15, 67),
                        CourseProgressItem("EV System Components", 8, 15, 53),
                        CourseProgressItem("EV Charging Systems", 6, 15, 40),
                        CourseProgressItem("Advanced EV Systems", 4, 15, 27)
                    )
                    courseProgressAdapter.submitList(basicCourseData)

                    // Setup podcast engagement data
                    val podcastEngagementData = listOf(
                        PodcastEngagementItem("EV Safety Fundamentals", 8, 15, 45, 53),
                        PodcastEngagementItem("Electrical Systems Deep Dive", 6, 15, 38, 40),
                        PodcastEngagementItem("Battery Technology Explained", 5, 15, 42, 33),
                        PodcastEngagementItem("Charging Infrastructure", 4, 15, 35, 27),
                        PodcastEngagementItem("Future of EVs", 3, 15, 28, 20)
                    )
                    podcastEngagementAdapter.submitList(podcastEngagementData)

                    // Setup top performers (sort by XP)
                    val topPerformers = roster.students
                        .sortedByDescending { it.totalXP }
                        .take(5)
                        .mapIndexed { index, student ->
                            TopPerformerItem(
                                rank = index + 1,
                                name = student.name,
                                level = student.currentLevel,
                                xp = student.totalXP,
                                certificates = student.completedCourses,
                                progress = (student.completedCourses * 100) / 5
                            )
                        }
                    topPerformersAdapter.submitList(topPerformers)

                    // Setup recent activity data (focus on basic course engagement)
                    val recentActivities = listOf(
                        RecentActivityItem("📚", "Video completed", "Murgesh Navar • High Voltage Safety Foundation", "30m ago"),
                        RecentActivityItem("⚡", "Earned 25 XP", "Abigail Clark • Electrical Fundamentals Quiz", "45m ago"),
                        RecentActivityItem("🎯", "Started course", "John Smith • EV System Components", "1h ago"),
                        RecentActivityItem("📖", "Module progress", "Sarah Johnson • 75% complete in EV Charging", "2h ago"),
                        RecentActivityItem("🔋", "Watch streak", "Mike Brown • 5 day learning streak", "3h ago"),
                        RecentActivityItem("⭐", "XP milestone", "Emma Davis • Reached 500 XP total", "4h ago"),
                        RecentActivityItem("📺", "Video watched", "Chris Wilson • Advanced EV Systems Intro", "5h ago")
                    )
                    recentActivityAdapter.submitList(recentActivities)
                }

            } catch (e: Exception) {
                println("Error loading progress data: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    companion object {
        fun newInstance() = TeacherProgressFragment()
    }
}

// Data classes
data class CourseProgressItem(
    val courseName: String,
    val completedStudents: Int,
    val totalStudents: Int,
    val progressPercentage: Int
)

data class TopPerformerItem(
    val rank: Int,
    val name: String,
    val level: Int,
    val xp: Int,
    val certificates: Int,
    val progress: Int
)

data class PodcastEngagementItem(
    val title: String,
    val listenersCount: Int,
    val totalStudents: Int,
    val avgListenMinutes: Int,
    val engagementPercentage: Int
)

data class RecentActivityItem(
    val icon: String,
    val description: String,
    val details: String,
    val timeAgo: String
)

// Adapters
class CourseProgressAdapter : RecyclerView.Adapter<CourseProgressAdapter.ViewHolder>() {

    private var items = listOf<CourseProgressItem>()

    fun submitList(newItems: List<CourseProgressItem>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_course_progress, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val courseName: TextView = itemView.findViewById(R.id.course_name)
        private val courseStats: TextView = itemView.findViewById(R.id.course_stats)
        private val progressPercentage: TextView = itemView.findViewById(R.id.progress_percentage)
        private val progressBar: android.widget.ProgressBar = itemView.findViewById(R.id.progress_bar)

        fun bind(item: CourseProgressItem) {
            courseName.text = item.courseName
            courseStats.text = "${item.completedStudents}/${item.totalStudents} students actively engaged"
            progressPercentage.text = "${item.progressPercentage}%"
            progressBar.progress = item.progressPercentage
        }
    }
}

class TopPerformersAdapter : RecyclerView.Adapter<TopPerformersAdapter.ViewHolder>() {

    private var items = listOf<TopPerformerItem>()

    fun submitList(newItems: List<TopPerformerItem>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_top_performer, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val rankNumber: TextView = itemView.findViewById(R.id.rank_number)
        private val studentName: TextView = itemView.findViewById(R.id.student_name)
        private val studentProgress: TextView = itemView.findViewById(R.id.student_progress)
        private val completionPercentage: TextView = itemView.findViewById(R.id.completion_percentage)

        fun bind(item: TopPerformerItem) {
            rankNumber.text = item.rank.toString()
            studentName.text = item.name
            studentProgress.text = "Level ${item.level} • ${item.xp} XP • ${item.certificates} Certificates"
            completionPercentage.text = "${item.progress}%"

            // Set rank background color
            val backgroundColor = when (item.rank) {
                1 -> Color.parseColor("#FFD700") // Gold
                2 -> Color.parseColor("#C0C0C0") // Silver
                3 -> Color.parseColor("#CD7F32") // Bronze
                else -> Color.parseColor("#FF9800") // Orange
            }
            rankNumber.setBackgroundColor(backgroundColor)
        }
    }
}

class RecentActivityAdapter : RecyclerView.Adapter<RecentActivityAdapter.ViewHolder>() {

    private var items = listOf<RecentActivityItem>()

    fun submitList(newItems: List<RecentActivityItem>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_recent_activity, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val activityIcon: TextView = itemView.findViewById(R.id.activity_icon)
        private val activityDescription: TextView = itemView.findViewById(R.id.activity_description)
        private val activityDetails: TextView = itemView.findViewById(R.id.activity_details)
        private val activityTime: TextView = itemView.findViewById(R.id.activity_time)

        fun bind(item: RecentActivityItem) {
            activityIcon.text = item.icon
            activityDescription.text = item.description
            activityDetails.text = item.details
            activityTime.text = item.timeAgo
        }
    }
}

class PodcastEngagementAdapter : RecyclerView.Adapter<PodcastEngagementAdapter.ViewHolder>() {

    private var items = listOf<PodcastEngagementItem>()

    fun submitList(newItems: List<PodcastEngagementItem>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_podcast_engagement, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val podcastIcon: TextView = itemView.findViewById(R.id.podcast_icon)
        private val podcastTitle: TextView = itemView.findViewById(R.id.podcast_title)
        private val podcastStats: TextView = itemView.findViewById(R.id.podcast_stats)
        private val engagementPercentage: TextView = itemView.findViewById(R.id.podcast_engagement_percentage)

        fun bind(item: PodcastEngagementItem) {
            podcastIcon.text = "🎧"
            podcastTitle.text = item.title
            podcastStats.text = "${item.listenersCount}/${item.totalStudents} students listened • ${item.avgListenMinutes} min avg"
            engagementPercentage.text = "${item.engagementPercentage}%"
        }
    }
}