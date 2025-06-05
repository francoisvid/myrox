import Foundation

// MARK: - API User Models

struct APIUser: Codable, Identifiable {
    let id: String               // UUID as String from API
    let firebaseUID: String      // ✅ Clé de mapping Firebase
    let email: String?
    let displayName: String?
    let coachId: String?         // UUID as String (empty string if no coach)
    let createdAt: String        // ISO8601 string from API
    let updatedAt: String        // ISO8601 string from API
    
    // MARK: - Computed Properties for iOS compatibility
    
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    var coachUUID: UUID? {
        guard let coachId = coachId, !coachId.isEmpty else { return nil }
        return UUID(uuidString: coachId)
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
    
    var updatedDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: updatedAt) ?? Date()
    }
    
    var hasAssignedCoach: Bool {
        return coachUUID != nil
    }
}

// MARK: - Coach Model (Read-only pour iOS)

struct Coach: Codable, Identifiable {
    let id: UUID
    let firebaseUID: String
    let displayName: String
    let email: String?
    let specialization: String?
    let bio: String?
    let createdAt: Date
    
    // Stats coach (calculées côté serveur)
    let athleteCount: Int?
    let totalWorkouts: Int?
    let averageWorkoutDuration: TimeInterval?
    
    // MARK: - Initializer for testing
    init(id: UUID, firebaseUID: String, displayName: String, email: String?, specialization: String?, bio: String?, createdAt: Date, athleteCount: Int?, totalWorkouts: Int?, averageWorkoutDuration: TimeInterval?) {
        self.id = id
        self.firebaseUID = firebaseUID
        self.displayName = displayName
        self.email = email
        self.specialization = specialization
        self.bio = bio
        self.createdAt = createdAt
        self.athleteCount = athleteCount
        self.totalWorkouts = totalWorkouts
        self.averageWorkoutDuration = averageWorkoutDuration
    }
}

// MARK: - User Update Models

struct UserUpdateRequest: Codable {
    let displayName: String?
    let email: String?
    // Autres champs modifiables par l'athlete
    // Note: coachId n'est PAS modifiable côté iOS
}

// MARK: - User Response Models

struct UserListResponse: Codable {
    let users: [APIUser]
    let total: Int
    let page: Int
    let limit: Int
}

// MARK: - Generic API Response

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
} 