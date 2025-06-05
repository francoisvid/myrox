import SwiftData
import Foundation

@Model
final class PersonalBest {
    var id: UUID
    var exerciseType: String // "run_100m", "burpees_50reps", "plank_timeonly"
    var value: Double // time in seconds, reps, distance in meters, etc.
    var unit: String // "seconds", "reps", "meters", "kg"
    var achievedAt: Date
    var workoutId: UUID? // Reference to the workout where this was achieved
    var apiId: String? // Backend API ID for sync
    var isSynced: Bool = false // Flag pour tracker la synchronisation API
    
    init(exerciseType: String, value: Double, unit: String, achievedAt: Date, workoutId: UUID? = nil) {
        self.id = UUID()
        self.exerciseType = exerciseType
        self.value = value
        self.unit = unit
        self.achievedAt = achievedAt
        self.workoutId = workoutId
    }
    
    // Helper pour convertir vers APIPersonalBest
    func toAPIPersonalBest() -> APIPersonalBest {
        let formatter = ISO8601DateFormatter()
        return APIPersonalBest(
            id: apiId ?? id.uuidString,
            exerciseType: exerciseType,
            value: value,
            unit: unit,
            achievedAt: formatter.string(from: achievedAt),
            workoutId: workoutId?.uuidString,
            workout: nil // Sera rempli par l'API si nécessaire
        )
    }
    
    // Helper pour créer depuis APIPersonalBest
    static func fromAPI(_ apiPersonalBest: APIPersonalBest) -> PersonalBest {
        let personalBest = PersonalBest(
            exerciseType: apiPersonalBest.exerciseType,
            value: apiPersonalBest.value,
            unit: apiPersonalBest.unit,
            achievedAt: apiPersonalBest.achievementDate,
            workoutId: apiPersonalBest.workoutId != nil ? UUID(uuidString: apiPersonalBest.workoutId!) : nil
        )
        personalBest.apiId = apiPersonalBest.id
        personalBest.isSynced = true
        return personalBest
    }
    
    // Helper pour mettre à jour avec des données API
    func updateFromAPI(_ apiPersonalBest: APIPersonalBest) {
        self.value = apiPersonalBest.value
        self.achievedAt = apiPersonalBest.achievementDate
        self.workoutId = apiPersonalBest.workoutId != nil ? UUID(uuidString: apiPersonalBest.workoutId!) : nil
        self.apiId = apiPersonalBest.id
        self.isSynced = true
    }
} 