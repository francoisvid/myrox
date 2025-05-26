import SwiftData
import Foundation

@Model
final class HeartRatePoint {
    var id: UUID
    var value: Int
    var timestamp: Date
    
    @Relationship(inverse: \WorkoutExercise.heartRatePoints)
    var workoutExercise: WorkoutExercise?
    
    init(value: Int, timestamp: Date) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
    }
}
