import SwiftData
import Foundation

@Model
final class ExerciseDefaults {
    var id: UUID
    var exerciseName: String
    var defaultDistance: Double?
    var defaultRepetitions: Int?
    var isCustomized: Bool = false
    var updatedAt: Date
    
    init(exerciseName: String, defaultDistance: Double? = nil, defaultRepetitions: Int? = nil) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.defaultDistance = defaultDistance
        self.defaultRepetitions = defaultRepetitions
        self.updatedAt = Date()
    }
} 