package com.skillvergence.mindsherpa.data.api

import retrofit2.Response
import retrofit2.http.*

/**
 * Teacher API Service for Android
 * Corresponds to TeacherAPIService.swift in iOS
 */
interface TeacherApiService {

    @POST("teacher/validate-code")
    suspend fun validateTeacherCode(
        @Body request: TeacherCodeRequest
    ): Response<TeacherValidationResponse>

    @GET("teacher/school/{schoolId}/config")
    suspend fun getSchoolConfig(
        @Path("schoolId") schoolId: String
    ): Response<SchoolConfigResponse>

    @GET("teacher/school/{schoolId}/students")
    suspend fun getStudentRoster(
        @Path("schoolId") schoolId: String,
        @Query("level") level: String? = null,
        @Query("sortBy") sortBy: String = "name",
        @Query("order") order: String = "asc"
    ): Response<StudentRosterResponse>

    @GET("teacher/students/{studentId}/progress")
    suspend fun getStudentProgress(
        @Path("studentId") studentId: String
    ): Response<StudentProgressResponse>

    @GET("teacher/school/{schoolId}/certificates")
    suspend fun getCertificates(
        @Path("schoolId") schoolId: String,
        @Query("status") status: String = "all"
    ): Response<CertificatesResponse>

    @POST("teacher/certificates/{certId}/approve")
    suspend fun approveCertificate(
        @Path("certId") certId: String,
        @Body request: CertificateActionRequest
    ): Response<CertificateActionResponse>

    @GET("teacher/school/{schoolId}/code-usage")
    suspend fun getCodeUsage(
        @Path("schoolId") schoolId: String
    ): Response<CodeUsageResponse>

    @POST("teacher/school/{schoolId}/generate-codes")
    suspend fun generateCodes(
        @Path("schoolId") schoolId: String,
        @Body request: CodeGenerationRequest
    ): Response<CodeGenerationResponse>

    @POST("teacher/generate-class-code")
    suspend fun generateClassCode(
        @Body request: ClassCodeGenerationRequest
    ): Response<ClassCodeResponse>

    @GET("teacher/class-code")
    suspend fun getCurrentClassCode(
        @Query("teacherId") teacherId: String
    ): Response<ClassCodeResponse>

    @POST("student/join-class")
    suspend fun joinClass(
        @Body request: JoinClassRequest
    ): Response<JoinClassResponse>
}

// MARK: - Request Models

data class TeacherCodeRequest(
    val code: String,
    val schoolId: String
)

data class CertificateActionRequest(
    val action: String,
    val teacherId: String
)

data class CodeGenerationRequest(
    val type: String,
    val count: Int
)

data class ClassCodeGenerationRequest(
    val teacherId: String,
    val teacherCode: String,
    val regenerate: Boolean = false
)

data class JoinClassRequest(
    val classCode: String,
    val studentName: String,
    val studentEmail: String
)

// MARK: - Response Models

data class TeacherValidationResponse(
    val success: Boolean,
    val teacher: TeacherDetails?,
    val error: String?
)

data class TeacherDetails(
    val id: String,
    val name: String,
    val email: String,
    val school: String,
    val schoolId: String,
    val department: String,
    val program: String,
    val classCode: String
)

data class SchoolInfo(
    val id: String,
    val name: String,
    val district: String,
    val program: String,
    val instructor: InstructorInfo
)

data class InstructorInfo(
    val id: String,
    val name: String,
    val email: String,
    val department: String?
)

data class SchoolConfigResponse(
    val school: SchoolConfig
)

data class SchoolConfig(
    val id: String,
    val name: String,
    val district: String,
    val program: String,
    val instructor: InstructorInfo,
    val xpThreshold: Int,
    val bulkLicenses: Int,
    val districtLicenses: Int
)

data class StudentRosterResponse(
    val students: List<ApiStudent>,
    val summary: StudentSummary
)

data class ApiStudent(
    val id: String,
    val name: String,
    val email: String,
    val courseLevel: String,
    val totalXP: Int,
    val currentLevel: Int,
    val completedCourses: Int,
    val lastActive: String,
    val streak: Int
)

data class StudentSummary(
    val totalStudents: Int,
    val activeToday: Int,
    val avgXP: Int,
    val totalCompletedCourses: Int,
    val avgCompletionRate: Int
)

data class StudentProgressResponse(
    val student: ApiStudent,
    val devices: List<ApiDevice>,
    val courseProgress: List<CourseProgress>,
    val weeklyActivity: List<WeeklyActivity>,
    val achievements: List<Achievement>
)

data class CourseProgress(
    val courseId: String,
    val courseName: String,
    val progress: Int,
    val completedVideos: Int,
    val totalVideos: Int,
    val timeSpent: Int
)

data class WeeklyActivity(
    val week: String,
    val xpEarned: Int,
    val timeSpent: Int
)

data class Achievement(
    val title: String,
    val earnedDate: String
)

data class ApiDevice(
    val deviceId: String,
    val deviceName: String,
    val platform: String,
    val appVersion: String,
    val lastSeen: String,
    val isActive: Boolean
)

data class CertificatesResponse(
    val certificates: List<ApiCertificate>,
    val summary: CertificateSummary
)

data class ApiCertificate(
    val id: String,
    val studentId: String,
    val studentName: String,
    val courseTitle: String,
    val completedDate: String,
    val status: String,
    val approvedBy: String?,
    val approvedDate: String?
)

data class CertificateSummary(
    val total: Int,
    val pending: Int,
    val approved: Int
)

data class CertificateActionResponse(
    val success: Boolean,
    val certificate: ApiCertificate
)

data class CodeUsageResponse(
    val usage: CodeUsage,
    val generatedCodes: GeneratedCodes
)

data class CodeUsage(
    val basicCodes: Int,
    val premiumCodes: Int,
    val friendCodes: Int
)

data class GeneratedCodes(
    val basic: List<String>,
    val premium: List<String>
)

data class CodeGenerationResponse(
    val success: Boolean,
    val codes: List<String>,
    val type: String,
    val count: Int,
    val generatedAt: String
)

data class ClassCodeResponse(
    val success: Boolean,
    val classCode: String?,
    val teacherInfo: TeacherInfo?,
    val error: String?
)

data class TeacherInfo(
    val id: String,
    val name: String,
    val email: String,
    val schoolName: String,
    val programName: String
)

data class JoinClassResponse(
    val success: Boolean,
    val teacherInfo: TeacherInfo?,
    val accessLevel: String?,
    val error: String?
)