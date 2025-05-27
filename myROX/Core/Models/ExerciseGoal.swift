import SwiftData
import Foundation

@Model
final class ExerciseGoal {
    var id: UUID
    var exerciseName: String
    var targetTime: TimeInterval
    var targetDistance: Double?
    var targetRepetitions: Int?
    var createdAt: Date
    var updatedAt: Date
    
    init(exerciseName: String, targetTime: TimeInterval = 0, targetDistance: Double? = nil, targetRepetitions: Int? = nil) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.targetTime = targetTime
        self.targetDistance = targetDistance
        self.targetRepetitions = targetRepetitions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
