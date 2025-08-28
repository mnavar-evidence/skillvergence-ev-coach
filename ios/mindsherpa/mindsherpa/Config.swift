import Foundation

struct AppConfig {
    // MARK: - API Configuration
    
    // Force production mode for testing
    static let baseURL = "https://backend-production-f873.up.railway.app"
    static let isProduction = true
    
    // Uncomment below for development
    /*
    #if DEBUG
    // Development - Local server  
    static let baseURL = "http://192.168.86.46:3000"  // Your Mac's IP address
    static let isProduction = false
    #else
    // Production - Railway deployment
    static let baseURL = "https://backend-production-f873.up.railway.app"
    static let isProduction = true
    #endif
    */
    
    // MARK: - API Endpoints
    
    static var apiURL: String {
        return "\(baseURL)/api"
    }
    
    static var coursesEndpoint: String {
        return "\(apiURL)/courses"
    }
    
    static var aiEndpoint: String {
        return "\(apiURL)/ai/ask"
    }
    
    static var analyticsEndpoint: String {
        return "\(apiURL)/analytics/events"
    }
    
    static var progressEndpoint: String {
        return "\(apiURL)/progress"
    }
    
    // MARK: - Network Configuration
    
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetryCount = 3
    
    // MARK: - Debug Settings
    
    static var enableNetworkLogging: Bool {
        return !isProduction
    }
    
    static var enableVerboseAnalytics: Bool {
        return !isProduction
    }
    
    // MARK: - Helper Methods
    
    static func printConfiguration() {
        print("📱 EV Coach App Configuration")
        print("   Environment: \(isProduction ? "Production" : "Development")")
        print("   Base URL: \(baseURL)")
        print("   API URL: \(apiURL)")
        print("   Courses URL: \(coursesEndpoint)")
        print("   Network Logging: \(enableNetworkLogging)")
        print("   Device ID: \(DeviceManager.shared.deviceId)")
        
        #if DEBUG
        print("   ⚠️  HTTP connections enabled for local development")
        print("   📶 Ensure your device is on the same WiFi network")
        #else
        print("   🌐 Using Railway production backend")
        print("   📡 Testing network connectivity...")
        #endif
    }
}

// MARK: - Network Helper

class NetworkHelper {
    static let shared = NetworkHelper()
    
    private init() {}
    
    private func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.waitsForConnectivity = true
        
        return URLSession(configuration: config)
    }
    
    func createURLRequest(for endpoint: String, method: String = "GET") -> URLRequest? {
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid URL: \(endpoint)")
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: AppConfig.requestTimeout)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("EV-Coach-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        if AppConfig.enableNetworkLogging {
            print("🌐 \(method) \(endpoint)")
        }
        
        return request
    }
    
    func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        // Create a custom session that can handle HTTP in development
        let session = createURLSession()
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    if AppConfig.enableNetworkLogging {
                        print("❌ Network Error: \(error.localizedDescription)")
                    }
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                if AppConfig.enableNetworkLogging {
                    print("✅ Response: \(data.count) bytes")
                }
                
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    if AppConfig.enableNetworkLogging {
                        print("❌ Decode Error: \(error)")
                        print("Raw Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    }
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum NetworkError: Error, LocalizedError {
    case noData
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}