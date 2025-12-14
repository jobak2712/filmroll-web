import Foundation

class SupabaseService {
    static let shared = SupabaseService()
    
    // MARK: - Configuration
    // Uses SupabaseConfig for credentials
    private var baseUrl: String { SupabaseConfig.projectURL }
    private var anonKey: String { SupabaseConfig.anonKey }
    
    private var authToken: String?
    
    private init() {
        // Load saved auth token
        authToken = UserDefaults.standard.string(forKey: "supabase_auth_token")
        
        // Warn if not configured
        if !SupabaseConfig.isConfigured {
            print("⚠️ SupabaseService: Using placeholder credentials. Update SupabaseConfig.swift with your project credentials.")
        }
    }
    
    // Request timeout configuration
    private var requestTimeout: TimeInterval { SupabaseConfig.requestTimeout }
    
    // MARK: - HTTP Helpers
    private func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(endpoint)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout // H01: Add timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        if httpResponse.statusCode >= 400 {
            if httpResponse.statusCode == 401 {
                throw SupabaseError.unauthorized
            }
            throw SupabaseError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func callFunction(
        name: String,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: "\(baseUrl)/functions/v1/\(name)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        // Always send Authorization header - use auth token if available, otherwise use anon key
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            // Edge functions require Authorization header even for anonymous access
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        // Debug logging for function calls
        print("📡 Function \(name) - Status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Function \(name) Error: \(errorString)")
            }
            throw SupabaseError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
    
    // MARK: - Auth
    func signUp(email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseUrl)/auth/v1/signup") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        // Debug logging
        print("📧 SignUp Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📧 SignUp Response: \(responseString)")
        }
        
        // Supabase returns 200 for successful signup
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = errorJson["error_description"] as? String ?? errorJson["msg"] as? String {
                print("❌ SignUp Error: \(errorMsg)")
            }
            throw SupabaseError.authError
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        authToken = authResponse.accessToken
        UserDefaults.standard.set(authToken, forKey: "supabase_auth_token")
        
        return authResponse.user.toUser()
    }
    
    func signIn(email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseUrl)/auth/v1/token?grant_type=password") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.authError
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        authToken = authResponse.accessToken
        UserDefaults.standard.set(authToken, forKey: "supabase_auth_token")
        
        return authResponse.user.toUser()
    }
    
    func signOut() async throws {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "supabase_auth_token")
    }
    
    func sendPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(baseUrl)/auth/v1/recover") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.authError
        }
    }
    
    func signInWithGoogle() async throws -> User {
        // In production, implement Google Sign-In SDK integration
        // This would use GoogleSignIn framework and exchange the ID token with Supabase
        // For now, throw not implemented
        throw SupabaseError.notImplemented
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        guard let url = URL(string: "\(baseUrl)/auth/v1/token?grant_type=id_token") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.authError
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        authToken = authResponse.accessToken
        UserDefaults.standard.set(authToken, forKey: "supabase_auth_token")
        
        return authResponse.user.toUser()
    }
    
    func getCurrentUser() async throws -> User? {
        guard let token = authToken else { return nil }
        
        guard let url = URL(string: "\(baseUrl)/auth/v1/user") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        // Supabase /auth/v1/user returns SupabaseAuthUser format
        let authUser = try JSONDecoder().decode(SupabaseAuthUser.self, from: data)
        return authUser.toUser()
    }
    
    // Shared decoder with date strategy for Supabase responses
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }
    
    // MARK: - Events
    func createEvent(_ request: CreateEventRequest) async throws -> Event {
        let body: [String: Any] = [
            "title": request.title,
            "description": request.description as Any,
            "event_date": ISO8601DateFormatter().string(from: request.eventDate),
            "shot_limit_per_guest": request.shotLimitPerGuest,
            "participant_cap": request.participantCap,
            "reveal_mode": request.revealMode.rawValue,
            "reveal_time": request.revealTime.map { ISO8601DateFormatter().string(from: $0) } as Any
        ]
        
        let data = try await callFunction(name: "createEvent", body: body)
        
        // Debug: print response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 createEvent response: \(responseString)")
        }
        
        let response = try jsonDecoder.decode(CreateEventResponse.self, from: data)
        return response.event
    }
    
    func getEvents(forHost hostId: String) async throws -> [EventWithStats] {
        let data = try await makeRequest(
            endpoint: "events?host_id=eq.\(hostId)&select=*,participants(count),photos(count)",
            method: "GET"
        )
        
        // Debug: print response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 getEvents response: \(responseString)")
        }
        
        let events = try jsonDecoder.decode([EventWithParticipantsAndPhotos].self, from: data)
        
        return events.map { event in
            EventWithStats(
                event: event.toEvent(),
                participantCount: event.participants.first?.count ?? 0,
                photoCount: event.photos.first?.count ?? 0,
                totalShots: (event.participants.first?.count ?? 0) * event.shotLimitPerGuest
            )
        }
    }
    
    func getEvent(id: String) async throws -> Event {
        let data = try await makeRequest(
            endpoint: "events?id=eq.\(id)",
            method: "GET",
            requiresAuth: false
        )
        
        let events = try jsonDecoder.decode([Event].self, from: data)
        guard let event = events.first else {
            throw SupabaseError.notFound
        }
        return event
    }
    
    func getEvent(joinCode: String) async throws -> Event {
        let data = try await makeRequest(
            endpoint: "events?join_code=eq.\(joinCode.lowercased())",
            method: "GET",
            requiresAuth: false
        )
        
        let events = try jsonDecoder.decode([Event].self, from: data)
        guard let event = events.first else {
            throw SupabaseError.notFound
        }
        return event
    }
    
    func updateEvent(_ event: Event) async throws -> Event {
        let body: [String: Any] = [
            "title": event.title,
            "description": event.description as Any,
            "shot_limit_per_guest": event.shotLimitPerGuest,
            "participant_cap": event.participantCap,
            "is_locked": event.isLocked,
            "allow_new_photos": event.allowNewPhotos,
            "reveal_time": event.revealTime.map { ISO8601DateFormatter().string(from: $0) } as Any
        ]
        
        print("📝 Updating event \(event.id) with body: \(body)")
        
        let data = try await makeRequest(
            endpoint: "events?id=eq.\(event.id)",
            method: "PATCH",
            body: body
        )
        
        // Debug response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📝 updateEvent response: \(responseString)")
        }
        
        // Handle empty response (PATCH might return empty array if no rows matched)
        if data.isEmpty || String(data: data, encoding: .utf8) == "[]" {
            // Return the event as-is since update was sent
            return event
        }
        
        let events = try jsonDecoder.decode([Event].self, from: data)
        guard let updated = events.first else {
            // If no event returned, return the original with updates applied
            return event
        }
        return updated
    }
    
    func deleteEvent(id: String) async throws {
        _ = try await makeRequest(
            endpoint: "events?id=eq.\(id)",
            method: "DELETE"
        )
    }
    
    func revealEvent(id: String) async throws {
        let body: [String: Any] = ["event_id": id]
        _ = try await callFunction(name: "revealEvent", body: body)
    }
    
    // MARK: - Participants
    func joinEvent(eventId: String, guestName: String?) async throws -> Participant {
        let body: [String: Any] = [
            "join_code": eventId,
            "guest_name": guestName as Any
        ]
        
        let data = try await callFunction(name: "joinEvent", body: body, requiresAuth: false)
        let response = try jsonDecoder.decode(JoinEventResponse.self, from: data)
        return response.participant
    }
    
    func getParticipants(eventId: String) async throws -> [Participant] {
        let data = try await makeRequest(
            endpoint: "participants?event_id=eq.\(eventId)",
            method: "GET",
            requiresAuth: false
        )
        
        return try jsonDecoder.decode([Participant].self, from: data)
    }
    
    func updateParticipantShotCount(participantId: String, count: Int) async throws {
        let body: [String: Any] = ["shots_taken": count]
        
        _ = try await makeRequest(
            endpoint: "participants?id=eq.\(participantId)",
            method: "PATCH",
            body: body,
            requiresAuth: false
        )
    }
    
    // MARK: - Photos
    func getSignedUploadUrl(eventId: String, participantId: String, fileName: String) async throws -> (signedUrl: String, storagePath: String) {
        let body: [String: Any] = [
            "event_id": eventId,
            "participant_id": participantId,
            "file_name": fileName,
            "content_type": "image/jpeg"
        ]
        
        let data = try await callFunction(name: "signPhotoUpload", body: body, requiresAuth: false)
        let response = try JSONDecoder().decode(SignedUploadResponse.self, from: data)
        return (response.signedUrl, response.storagePath)
    }
    
    func registerPhoto(_ request: CreatePhotoRequest) async throws -> Photo {
        let body: [String: Any] = [
            "event_id": request.eventId,
            "participant_id": request.participantId,
            "storage_path": request.storagePath,
            "file_size": request.fileSize
        ]
        
        let data = try await callFunction(name: "registerPhoto", body: body, requiresAuth: false)
        let response = try jsonDecoder.decode(RegisterPhotoResponse.self, from: data)
        return response.photo
    }
    
    func getPhotos(eventId: String, isHost: Bool = false) async throws -> [Photo] {
        // Use edge function for reliable access (bypasses RLS issues)
        guard let url = URL(string: "\(baseUrl)/functions/v1/getEventPhotos?event_id=\(eventId)&is_host=\(isHost)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        // Debug logging
        print("📡 getEventPhotos - Status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ getEventPhotos Error: \(errorString)")
            }
            throw SupabaseError.serverError(httpResponse.statusCode)
        }
        
        let photosResponse = try jsonDecoder.decode(GetPhotosResponse.self, from: data)
        return photosResponse.photos
    }
    
    func deletePhoto(id: String) async throws {
        _ = try await makeRequest(
            endpoint: "photos?id=eq.\(id)",
            method: "DELETE"
        )
    }
    
    func getPhotoUrl(path: String) -> String {
        return "\(baseUrl)/storage/v1/object/public/photos/\(path)"
    }
    
    func getSignedPhotoUrl(path: String) async throws -> String {
        guard let url = URL(string: "\(baseUrl)/storage/v1/object/sign/photos/\(path)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["expiresIn": 3600]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SignedUrlResponse.self, from: data)
        
        return "\(baseUrl)/storage/v1\(response.signedURL)"
    }
}

// MARK: - Request/Response Models
struct CreateEventRequest {
    let title: String
    let description: String?
    let eventDate: Date
    let shotLimitPerGuest: Int
    let participantCap: Int
    let revealMode: RevealMode
    let revealTime: Date?
}

struct CreatePhotoRequest {
    let eventId: String
    let participantId: String
    let storagePath: String
    let fileSize: Int64
    let caption: String?
    let filterApplied: String?
}

// Supabase Auth returns a different user structure than our app User model
struct SupabaseAuthUser: Codable {
    let id: String
    let email: String?
    let userMetadata: UserMetadata?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
        case createdAt = "created_at"
    }
    
    struct UserMetadata: Codable {
        let displayName: String?
        let avatarUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }
    }
    
    func toUser() -> User {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: createdAt) ?? Date()
        
        return User(
            id: id,
            email: email ?? "",
            displayName: userMetadata?.displayName,
            avatarUrl: userMetadata?.avatarUrl,
            createdAt: date
        )
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let user: SupabaseAuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct CreateEventResponse: Codable {
    let event: Event
}

struct JoinEventResponse: Codable {
    let participant: Participant
    let event: JoinEventPartialEvent
}

// Partial event returned by joinEvent function (doesn't include all fields)
struct JoinEventPartialEvent: Codable {
    let id: String
    let title: String
    let description: String?
    let eventDate: Date
    let shotLimitPerGuest: Int
    let revealMode: RevealMode
    let revealTime: Date?
    let isRevealed: Bool
    let allowNewPhotos: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case eventDate = "event_date"
        case shotLimitPerGuest = "shot_limit_per_guest"
        case revealMode = "reveal_mode"
        case revealTime = "reveal_time"
        case isRevealed = "is_revealed"
        case allowNewPhotos = "allow_new_photos"
    }
}

struct SignedUploadResponse: Codable {
    let signedUrl: String
    let storagePath: String
    
    enum CodingKeys: String, CodingKey {
        case signedUrl = "signed_url"
        case storagePath = "storage_path"
    }
}

struct RegisterPhotoResponse: Codable {
    let photo: Photo
    let shotsTaken: Int
    let shotsRemaining: Int
    
    enum CodingKeys: String, CodingKey {
        case photo
        case shotsTaken = "shots_taken"
        case shotsRemaining = "shots_remaining"
    }
}

struct GetPhotosResponse: Codable {
    let photos: [Photo]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case photos
        case totalCount = "total_count"
    }
}

struct SignedUrlResponse: Codable {
    let signedURL: String
}

struct EventWithParticipantsAndPhotos: Codable {
    let id: String
    let hostId: String
    let title: String
    let description: String?
    let eventDate: Date
    let shotLimitPerGuest: Int
    let participantCap: Int
    let revealMode: RevealMode
    let revealTime: Date?
    let coverImageUrl: String?
    let joinCode: String
    let isLocked: Bool
    let allowNewPhotos: Bool
    let isRevealed: Bool
    let createdAt: Date
    let participants: [CountResult]
    let photos: [CountResult]
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title, description
        case eventDate = "event_date"
        case shotLimitPerGuest = "shot_limit_per_guest"
        case participantCap = "participant_cap"
        case revealMode = "reveal_mode"
        case revealTime = "reveal_time"
        case coverImageUrl = "cover_image_url"
        case joinCode = "join_code"
        case isLocked = "is_locked"
        case allowNewPhotos = "allow_new_photos"
        case isRevealed = "is_revealed"
        case createdAt = "created_at"
        case participants, photos
    }
    
    func toEvent() -> Event {
        Event(
            id: id,
            hostId: hostId,
            title: title,
            description: description,
            eventDate: eventDate,
            shotLimitPerGuest: shotLimitPerGuest,
            participantCap: participantCap,
            revealMode: revealMode,
            revealTime: revealTime,
            coverImageUrl: coverImageUrl,
            joinCode: joinCode,
            isLocked: isLocked,
            allowNewPhotos: allowNewPhotos,
            isRevealed: isRevealed,
            createdAt: createdAt
        )
    }
}

struct CountResult: Codable {
    let count: Int
}

// MARK: - Errors
enum SupabaseError: Error, LocalizedError {
    case notImplemented
    case networkError
    case authError
    case notFound
    case unauthorized
    case invalidURL
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented: return "Feature not implemented"
        case .networkError: return "Network error occurred"
        case .authError: return "Authentication failed"
        case .notFound: return "Resource not found"
        case .unauthorized: return "Unauthorized access"
        case .invalidURL: return "Invalid URL"
        case .serverError(let code): return "Server error: \(code)"
        }
    }
}
