import Foundation

// MARK: - Common API Request Models

// MARK: - Template Creation Models

struct CreateTemplateRequest: Codable {
    let name: String
    let rounds: Int
    let exercises: [CreateTemplateExerciseRequest]
}

struct CreateTemplateExerciseRequest: Codable {
    let exerciseId: String
    let order: Int
    let targetRepetitions: Int?
    let targetDistance: Int?
    let targetTime: Int? // en secondes
    let restTime: Int?   // en secondes
}

struct UpdateTemplateRequest: Codable {
    let id: String
    let name: String?
    let rounds: Int?
    let exercises: [CreateTemplateExerciseRequest]?
}

// MARK: - Common Response Models

struct EmptyResponse: Codable {
    // Empty response for delete operations
} 