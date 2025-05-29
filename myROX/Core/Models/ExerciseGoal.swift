import SwiftData
import Foundation

@Model
final class ExerciseGoal {
    var id: UUID
    var exerciseName: String
    var targetTime: TimeInterval
    var createdAt: Date
    var updatedAt: Date
    
    init(exerciseName: String, targetTime: TimeInterval = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.targetTime = targetTime
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
