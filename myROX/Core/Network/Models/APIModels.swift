import Foundation

// MARK: - Workout Models

struct APIWorkout: Codable, Identifiable {
    let id: String
    let name: String?
    let startedAt: String // ISO8601
    let completedAt: String? // ISO8601
    let totalDuration: Int? // in seconds
    let notes: String?
    let rating: Int? // 1-5 stars
    let templateId: String?
    let template: APIWorkoutTemplate?
    let exercises: [APIWorkoutExercise]
    
    var uuid: UUID {
        UUID(uuidString: id) ?? UUID()
    }
    
    var startDate: Date {
        // Essayer d'abord le formatter UTC, puis le formatter API standard
        if let date = ISO8601DateFormatter.utcFormatter.date(from: startedAt) {
            return date
        } else if let date = ISO8601DateFormatter.apiFormatter.date(from: startedAt) {
            return date
        } else {
            print("⚠️ Impossible de parser startedAt: '\(startedAt)' - utilisation de Date()")
            return Date()
        }
    }
    
    var completionDate: Date? {
        guard let completedAt = completedAt else { return nil }
        // Essayer d'abord le formatter UTC, puis le formatter API standard
        if let date = ISO8601DateFormatter.utcFormatter.date(from: completedAt) {
            return date
        } else if let date = ISO8601DateFormatter.apiFormatter.date(from: completedAt) {
            return date
        } else {
            print("⚠️ Impossible de parser completedAt: '\(completedAt)' - retour nil")
            return nil
        }
    }
}

struct APIWorkoutTemplate: Codable {
    let id: String
    let name: String
}

struct APIWorkoutExercise: Codable, Identifiable {
    let id: String
    let order: Int
    let sets: Int?
    let repsCompleted: Int?
    let durationCompleted: Int? // in seconds
    let distanceCompleted: Double? // in meters
    let weightUsed: Double? // in kg
    let restTime: Int? // in seconds
    let notes: String?
    let completedAt: String? // ISO8601
    let exercise: APIExerciseReference
    
    var completionDate: Date? {
        guard let completedAt = completedAt else { return nil }
        // Essayer d'abord le formatter UTC, puis le formatter API standard
        if let date = ISO8601DateFormatter.utcFormatter.date(from: completedAt) {
            return date
        } else if let date = ISO8601DateFormatter.apiFormatter.date(from: completedAt) {
            return date
        } else {
            print("⚠️ Impossible de parser exercise completedAt: '\(completedAt)' - retour nil")
            return nil
        }
    }
}

struct APIExerciseReference: Codable {
    let id: String
    let name: String
    let category: String
}

struct APIPersonalBest: Codable, Identifiable {
    let id: String
    let exerciseType: String
    let value: Double
    let unit: String
    let achievedAt: String // ISO8601
    let workoutId: String?
    let workout: APIWorkoutReference?
    
    var achievementDate: Date {
        // Essayer d'abord le formatter UTC, puis le formatter API standard
        if let date = ISO8601DateFormatter.utcFormatter.date(from: achievedAt) {
            return date
        } else if let date = ISO8601DateFormatter.apiFormatter.date(from: achievedAt) {
            return date
        } else {
            print("⚠️ Impossible de parser achievedAt: '\(achievedAt)' - utilisation de Date()")
            return Date()
        }
    }
}

struct APIWorkoutReference: Codable {
    let id: String?
    let name: String?
    let completedAt: String?
} 