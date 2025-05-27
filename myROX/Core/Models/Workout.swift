import SwiftData
import Foundation

@Model
final class Workout {
    var id: UUID
    var templateID: UUID? // Référence au template utilisé
    var templateName: String? // Nom du template utilisé
    var totalRounds: Int = 1 // Nombre total de rounds
    var startedAt: Date
    var completedAt: Date?
    var totalDuration: TimeInterval = 0
    var totalDistance: Double = 0
    
    @Relationship(deleteRule: .cascade)
    var performances: [WorkoutExercise] = []
    
    init() {
        self.id = UUID()
        self.startedAt = Date()
    }
}
