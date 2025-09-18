package com.skillvergence.mindsherpa.data.api

import com.google.gson.GsonBuilder
import com.skillvergence.mindsherpa.config.AppConfig
import com.skillvergence.mindsherpa.data.model.SkillLevel
import com.skillvergence.mindsherpa.data.model.SkillLevelDeserializer
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Network module for Railway backend integration
 * Matches iOS networking configuration
 */
object NetworkModule {

    private val gson = GsonBuilder()
        .registerTypeAdapter(SkillLevel::class.java, SkillLevelDeserializer())
        .create()

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (AppConfig.ENABLE_NETWORK_LOGGING) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.NONE
        }
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .addInterceptor { chain ->
            val originalRequest = chain.request()
            val requestWithHeaders = originalRequest.newBuilder()
                .addHeader("User-Agent", AppConfig.USER_AGENT)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            if (AppConfig.ENABLE_NETWORK_LOGGING) {
                println("🌐 ${originalRequest.method} ${originalRequest.url}")
            }

            chain.proceed(requestWithHeaders)
        }
        .connectTimeout(AppConfig.CONNECT_TIMEOUT, TimeUnit.SECONDS)
        .readTimeout(AppConfig.READ_TIMEOUT, TimeUnit.SECONDS)
        .writeTimeout(AppConfig.REQUEST_TIMEOUT, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(AppConfig.apiURL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create(gson))
        .build()

    val apiService: ApiService = retrofit.create(ApiService::class.java)

    /**
     * Create a new Retrofit instance with updated base URL
     * Used for dynamic configuration updates
     */
    fun createApiService(baseUrl: String = AppConfig.apiURL): ApiService {
        val newRetrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        return newRetrofit.create(ApiService::class.java)
    }

    /**
     * Create teacher API service
     */
    fun createTeacherApiService(baseUrl: String = AppConfig.apiURL): TeacherApiService {
        val newRetrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        return newRetrofit.create(TeacherApiService::class.java)
    }
}

/**
 * API Exception handling
 */
sealed class ApiException(message: String) : Exception(message) {
    object NetworkError : ApiException("Network connection failed")
    object ServerError : ApiException("Server error occurred")
    object TimeoutError : ApiException("Request timed out")
    data class HttpError(val code: Int, val errorMessage: String) : ApiException("HTTP $code: $errorMessage")
    data class UnknownError(val originalError: Throwable) : ApiException("Unknown error: ${originalError.message}")
}

/**
 * API Result wrapper
 */
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val exception: ApiException) : ApiResult<Nothing>()
}

/**
 * Safe API call wrapper
 */
suspend fun <T> safeApiCall(apiCall: suspend () -> retrofit2.Response<T>): ApiResult<T> {
    return try {
        println("🔧 [API] Making API call...")
        val response = apiCall()
        println("🔧 [API] Response received - Code: ${response.code()}, Success: ${response.isSuccessful}")

        if (response.isSuccessful) {
            response.body()?.let { body ->
                println("🔧 [API] Response body received successfully")
                // Log specific details for courses response
                if (body is com.skillvergence.mindsherpa.data.model.CoursesResponse) {
                    println("🔧 [API] CoursesResponse - Total courses: ${body.courses.size}")
                    body.courses.forEach { course ->
                        println("🔧 [API] Course: ${course.id} - ${course.title} - Videos: ${course.videos?.size ?: 0}")
                        course.videos?.forEach { video ->
                            println("🔧 [API]   Video: ${video.id} - ${video.title}")
                        }
                    }
                }
                ApiResult.Success(body)
            } ?: run {
                println("❌ [API] Response body is null!")
                ApiResult.Error(ApiException.ServerError)
            }
        } else {
            println("❌ [API] HTTP Error: ${response.code()} - ${response.message()}")
            println("❌ [API] Error body: ${response.errorBody()?.string()}")
            ApiResult.Error(
                ApiException.HttpError(
                    response.code(),
                    response.message()
                )
            )
        }
    } catch (e: java.net.UnknownHostException) {
        println("❌ [API] Network Error - UnknownHost: ${e.message}")
        ApiResult.Error(ApiException.NetworkError)
    } catch (e: java.net.SocketTimeoutException) {
        println("❌ [API] Timeout Error: ${e.message}")
        ApiResult.Error(ApiException.TimeoutError)
    } catch (e: Exception) {
        println("❌ [API] Unknown Error: ${e.message}")
        e.printStackTrace()
        ApiResult.Error(ApiException.UnknownError(e))
    }
}