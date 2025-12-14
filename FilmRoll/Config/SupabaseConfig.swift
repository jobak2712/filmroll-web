import Foundation

/// Supabase Configuration
/// Update these values with your Supabase project credentials
enum SupabaseConfig {
    // MARK: - Project Credentials
    // Get these from: Supabase Dashboard > Settings > API
    
    /// Your Supabase project URL
    static let projectURL = "https://zcsuxholzvaidksgxqzi.supabase.co"
    
    /// Your Supabase anon/public key
    /// This is safe to include in client apps
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpjc3V4aG9senZhaWRrc2d4cXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MjU5MjcsImV4cCI6MjA4MTIwMTkyN30.XuJqC8xso2nD3aaO0EMe7vIy67UVgQVD7_kkdE6wUDo"
    
    // MARK: - Feature Flags
    
    /// Set to false to use real Supabase backend
    /// Set to true for local development with mock data
    static let useMockData = false
    
    // MARK: - Storage
    
    /// Storage bucket name for photos
    static let photoBucket = "photos"
    
    /// Maximum photo file size (10MB)
    static let maxPhotoSize: Int64 = 10 * 1024 * 1024
    
    // MARK: - Timeouts
    
    /// Network request timeout in seconds
    static let requestTimeout: TimeInterval = 30
    
    /// Photo upload timeout in seconds
    static let uploadTimeout: TimeInterval = 60
    
    // MARK: - URLs
    
    /// REST API base URL
    static var restURL: String {
        "\(projectURL)/rest/v1"
    }
    
    /// Auth API base URL
    static var authURL: String {
        "\(projectURL)/auth/v1"
    }
    
    /// Edge Functions base URL
    static var functionsURL: String {
        "\(projectURL)/functions/v1"
    }
    
    /// Storage base URL
    static var storageURL: String {
        "\(projectURL)/storage/v1"
    }
    
    // MARK: - Validation
    
    /// Check if configuration is valid (not using placeholder values)
    static var isConfigured: Bool {
        !projectURL.contains("YOUR_PROJECT_REF") && !anonKey.contains("YOUR_ANON_KEY")
    }
}
