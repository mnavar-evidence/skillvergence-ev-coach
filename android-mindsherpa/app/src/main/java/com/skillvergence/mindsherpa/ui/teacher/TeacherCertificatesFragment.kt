package com.skillvergence.mindsherpa.ui.teacher

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Button
import android.widget.LinearLayout
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.skillvergence.mindsherpa.R
import com.skillvergence.mindsherpa.data.api.TeacherApiService
import com.skillvergence.mindsherpa.data.api.ApiCertificate
import com.skillvergence.mindsherpa.data.api.CertificateActionRequest
import kotlinx.coroutines.launch
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.text.SimpleDateFormat
import java.util.*

/**
 * Teacher Certificates Fragment
 * Shows certificate management and approvals
 */
class TeacherCertificatesFragment : Fragment() {

    private lateinit var pendingCount: TextView
    private lateinit var approvedCount: TextView
    private lateinit var tabAllCertificates: CardView
    private lateinit var tabPendingCertificates: CardView
    private lateinit var tabApprovedCertificates: CardView
    private lateinit var certificatesRecyclerView: RecyclerView
    private lateinit var emptyState: LinearLayout

    private var allCertificates = listOf<ApiCertificate>()
    private var currentFilter = FilterType.ALL
    private lateinit var certificateAdapter: CertificateAdapter

    private val teacherApiService: TeacherApiService by lazy {
        Retrofit.Builder()
            .baseUrl("http://192.168.86.46:3000/api/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TeacherApiService::class.java)
    }

    enum class FilterType {
        ALL, PENDING, APPROVED
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_teacher_certificates, container, false)

        setupViews(view)
        setupRecyclerView()
        setupFilterTabs()
        loadCertificates()

        return view
    }

    private fun setupViews(view: View) {
        pendingCount = view.findViewById(R.id.pending_count)
        approvedCount = view.findViewById(R.id.approved_count)
        tabAllCertificates = view.findViewById(R.id.tab_all_certificates)
        tabPendingCertificates = view.findViewById(R.id.tab_pending_certificates)
        tabApprovedCertificates = view.findViewById(R.id.tab_approved_certificates)
        certificatesRecyclerView = view.findViewById(R.id.certificates_recycler_view)
        emptyState = view.findViewById(R.id.empty_state)
    }

    private fun setupRecyclerView() {
        certificateAdapter = CertificateAdapter { certificate, action ->
            handleCertificateAction(certificate, action)
        }

        certificatesRecyclerView.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = certificateAdapter
        }
    }

    private fun setupFilterTabs() {
        tabAllCertificates.setOnClickListener {
            setActiveTab(FilterType.ALL)
        }

        tabPendingCertificates.setOnClickListener {
            setActiveTab(FilterType.PENDING)
        }

        tabApprovedCertificates.setOnClickListener {
            setActiveTab(FilterType.APPROVED)
        }
    }

    private fun setActiveTab(filterType: FilterType) {
        currentFilter = filterType

        // Reset all tabs
        resetTabStyle(tabAllCertificates)
        resetTabStyle(tabPendingCertificates)
        resetTabStyle(tabApprovedCertificates)

        // Set active tab
        when (filterType) {
            FilterType.ALL -> setActiveTabStyle(tabAllCertificates)
            FilterType.PENDING -> setActiveTabStyle(tabPendingCertificates)
            FilterType.APPROVED -> setActiveTabStyle(tabApprovedCertificates)
        }

        applyFilter()
    }

    private fun resetTabStyle(tab: CardView) {
        tab.setCardBackgroundColor(Color.parseColor("#E3E3E3"))
        val textView = tab.getChildAt(0) as TextView
        textView.setTextColor(Color.BLACK)
    }

    private fun setActiveTabStyle(tab: CardView) {
        tab.setCardBackgroundColor(Color.parseColor("#6200EE"))
        val textView = tab.getChildAt(0) as TextView
        textView.setTextColor(Color.WHITE)
    }

    private fun applyFilter() {
        val filteredCertificates = when (currentFilter) {
            FilterType.ALL -> allCertificates
            FilterType.PENDING -> allCertificates.filter { it.status == "pending" }
            FilterType.APPROVED -> allCertificates.filter { it.status == "approved" }
        }

        certificateAdapter.submitList(filteredCertificates)

        // Show/hide empty state
        if (filteredCertificates.isEmpty()) {
            certificatesRecyclerView.visibility = View.GONE
            emptyState.visibility = View.VISIBLE
        } else {
            certificatesRecyclerView.visibility = View.VISIBLE
            emptyState.visibility = View.GONE
        }
    }

    private fun loadCertificates() {
        lifecycleScope.launch {
            try {
                // TODO: Get actual school ID from AccessControlManager
                val schoolId = "fallbrook-hs"
                val response = teacherApiService.getCertificates(schoolId)

                if (response.isSuccessful && response.body() != null) {
                    val certificatesResponse = response.body()!!
                    allCertificates = certificatesResponse.certificates

                    // Update summary stats
                    pendingCount.text = certificatesResponse.summary.pending.toString()
                    approvedCount.text = certificatesResponse.summary.approved.toString()

                    // Apply current filter
                    applyFilter()
                } else {
                    // Show empty state
                    showEmptyState()
                }
            } catch (e: Exception) {
                println("Error loading certificates: ${e.message}")
                e.printStackTrace()
                showEmptyState()
            }
        }
    }

    private fun showEmptyState() {
        allCertificates = emptyList()
        pendingCount.text = "0"
        approvedCount.text = "0"
        certificatesRecyclerView.visibility = View.GONE
        emptyState.visibility = View.VISIBLE
    }

    private fun handleCertificateAction(certificate: ApiCertificate, action: String) {
        lifecycleScope.launch {
            try {
                val response = teacherApiService.approveCertificate(
                    certificate.id,
                    CertificateActionRequest(action, "teacher-djohnson")
                )

                if (response.isSuccessful) {
                    // Reload certificates to get updated data
                    loadCertificates()
                } else {
                    println("Certificate action failed: ${response.code()}")
                }
            } catch (e: Exception) {
                println("Error handling certificate action: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    companion object {
        fun newInstance() = TeacherCertificatesFragment()
    }
}

/**
 * Certificate Adapter for RecyclerView
 */
class CertificateAdapter(
    private val onActionClick: (ApiCertificate, String) -> Unit
) : RecyclerView.Adapter<CertificateAdapter.CertificateViewHolder>() {

    private var certificates = listOf<ApiCertificate>()

    fun submitList(newCertificates: List<ApiCertificate>) {
        certificates = newCertificates
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CertificateViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_certificate, parent, false)
        return CertificateViewHolder(view)
    }

    override fun onBindViewHolder(holder: CertificateViewHolder, position: Int) {
        holder.bind(certificates[position])
    }

    override fun getItemCount() = certificates.size

    inner class CertificateViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val certificateTitle: TextView = itemView.findViewById(R.id.certificate_title)
        private val certificateStatus: TextView = itemView.findViewById(R.id.certificate_status)
        private val studentName: TextView = itemView.findViewById(R.id.student_name)
        private val completionDate: TextView = itemView.findViewById(R.id.completion_date)
        private val actionButtons: LinearLayout = itemView.findViewById(R.id.action_buttons)
        private val btnReject: Button = itemView.findViewById(R.id.btn_reject)
        private val btnApprove: Button = itemView.findViewById(R.id.btn_approve)
        private val approvedInfo: LinearLayout = itemView.findViewById(R.id.approved_info)
        private val approvedBy: TextView = itemView.findViewById(R.id.approved_by)
        private val approvedDate: TextView = itemView.findViewById(R.id.approved_date)

        fun bind(certificate: ApiCertificate) {
            certificateTitle.text = certificate.courseTitle
            studentName.text = certificate.studentName

            // Format completion date
            try {
                val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault())
                val outputFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
                val date = inputFormat.parse(certificate.completedDate)
                completionDate.text = outputFormat.format(date!!)
            } catch (e: Exception) {
                completionDate.text = "Recent"
            }

            // Set status and show appropriate UI elements
            when (certificate.status) {
                "pending" -> {
                    certificateStatus.text = "Pending"
                    certificateStatus.setTextColor(Color.parseColor("#FF9800"))
                    actionButtons.visibility = View.VISIBLE
                    approvedInfo.visibility = View.GONE

                    btnApprove.setOnClickListener {
                        onActionClick(certificate, "approve")
                    }

                    btnReject.setOnClickListener {
                        onActionClick(certificate, "reject")
                    }
                }
                "approved" -> {
                    certificateStatus.text = "Approved"
                    certificateStatus.setTextColor(Color.parseColor("#4CAF50"))
                    actionButtons.visibility = View.GONE
                    approvedInfo.visibility = View.VISIBLE

                    approvedBy.text = certificate.approvedBy ?: "System"

                    // Format approved date
                    try {
                        certificate.approvedDate?.let { approvedDateStr ->
                            val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault())
                            val outputFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
                            val date = inputFormat.parse(approvedDateStr)
                            approvedDate.text = "on ${outputFormat.format(date!!)}"
                        } ?: run {
                            approvedDate.text = "recently"
                        }
                    } catch (e: Exception) {
                        approvedDate.text = "recently"
                    }
                }
                else -> {
                    certificateStatus.text = certificate.status.capitalize()
                    certificateStatus.setTextColor(Color.parseColor("#F44336"))
                    actionButtons.visibility = View.GONE
                    approvedInfo.visibility = View.GONE
                }
            }
        }
    }
}