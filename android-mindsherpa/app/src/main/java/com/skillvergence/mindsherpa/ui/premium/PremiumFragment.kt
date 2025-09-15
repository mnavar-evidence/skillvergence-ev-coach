package com.skillvergence.mindsherpa.ui.premium

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.skillvergence.mindsherpa.R
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider

/**
 * Premium Fragment - Matches iOS AdvancedCourseListView
 * Displays premium/advanced courses requiring subscription
 */
class PremiumFragment : Fragment() {

    private lateinit var premiumViewModel: PremiumViewModel

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        premiumViewModel = ViewModelProvider(this)[PremiumViewModel::class.java]

        // Inflate the proper layout
        val rootView = inflater.inflate(R.layout.fragment_premium, container, false)

        val contentTextView = rootView.findViewById<TextView>(R.id.premium_content)

        premiumViewModel.text.observe(viewLifecycleOwner) {
            contentTextView.text = it
        }

        return rootView
    }
}