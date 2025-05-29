import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var rounds: Int = 1
    
    @Relationship(deleteRule: .cascade)
    var exercises: [TemplateExercise] = []
    
    // Propriété de compatibilité pour l'ancien système
    var exerciseNames: [String] {
        get {
            exercises.sorted(by: { $0.order < $1.order }).map { $0.exerciseName }
        }
        set {
            // Migration automatique si besoin
            if exercises.isEmpty && !newValue.isEmpty {
                exercises = newValue.enumerated().map { index, name in
                    TemplateExercise(exerciseName: name, order: index)
                }
            }
        }
    }
    
    init(name: String, rounds: Int = 1) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.rounds = rounds
    }
}
