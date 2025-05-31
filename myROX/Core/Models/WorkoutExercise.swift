import SwiftData
import Foundation

@Model
final class WorkoutExercise {
    var id: UUID
    var exerciseName: String // Nom de l'exercice réalisé
    var duration: TimeInterval = 0
    var distance: Double = 0
    var repetitions: Int = 0
    var completedAt: Date?
    var averageHeartRate: Int = 0
    var maxHeartRate: Int = 0
    var round: Int = 1 // Numéro du round
    var order: Int = 0 // Ordre dans le round
    var isPersonalRecord: Bool = false // Indique si c'est un record personnel
    
    @Relationship(inverse: \Workout.performances)
    var workout: Workout?
    
    @Relationship(deleteRule: .cascade)
    var heartRatePoints: [HeartRatePoint] = []
    
    init(exerciseName: String, round: Int = 1, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.round = round
        self.order = order
    }
}
