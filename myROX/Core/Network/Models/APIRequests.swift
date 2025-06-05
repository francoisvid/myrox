import Foundation

// MARK: - Template Requests

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
    
    // Initializer pour mise à jour avec exercices (cas le plus fréquent)
    init(id: String, name: String, rounds: Int, exercises: [CreateTemplateExerciseRequest]) {
        self.id = id
        self.name = name
        self.rounds = rounds
        self.exercises = exercises
    }
    
    // Initializer pour mise à jour basique (nom/rounds seulement)
    init(id: String, name: String? = nil, rounds: Int? = nil) {
        self.id = id
        self.name = name
        self.rounds = rounds
        self.exercises = nil
    }
}

// MARK: - User Requests

struct CreateUserRequest: Codable {
    let firebaseUID: String
    let email: String?
    let displayName: String?
}

struct UpdateUserRequest: Codable {
    let displayName: String?
    let email: String?
}

// MARK: - Workout Requests

struct CreateWorkoutRequest: Codable {
    let templateId: String?
    let name: String?
    let startedAt: String // ISO8601
    let exercises: [CreateWorkoutExerciseRequest]
}

struct CreateWorkoutExerciseRequest: Codable {
    let exerciseId: String
    let order: Int
    let sets: Int?
    let targetReps: Int?
    let targetDuration: Int? // en secondes
    let targetDistance: Double? // en mètres
    let targetWeight: Double? // en kg
    let restTime: Int? // en secondes
}

struct UpdateWorkoutRequest: Codable {
    let completedAt: String? // ISO8601
    let totalDuration: Int? // en secondes
    let notes: String?
    let rating: Int? // 1-5 étoiles
    let exercises: [UpdateWorkoutExerciseRequest]?
}

struct UpdateWorkoutExerciseRequest: Codable {
    let id: String
    let repsCompleted: Int?
    let durationCompleted: Int? // en secondes
    let distanceCompleted: Double? // en mètres
    let weightUsed: Double? // en kg
    let restTime: Int? // en secondes
    let notes: String?
    let completedAt: String? // ISO8601
}

// MARK: - Personal Best Requests

struct CreatePersonalBestRequest: Codable {
    let exerciseType: String
    let value: Double
    let unit: String
    let achievedAt: String // ISO8601
    let workoutId: String?
}

struct UpdatePersonalBestRequest: Codable {
    let value: Double?
    let achievedAt: String? // ISO8601
    let workoutId: String?
} 