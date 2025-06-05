import Foundation

// MARK: - API Template Models

struct APITemplate: Codable, Identifiable {
    let id: String               // UUID as String from API
    let name: String
    let rounds: Int
    let exercises: [APITemplateExercise]
    let userId: String           // UUID as String of the creator
    let isPersonal: Bool         // true if it's a personal template, false if assigned by coach
    let createdAt: String        // ISO8601 string from API
    let updatedAt: String        // ISO8601 string from API
    
    // MARK: - Computed Properties for iOS compatibility
    
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    var userUUID: UUID {
        return UUID(uuidString: userId) ?? UUID()
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
    
    var updatedDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: updatedAt) ?? Date()
    }
}

// MARK: - API Template Exercise

struct APITemplateExercise: Codable, Identifiable {
    let id: String               // UUID as String from API
    let exercise: APIExercise    // The exercise definition
    let order: Int               // Order in the template
    let sets: Int?               // Number of sets (optional)
    let reps: Int?               // Target repetitions (optional)
    let duration: Int?           // Target duration in seconds (optional)
    let distance: Double?        // Target distance in meters (optional)
    let weight: Double?          // Target weight (optional)
    let restTime: Int?           // Rest duration in seconds (optional)
    let notes: String?           // Additional notes (optional)
    let templateId: String       // Template ID
    let exerciseId: String       // Exercise ID
    
    // MARK: - Computed Properties
    
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    // MARK: - Convenience Properties for iOS compatibility
    
    var targetReps: Int? { reps }
    var targetDistance: Double? { distance }
    var targetDuration: Int? { duration }
    var restDuration: Int? { restTime }
}

// MARK: - Template Response Models

struct TemplateListResponse: Codable {
    let templates: [APITemplate]
    let total: Int
    let page: Int
    let limit: Int
}

// MARK: - Exercise Response Models

struct ExerciseListResponse: Codable {
    let exercises: [APIExercise]
    let total: Int
    let page: Int
    let limit: Int
} 