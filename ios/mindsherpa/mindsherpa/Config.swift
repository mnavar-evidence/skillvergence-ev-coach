import Foundation

struct AppConfig {
    // MARK: - API Configuration
    
    // Primary: Custom domain with SSL certificate
    static let baseURL = "https://api.mindsherpa.ai"  // Custom domain URL
    
    // Fallback: Direct Railway URLs (update when needed)
    static let fallbackBaseURL = "https://backend-production-f873.up.railway.app"
    static let configurationURL = "https://skillvergence.mindsherpa.ai/config.json"  // Dynamic config
    
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
    
    // MARK: - API Endpoints (Updated to use dynamic configuration)
    
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
    
    // MARK: - Dynamic Configuration
    
    private static var _dynamicBaseURL: String?
    
    static var currentBaseURL: String {
        return _dynamicBaseURL ?? baseURL
    }
    
    static var apiURL: String {
        return "\(currentBaseURL)/api"
    }
    
    static func loadDynamicConfiguration() async {
        do {
            guard let url = URL(string: configurationURL) else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let config = try? JSONDecoder().decode(DynamicConfig.self, from: data) {
                _dynamicBaseURL = config.apiBaseURL
                print("✅ Loaded dynamic config: \(config.apiBaseURL)")
            }
        } catch {
            print("⚠️ Could not load dynamic config, using default: \(error)")
        }
    }
    
    static func testConnectivity() async -> Bool {
        // Test primary URL
        if await testURL(currentBaseURL) {
            return true
        }
        
        // Test fallback URL
        print("⚠️ Primary URL failed, trying fallback...")
        if await testURL(fallbackBaseURL) {
            _dynamicBaseURL = fallbackBaseURL
            print("✅ Using fallback URL: \(fallbackBaseURL)")
            return true
        }
        
        return false
    }
    
    private static func testURL(_ baseURL: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ Connection test failed for \(baseURL): \(error)")
        }
        
        return false
    }

    // MARK: - Helper Methods
    
    static func printConfiguration() {
        print("📱 EV Coach App Configuration")
        print("   Environment: \(isProduction ? "Production" : "Development")")
        print("   Current Base URL: \(currentBaseURL)")
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

// MARK: - Dynamic Configuration Model

struct DynamicConfig: Codable {
    let apiBaseURL: String
    let cdnBaseURL: String?
    let version: String?
    let features: [String: Bool]?
    
    enum CodingKeys: String, CodingKey {
        case apiBaseURL = "api_base_url"
        case cdnBaseURL = "cdn_base_url"
        case version
        case features
    }
}