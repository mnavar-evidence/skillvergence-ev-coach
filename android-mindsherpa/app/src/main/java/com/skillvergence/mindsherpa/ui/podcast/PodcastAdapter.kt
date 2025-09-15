package com.skillvergence.mindsherpa.ui.podcast

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.google.android.material.card.MaterialCardView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.model.Podcast

/**
 * RecyclerView adapter for podcast episodes
 * Displays podcast list with Material Design 3 styling
 */
class PodcastAdapter(
    private val podcasts: List<Podcast>,
    private val onPodcastClick: (Podcast) -> Unit
) : RecyclerView.Adapter<PodcastAdapter.PodcastViewHolder>() {

    inner class PodcastViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val cardView: MaterialCardView = view.findViewById(R.id.podcast_card)
        val podcastThumbnail: ImageView = view.findViewById(R.id.podcast_thumbnail)
        val podcastTitle: TextView = view.findViewById(R.id.podcast_title)
        val podcastDescription: TextView = view.findViewById(R.id.podcast_description)
        val podcastDuration: TextView = view.findViewById(R.id.podcast_duration)
        val episodeNumber: TextView = view.findViewById(R.id.episode_number)
        val playIcon: ImageView = view.findViewById(R.id.play_icon)

        fun bind(podcast: Podcast) {
            podcastTitle.text = podcast.title
            podcastDescription.text = podcast.description
            podcastDuration.text = podcast.getFormattedDuration()

            // Show episode number if available
            podcast.episodeNumber?.let { number ->
                episodeNumber.text = "Episode $number"
                episodeNumber.visibility = View.VISIBLE
            } ?: run {
                episodeNumber.visibility = View.GONE
            }

            // Load thumbnail
            Glide.with(itemView.context)
                .load(podcast.resolveThumbnailUrl())
                .placeholder(R.drawable.ic_headphones_24dp)
                .error(R.drawable.ic_headphones_24dp)
                .into(podcastThumbnail)

            // Set click listener
            cardView.setOnClickListener {
                onPodcastClick(podcast)
            }

            // Add visual feedback for Mux streams
            if (podcast.isMuxStream()) {
                playIcon.setImageResource(R.drawable.ic_play_circle_24dp)
                playIcon.visibility = View.VISIBLE
            } else {
                playIcon.visibility = View.GONE
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PodcastViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_podcast, parent, false)
        return PodcastViewHolder(view)
    }

    override fun onBindViewHolder(holder: PodcastViewHolder, position: Int) {
        holder.bind(podcasts[position])
    }

    override fun getItemCount(): Int = podcasts.size
}