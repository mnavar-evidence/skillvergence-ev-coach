package com.skillvergence.mindsherpa.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Video

/**
 * Video Adapter for Course Content List
 * Shows individual videos with completion status
 */
class VideoAdapter(
    private val onVideoClick: (Video) -> Unit
) : RecyclerView.Adapter<VideoAdapter.VideoViewHolder>() {

    private var videos = listOf<Video>()

    fun updateVideos(newVideos: List<Video>) {
        videos = newVideos
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VideoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_video, parent, false)
        return VideoViewHolder(view)
    }

    override fun onBindViewHolder(holder: VideoViewHolder, position: Int) {
        val video = videos[position]
        holder.bind(video, position)
    }

    override fun getItemCount() = videos.size

    inner class VideoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val thumbnailImage: ImageView = itemView.findViewById(R.id.video_thumbnail)
        private val titleText: TextView = itemView.findViewById(R.id.video_title)
        private val durationText: TextView = itemView.findViewById(R.id.video_duration)
        private val completionStatus: TextView = itemView.findViewById(R.id.completion_status)

        fun bind(video: Video, position: Int) {
            // Video title
            titleText.text = video.title

            // Duration formatting using the Video model's computed property
            durationText.text = video.formattedDuration

            // Load thumbnail image using Glide (matching iOS implementation)
            Glide.with(itemView.context)
                .load(video.thumbnailUrl)
                .apply(
                    RequestOptions()
                        .transform(RoundedCorners(16))
                        .placeholder(R.drawable.ic_play_circle_24dp)
                        .error(R.drawable.ic_play_circle_24dp)
                )
                .into(thumbnailImage)

            // TODO: Real completion status would come from user progress API
            // For now, show all videos as available to watch
            completionStatus.text = "▶️"

            itemView.setOnClickListener {
                onVideoClick(video)
            }
        }


    }
}